@testset "Rate Limiter" begin
    @testset "Route bucket key" begin
        r1 = Route("GET", "/channels/123/messages", "channel_id" => "123")
        r2 = Route("GET", "/channels/456/messages", "channel_id" => "456")
        r3 = Route("GET", "/channels/123/messages", "channel_id" => "123")

        # Same channel should have same bucket key
        @test r1.bucket_key == r3.bucket_key
        # Different channel should have different bucket key
        @test r1.bucket_key != r2.bucket_key

        # Non-major param route
        r4 = Route("GET", "/users/123")
        r5 = Route("GET", "/users/456")
        # These share the same template so different behavior based on implementation
    end

    @testset "Route URL" begin
        r = Route("GET", "/channels/123/messages", "channel_id" => "123")
        @test Accord.url(r) == "https://discord.com/api/v10/channels/123/messages"
    end

    @testset "BucketState" begin
        bs = Accord.BucketState()
        @test bs.remaining == 1
        @test bs.reset_at == 0.0
    end

    @testset "RateLimiter construction" begin
        rl = RateLimiter()
        @test rl.global_limit == 50
        @test rl.running == false
        @test isempty(rl.buckets)
    end
end
