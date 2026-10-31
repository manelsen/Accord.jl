@testitem "Client event loop concurrency" tags=[:unit] begin
    using Accord

    struct BlockingEvent <: AbstractEvent
        id::Int
    end

    struct FastEvent <: AbstractEvent
        id::Int
    end

    @testset "slow handlers do not block ingestion loop" begin
        client = Client("Bot test_token")
        events = client.shards[1].events

        slow_started = Base.Event()
        release_slow = Base.Event()
        fast_done = Base.Event()

        Accord.on(client, BlockingEvent) do _, _
            notify(slow_started)
            wait(release_slow)
        end

        Accord.on(client, FastEvent) do _, _
            notify(fast_done)
        end

        client.running = true
        loop_task = @async Accord._event_loop(client)

        put!(events, BlockingEvent(1))

        deadline = time() + 10.0  # generous: first dispatch includes compilation
        while !slow_started.set && time() < deadline
            sleep(0.01)
        end
        @test slow_started.set

        put!(events, FastEvent(2))

        deadline = time() + 10.0  # generous: first dispatch includes compilation
        while !fast_done.set && time() < deadline
            sleep(0.01)
        end
        @test fast_done.set

        notify(release_slow)

        client.running = false
        close(events)
        wait(loop_task)
    end

    @testset "handler backlog bounds the number of handler tasks" begin
        client = Client("Bot test_token"; handler_concurrency=1, handler_backlog=2)
        events = client.shards[1].events

        release = Base.Event()
        Accord.on(client, BlockingEvent) do _, _
            wait(release)
        end

        client.running = true
        loop_task = @async Accord._event_loop(client)

        for i in 1:5
            put!(events, BlockingEvent(i))
        end
        sleep(0.2)

        @test length(client._handler_tasks) <= 2
        @test isready(events)   # the loop is applying back-pressure

        notify(release)
        deadline = time() + 10.0
        while (isready(events) || !isempty(client._handler_tasks)) && time() < deadline
            sleep(0.01)
        end
        @test isempty(client._handler_tasks)

        client.running = false
        close(events)
        wait(loop_task)
    end

    @testset "invalid handler_backlog is rejected" begin
        @test_throws ArgumentError Client("Bot test_token"; handler_concurrency=4, handler_backlog=2)
    end

    @testset "stop cancels pending wait_for" begin
        client = Client("Bot test_token")

        t0 = time()
        waiter_task = @async wait_for(_ -> true, client, FastEvent; timeout=10.0)
        sleep(0.05)

        Accord.stop(client)

        result = fetch(waiter_task)
        dt = time() - t0

        @test isnothing(result)
        @test dt < 5.0   # well under the 10s timeout; slack for compilation
    end
end
