using Accord
using Test
using JSON3
using HTTP

@testset "REST Mocking Integration (Manual)" begin
    client = Client("mock_token")
    
    # Pre-read fixtures
    me_fixture = read(joinpath(@__DIR__, "fixtures", "rest_get_me.json"), String)
    msg_fixture = read(joinpath(@__DIR__, "fixtures", "rest_create_message.json"), String)

    @testset "Get Current User" begin
        # Inject mock handler directly into the ratelimiter
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            @test m == "GET"
            @test occursin("/users/@me", u)
            return HTTP.Response(200, me_fixture)
        end
        
        # Start rate limiter to process the job
        Accord.start_ratelimiter!(client.ratelimiter)
        
        me = Accord.get_current_user(client.ratelimiter; token=client.token)
        @test me isa User
        @test me.username != ""
        
        Accord.stop_ratelimiter!(client.ratelimiter)
    end

    @testset "Create Message" begin
        # Re-initialize or reset ratelimiter for clean state
        client.ratelimiter = RateLimiter()
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            @test m == "POST"
            @test occursin("/messages", u)
            return HTTP.Response(200, msg_fixture)
        end
        
        Accord.start_ratelimiter!(client.ratelimiter)
        
        msg = create_message(client, Snowflake(123456789); content="Hello Mock!")
        @test msg isa Message
        @test msg.content != ""
        
        Accord.stop_ratelimiter!(client.ratelimiter)
    end
end
