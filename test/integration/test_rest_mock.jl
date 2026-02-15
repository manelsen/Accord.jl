using Accord
using Test
using JSON3
using HTTP

@testset "REST Mocking Integration (Manual)" begin
    client = Client("mock_token")
    
    # Pre-read fixtures
    function load_fixture(name)
        path = joinpath(@__DIR__, "fixtures", "$name.json")
        data = JSON3.read(read(path, String))
        # If it's an array, take the first element (common in our fixtures)
        return data isa AbstractVector ? data[1] : data
    end

    me_fixture = load_fixture("rest_get_me")
    msg_fixture = load_fixture("rest_create_message")

    @testset "Get Current User" begin
        # Inject mock handler
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            return HTTP.Response(200, JSON3.write(me_fixture))
        end
        
        Accord.start_ratelimiter!(client.ratelimiter)
        me = Accord.get_current_user(client.ratelimiter; token=client.token)
        @test me isa User
        @test me.username != ""
        Accord.stop_ratelimiter!(client.ratelimiter)
    end

    @testset "Create Message" begin
        client.ratelimiter = RateLimiter()
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            return HTTP.Response(200, JSON3.write(msg_fixture))
        end
        
        Accord.start_ratelimiter!(client.ratelimiter)
        msg = create_message(client, Snowflake(123456789); content="Hello Mock!")
        @test msg isa Message
        @test msg.content != ""
        Accord.stop_ratelimiter!(client.ratelimiter)
    end
end
