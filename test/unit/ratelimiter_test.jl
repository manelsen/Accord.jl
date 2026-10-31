@testitem "Rate Limiter" tags=[:unit] begin
    using Accord, HTTP, JSON3
    using Accord: BucketState, url, RateLimiter, Route,
        start_ratelimiter!, stop_ratelimiter!, RestJob, submit_rest,
        _update_ratelimit, _get_bucket_key, _get_retry_after, _is_global_ratelimit

    # ── Helpers ──────────────────────────────────────────────────────────────────

    "Build an HTTP.Response with rate limit headers."
    function rl_response(status=200; remaining=nothing, reset=nothing,
                         reset_after=nothing, bucket=nothing,
                         global_rl=false, retry_after=nothing, body="{}")
        headers = Pair{String,String}[]
        !isnothing(remaining)   && push!(headers, "X-RateLimit-Remaining" => string(remaining))
        !isnothing(reset)       && push!(headers, "X-RateLimit-Reset" => string(reset))
        !isnothing(reset_after) && push!(headers, "X-RateLimit-Reset-After" => string(reset_after))
        !isnothing(bucket)      && push!(headers, "X-RateLimit-Bucket" => bucket)
        global_rl               && push!(headers, "X-RateLimit-Global" => "true")
        !isnothing(retry_after) && push!(headers, "Retry-After" => string(retry_after))
        HTTP.Response(status, headers; body=Vector{UInt8}(body))
    end

    "Run a single request through the rate limiter with a mock handler."
    function with_mock_rl(handler; global_limit=50)
        rl = RateLimiter(; global_limit)
        rl.request_handler = handler
        start_ratelimiter!(rl)
        try
            return rl, (route, method="GET") -> begin
                job = RestJob(route, method, url(route),
                    ["Authorization" => "Bot test"], nothing, Channel{Any}(1))
                submit_rest(rl, job)
            end
        catch
            stop_ratelimiter!(rl)
            rethrow()
        end
    end

    # ── Route & Bucket Key ───────────────────────────────────────────────────────

    @testset "Route bucket key" begin
        r1 = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "123")
        r2 = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "456")
        r3 = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "123")

        @test r1.bucket_key == r3.bucket_key
        @test r1.bucket_key != r2.bucket_key

        # Same template with non-major param substituted → same bucket key
        r4 = Route("GET", "/users/{user_id}", "user_id" => "123")
        r5 = Route("GET", "/users/{user_id}", "user_id" => "456")
        @test r4.bucket_key == r5.bucket_key  # user_id is not a major param
    end

    @testset "Route URL" begin
        r = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "123")
        @test url(r) == "https://discord.com/api/v10/channels/123/messages"
    end

    @testset "BucketState defaults" begin
        bs = BucketState()
        @test bs.remaining == 1
        @test bs.reset_at == 0.0
        @test bs.bucket_hash === nothing
    end

    @testset "RateLimiter construction" begin
        rl = RateLimiter()
        @test rl.global_limit == 50
        @test rl.running == false
        @test isempty(rl.buckets)
        @test isempty(rl.bucket_hashes)

        rl2 = RateLimiter(; global_limit=100)
        @test rl2.global_limit == 100
    end

    # ── Header Parsing (_update_ratelimit) ───────────────────────────────────────

    @testset "Header parsing — remaining & reset" begin
        rl = RateLimiter()
        route = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "100")
        reset_ts = time() + 5.0

        resp = rl_response(200; remaining=4, reset=reset_ts)
        _update_ratelimit(rl, route, resp)

        bucket_key = _get_bucket_key(rl, route)
        bucket = rl.buckets[bucket_key]
        @test bucket.remaining == 4
        @test bucket.reset_at ≈ reset_ts atol=0.01
    end

    @testset "Header parsing — reset_after fallback" begin
        rl = RateLimiter()
        route = Route("GET", "/test")
        before = time()

        resp = rl_response(200; remaining=0, reset_after=2.5)
        _update_ratelimit(rl, route, resp)

        bucket = rl.buckets[_get_bucket_key(rl, route)]
        @test bucket.remaining == 0
        @test bucket.reset_at >= before + 2.5
    end

    @testset "Header parsing — reset takes priority over reset_after" begin
        rl = RateLimiter()
        route = Route("GET", "/test")
        exact_ts = time() + 10.0

        resp = rl_response(200; remaining=3, reset=exact_ts, reset_after=999.0)
        _update_ratelimit(rl, route, resp)

        bucket = rl.buckets[_get_bucket_key(rl, route)]
        @test bucket.reset_at ≈ exact_ts atol=0.01
    end

    @testset "Header parsing — bucket hash mapping" begin
        rl = RateLimiter()
        route = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "100")
        discord_hash = "abc123def456"

        resp = rl_response(200; remaining=5, reset=time()+1.0, bucket=discord_hash)
        _update_ratelimit(rl, route, resp)

        # Route's bucket_key should now map to Discord's hash
        @test rl.bucket_hashes[route.bucket_key] == discord_hash
        # Bucket state is keyed by Discord's hash *plus* the major parameter
        @test _get_bucket_key(rl, route) == "$discord_hash:channel_id:100"
        @test haskey(rl.buckets, "$discord_hash:channel_id:100")
        @test rl.buckets["$discord_hash:channel_id:100"].remaining == 5
        @test rl.buckets["$discord_hash:channel_id:100"].bucket_hash == discord_hash
    end

    @testset "Header parsing — case insensitive" begin
        rl = RateLimiter()
        route = Route("GET", "/test")
        # Headers with unusual casing
        headers = ["x-RATELIMIT-remaining" => "7", "X-Ratelimit-Reset" => string(time() + 3.0)]
        resp = HTTP.Response(200, headers; body=Vector{UInt8}("{}"))
        _update_ratelimit(rl, route, resp)

        bucket = rl.buckets[_get_bucket_key(rl, route)]
        @test bucket.remaining == 7
    end

    # ── Retry-After & Global Detection ───────────────────────────────────────────

    @testset "retry_after from JSON body" begin
        body = JSON3.write(Dict("retry_after" => 1.5, "message" => "rate limited"))
        resp = rl_response(429; body)
        @test _get_retry_after(resp) ≈ 1.5
    end

    @testset "retry_after from header fallback" begin
        resp = rl_response(429; retry_after=3.0, body="not json")
        @test _get_retry_after(resp) ≈ 3.0
    end

    @testset "retry_after defaults to 1.0" begin
        resp = rl_response(429; body="not json")
        @test _get_retry_after(resp) ≈ 1.0
    end

    @testset "global rate limit detection" begin
        resp_global = rl_response(429; global_rl=true)
        resp_bucket = rl_response(429)
        @test _is_global_ratelimit(resp_global) == true
        @test _is_global_ratelimit(resp_bucket) == false
    end

    # ── Actor Lifecycle ──────────────────────────────────────────────────────────

    @testset "start / stop lifecycle" begin
        rl = RateLimiter()
        @test rl.running == false
        @test rl.task === nothing

        start_ratelimiter!(rl)
        @test rl.running == true
        @test rl.task !== nothing

        stop_ratelimiter!(rl)
        @test rl.running == false
    end

    # ── End-to-End Request Flow ──────────────────────────────────────────────────

    @testset "successful request returns response" begin
        rl, do_request = with_mock_rl() do m, u, h, b
            rl_response(200; remaining=4, reset=time()+5.0)
        end
        try
            route = Route("GET", "/test")
            resp = do_request(route)
            @test resp.status == 200
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "bucket state updated after request" begin
        reset_ts = time() + 10.0
        rl, do_request = with_mock_rl() do m, u, h, b
            rl_response(200; remaining=3, reset=reset_ts, bucket="discord-hash-xyz")
        end
        try
            route = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "1")
            do_request(route)

            @test rl.bucket_hashes[route.bucket_key] == "discord-hash-xyz"
            @test rl.buckets["discord-hash-xyz:channel_id:1"].remaining == 3
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "429 triggers retry and succeeds" begin
        call_count = Ref(0)
        rl, do_request = with_mock_rl() do m, u, h, b
            call_count[] += 1
            if call_count[] == 1
                body = JSON3.write(Dict("retry_after" => 0.01, "message" => "rate limited"))
                rl_response(429; remaining=0, reset_after=0.01, body)
            else
                rl_response(200; remaining=4, reset=time()+5.0)
            end
        end
        try
            route = Route("GET", "/test")
            resp = do_request(route)
            @test resp.status == 200
            @test call_count[] == 2
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "429 global sets global_reset_at" begin
        call_count = Ref(0)
        rl, do_request = with_mock_rl() do m, u, h, b
            call_count[] += 1
            if call_count[] == 1
                body = JSON3.write(Dict("retry_after" => 0.01))
                rl_response(429; global_rl=true, remaining=0, reset_after=0.01, body)
            else
                rl_response(200; remaining=10, reset=time()+5.0)
            end
        end
        try
            before = time()
            route = Route("GET", "/test")
            resp = do_request(route)
            @test resp.status == 200
            # global_reset_at should have been set (even if it already expired)
            @test rl.global_reset_at >= before
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "multiple buckets are independent" begin
        rl, do_request = with_mock_rl() do m, u, h, b
            if contains(u, "channels/111")
                rl_response(200; remaining=5, reset=time()+5.0, bucket="bucket-ch111")
            else
                rl_response(200; remaining=9, reset=time()+5.0, bucket="bucket-ch222")
            end
        end
        try
            r1 = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "111")
            r2 = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "222")
            do_request(r1)
            do_request(r2)

            @test rl.buckets["bucket-ch111:channel_id:111"].remaining == 5
            @test rl.buckets["bucket-ch222:channel_id:222"].remaining == 9
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "request handler exception retries with backoff" begin
        call_count = Ref(0)
        rl, do_request = with_mock_rl() do m, u, h, b
            call_count[] += 1
            if call_count[] <= 2
                error("connection reset")
            end
            rl_response(200; remaining=5, reset=time()+5.0)
        end
        try
            route = Route("GET", "/test")
            resp = do_request(route)
            @test resp.status == 200
            @test call_count[] == 3  # 2 failures + 1 success
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "max retries exhausted returns exception" begin
        rl, do_request = with_mock_rl() do m, u, h, b
            error("always fails")
        end
        try
            route = Route("GET", "/test")
            @test_throws ErrorException do_request(route)
        finally
            stop_ratelimiter!(rl)
        end
    end

    # ── Bucket identity ─────────────────────────────────────────────────────────

    @testset "same hash, different channels → independent buckets" begin
        rl = RateLimiter()
        r1 = Route("POST", "/channels/{channel_id}/messages", "channel_id" => "111")
        r2 = Route("POST", "/channels/{channel_id}/messages", "channel_id" => "222")
        _update_ratelimit(rl, r1, rl_response(200; remaining=0, reset=time()+5.0, bucket="shared"))
        _update_ratelimit(rl, r2, rl_response(200; remaining=4, reset=time()+5.0, bucket="shared"))

        @test _get_bucket_key(rl, r1) != _get_bucket_key(rl, r2)
        @test rl.buckets[_get_bucket_key(rl, r1)].remaining == 0
        @test rl.buckets[_get_bucket_key(rl, r2)].remaining == 4
    end

    @testset "substituted paths share a bucket across minor ids" begin
        r1 = Route("DELETE", "/channels/111111111111/messages/222222222222", "channel_id" => "111111111111")
        r2 = Route("DELETE", "/channels/111111111111/messages/333333333333", "channel_id" => "111111111111")
        r3 = Route("DELETE", "/channels/999999999999/messages/333333333333", "channel_id" => "999999999999")
        @test r1.bucket_key == r2.bucket_key
        @test r1.bucket_key != r3.bucket_key
        @test url(r1) == "https://discord.com/api/v10/channels/111111111111/messages/222222222222"
    end

    @testset "webhook tokens never appear in bucket keys" begin
        secret = "s3cr3t-T0KEN_abc"
        r = Route("POST", "/webhooks/123456789012/$secret",
                  "webhook_id" => "123456789012", "webhook_token" => secret)
        @test !occursin(secret, r.bucket_key)
        @test occursin(secret, url(r))

        other = Route("POST", "/webhooks/123456789012/other-token",
                      "webhook_id" => "123456789012", "webhook_token" => "other-token")
        @test r.bucket_key != other.bucket_key
    end

    # ── Retry semantics ─────────────────────────────────────────────────────────

    @testset "POST is not re-sent after a network error" begin
        call_count = Ref(0)
        rl, do_request = with_mock_rl() do m, u, h, b
            call_count[] += 1
            error("connection reset")
        end
        try
            @test_throws ErrorException do_request(Route("POST", "/test"), "POST")
            @test call_count[] == 1
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "body factory is rebuilt on every attempt" begin
        bodies = Any[]
        call_count = Ref(0)
        rl = RateLimiter()
        rl.request_handler = (m, u, h, b) -> begin
            call_count[] += 1
            push!(bodies, b)
            if call_count[] == 1
                rl_response(429; body=JSON3.write(Dict("retry_after" => 0.01)))
            else
                rl_response(200)
            end
        end
        start_ratelimiter!(rl)
        try
            built = Ref(0)
            factory = () -> (built[] += 1; IOBuffer("payload"))
            job = RestJob(Route("POST", "/test"), "POST", url(Route("POST", "/test")),
                ["Authorization" => "Bot test"], factory, Channel{Any}(1))
            resp = submit_rest(rl, job)
            @test resp.status == 200
            @test built[] == 2
            @test bodies[1] !== bodies[2]
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "persistent 429 returns the response instead of hanging" begin
        rl, do_request = with_mock_rl() do m, u, h, b
            rl_response(429; body=JSON3.write(Dict("retry_after" => 0.001)))
        end
        try
            t = @async do_request(Route("GET", "/always-429"))
            deadline = time() + 10
            while !istaskdone(t) && time() < deadline
                sleep(0.01)
            end
            @test istaskdone(t)
            @test fetch(t).status == 429
        finally
            stop_ratelimiter!(rl)
        end
    end

    # ── Concurrency ─────────────────────────────────────────────────────────────

    @testset "a waiting bucket does not block other buckets" begin
        rl, do_request = with_mock_rl() do m, u, h, b
            if contains(u, "channels/111")
                rl_response(200; remaining=0, reset_after=2.0, bucket="slow")
            else
                rl_response(200; remaining=5, reset_after=2.0, bucket="fast")
            end
        end
        try
            slow = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "111")
            fast = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "222")
            do_request(slow)                    # bucket "slow" is now exhausted for 2s
            blocked = @async do_request(slow)   # has to wait for the reset
            sleep(0.05)
            t0 = time()
            resp = do_request(fast)
            @test resp.status == 200
            @test time() - t0 < 1.0
            @test !istaskdone(blocked)
            wait(blocked)
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "global budget is enforced proactively" begin
        rl, do_request = with_mock_rl(; global_limit=3) do m, u, h, b
            rl_response(200)
        end
        try
            t0 = time()
            for i in 1:4
                do_request(Route("GET", "/users/$i"))
            end
            @test time() - t0 >= 0.9   # 4th request had to wait for the next window
        finally
            stop_ratelimiter!(rl)
        end
    end
end
