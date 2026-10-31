@testitem "Identify pacing and large bot sharding" tags=[:unit] begin
    using Accord, HTTP
    using Accord: IdentifyLimiter, wait_identify!, set_max_concurrency!, IDENTIFY_INTERVAL

    @testset "one identify per bucket every 5 seconds" begin
        lim = IdentifyLimiter(2)
        t0 = time()
        # Shards 0 and 1 are in different buckets: both go at once
        wait_identify!(lim, 0)
        wait_identify!(lim, 1)
        @test time() - t0 < 1.0
        @test all(s -> isapprox(s, t0 + IDENTIFY_INTERVAL; atol=1.0), lim.next_slot)
        # Shard 2 shares shard 0's bucket, so it waits for the next slot
        waiting = Threads.@spawn wait_identify!(lim, 2)
        sleep(0.3)
        @test !istaskdone(waiting)
        @test isapprox(lim.next_slot[1], t0 + 2IDENTIFY_INTERVAL; atol=1.0)
        @test isapprox(lim.next_slot[2], t0 + IDENTIFY_INTERVAL; atol=1.0)
        wait(waiting)
        @test time() - t0 >= IDENTIFY_INTERVAL - 0.1
    end

    @testset "configuration" begin
        @test IdentifyLimiter().max_concurrency == 1 && !IdentifyLimiter().configured
        @test_throws ArgumentError IdentifyLimiter(0)
        lim = set_max_concurrency!(IdentifyLimiter(), 16)
        @test lim.configured && length(lim.next_slot) == 16

        client = Client("Bot test_token_fake"; num_shards=8, max_concurrency=4)
        limiters = [s.identify_limiter for s in client.shards]
        @test all(l -> l === first(limiters), limiters)
        @test first(limiters).max_concurrency == 4 && first(limiters).configured
        # One shard never needs /gateway/bot
        single = Client("Bot test_token_fake")
        Accord._configure_identify!(first(single.shards).identify_limiter, single)
        @test !first(single.shards).identify_limiter.configured
    end

    @testset "get_current_user_guilds shard and with_counts" begin
        client = Client("Bot test_token_fake")
        urls = String[]
        client.ratelimiter.request_handler = (m, u, h, b) -> (push!(urls, u); HTTP.Response(200, "[]"))
        Accord.start_ratelimiter!(client.ratelimiter)
        try
            Accord.get_current_user_guilds(client; shard=3, with_counts=true)
            Accord.get_current_user_guilds(client)
        finally
            Accord.stop_ratelimiter!(client.ratelimiter)
        end
        @test endswith(urls[1], "/users/@me/guilds?limit=200&shard=3&with_counts=true")
        @test endswith(urls[2], "/users/@me/guilds?limit=200")
    end
end
