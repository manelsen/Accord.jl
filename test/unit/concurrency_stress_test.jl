@testitem "Concurrency stress" tags=[:unit, :concurrency] begin
    using Accord, HTTP
    using Accord: RateLimiter, Route, RestJob, url, submit_rest,
        start_ratelimiter!, stop_ratelimiter!, start_heartbeat, stop_heartbeat!,
        Store, AbstractEvent

    # Types and methods must be defined at top level, not inside @testset
    struct StressEvent <: AbstractEvent
        id::Int
    end
    struct RegEvent <: AbstractEvent end
    mutable struct ThreadSafeWS
        sent::Vector{String}
        lock::ReentrantLock
    end
    HTTP.WebSockets.send(w::ThreadSafeWS, msg) = lock(() -> push!(w.sent, msg), w.lock)
    HTTP.WebSockets.close(::ThreadSafeWS) = nothing

    @info "Concurrency stress threads" default=Threads.nthreads(:default) interactive=Threads.nthreads(:interactive)

    @testset "rate limiter: many threads, many buckets, nothing lost" begin
        calls = Threads.Atomic{Int}(0)
        rl = RateLimiter(; global_limit=10_000)
        rl.request_handler = (m, u, h, b) -> begin
            Threads.atomic_add!(calls, 1)
            ch = match(r"channels/(\d+)", u).captures[1]
            HTTP.Response(200, ["X-RateLimit-Remaining" => "1000",
                                "X-RateLimit-Reset-After" => "1.0",
                                "X-RateLimit-Bucket" => "shared-hash"]; body="{}")
        end
        start_ratelimiter!(rl)
        try
            n = 400
            tasks = map(1:n) do i
                Threads.@spawn begin
                    r = Route("GET", "/channels/$(1000 + i % 20)/messages")
                    submit_rest(rl, RestJob(r, "GET", url(r), Pair{String,String}[], nothing, Channel{Any}(1)))
                end
            end
            statuses = fetch.(tasks)
            @test all(r -> r.status == 200, statuses)
            @test calls[] == n
            # one bucket per channel: same hash, different major parameter
            @test length(rl.buckets) == 20
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "handlers run in parallel and none are lost" begin
        client = Client("Bot test"; handler_concurrency=8)
        count = Threads.Atomic{Int}(0)
        seen_threads = Set{Int}()
        seen_lock = ReentrantLock()
        Accord.on(client, StressEvent) do _, _
            lock(() -> push!(seen_threads, Threads.threadid()), seen_lock)
            t0 = time()
            while time() - t0 < 0.02   # a little CPU work, no yield
                GC.safepoint()
            end
            Threads.atomic_add!(count, 1)
        end

        client.running = true
        events = client.shards[1].events
        loop = Threads.@spawn Accord._event_loop(client)
        n = 64
        for i in 1:n
            put!(events, StressEvent(i))
        end
        deadline = time() + 30
        while count[] < n && time() < deadline
            sleep(0.01)
        end
        @test count[] == n
        if Threads.nthreads(:default) > 1
            @test length(seen_threads) > 1
        else
            @test_skip length(seen_threads) > 1
        end
        client.running = false
        close(events)
        wait(loop)
    end

    @testset "heartbeat keeps its rhythm while handlers burn CPU" begin
        if Threads.nthreads(:interactive) == 0
            @test_skip "needs an interactive thread (julia -t N,1)"
        else
            ws = ThreadSafeWS(String[], ReentrantLock())

            stop = Base.Event()
            task, state = start_heartbeat(ws, 50, Ref{Union{Int,Nothing}}(nothing), stop)
            # Keep acknowledging so the heartbeat never declares a zombie
            acker = Threads.@spawn :interactive while state.running
                Accord.heartbeat_ack!(state)
                sleep(0.01)
            end

            # Saturate every default thread with non-yielding work for 1 second
            burners = map(1:Threads.nthreads(:default)) do _
                Threads.@spawn :default begin
                    t0 = time()
                    while time() - t0 < 1.0
                        GC.safepoint()
                    end
                end
            end
            before = lock(() -> length(ws.sent), ws.lock)
            foreach(wait, burners)
            after = lock(() -> length(ws.sent), ws.lock)

            # 50 ms interval over ~1 s: expect well above 10 beats even with jitter
            @test after - before >= 10

            stop_heartbeat!(state)
            notify(stop)
            wait(task)
            wait(acker)
        end
    end

    @testset "cache store: concurrent readers and a writer" begin
        store = Store{Int}()
        writer = Threads.@spawn for i in 1:20_000
            store[Snowflake(i)] = i
            i % 3 == 0 && delete!(store, Snowflake(i - 1))
        end
        readers = map(1:4) do _
            Threads.@spawn begin
                hits = 0
                for i in 1:20_000
                    v = get(store, Snowflake(i))
                    v === nothing || (hits += 1)
                    i % 1000 == 0 && length(keys(store))
                end
                hits
            end
        end
        wait(writer)
        @test all(r -> fetch(r) isa Int, readers)
        @test length(store) > 0
    end

    @testset "registering handlers while events are dispatched" begin
        eh = Accord.EventHandler()
        hits = Threads.Atomic{Int}(0)
        Accord.register_handler!(eh, RegEvent, (c, e) -> Threads.atomic_add!(hits, 1))
        dispatchers = map(1:4) do _
            Threads.@spawn for _ in 1:500
                Accord.dispatch_event!(eh, nothing, RegEvent())
            end
        end
        registrar = Threads.@spawn for _ in 1:200
            Accord.register_handler!(eh, RegEvent, (c, e) -> nothing)
        end
        foreach(wait, dispatchers)
        wait(registrar)
        @test hits[] == 2000
        @test length(eh.handlers[RegEvent]) == 201
    end
end
