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

        on(client, BlockingEvent) do _, _
            notify(slow_started)
            wait(release_slow)
        end

        on(client, FastEvent) do _, _
            notify(fast_done)
        end

        client.running = true
        loop_task = @async Accord._event_loop(client)

        put!(events, BlockingEvent(1))

        deadline = time() + 1.0
        while !slow_started.set && time() < deadline
            sleep(0.01)
        end
        @test slow_started.set

        put!(events, FastEvent(2))

        deadline = time() + 1.0
        while !fast_done.set && time() < deadline
            sleep(0.01)
        end
        @test fast_done.set

        notify(release_slow)

        client.running = false
        close(events)
        wait(loop_task)
    end

    @testset "stop cancels pending wait_for" begin
        client = Client("Bot test_token")

        t0 = time()
        waiter_task = @async wait_for(_ -> true, client, FastEvent; timeout=10.0)
        sleep(0.05)

        stop(client)

        result = fetch(waiter_task)
        dt = time() - t0

        @test isnothing(result)
        @test dt < 1.0
    end
end
