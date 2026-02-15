using Accord
using Mocking
using Test
using JSON3
using HTTP

# Enable mocking
Mocking.activate()

@testset "REST Mocking Integration" begin
    client = Client("mock_token")
    
    # Start rate limiter to avoid deadlocks
    Accord.start_ratelimiter!(client.ratelimiter)
    
    # Pre-read fixtures to avoid IO inside mock scope
    me_fixture = read(joinpath(@__DIR__, "fixtures", "rest_get_me.json"))
    msg_fixture = read(joinpath(@__DIR__, "fixtures", "rest_create_message.json"))

    @testset "Get Current User (@me)" begin
        mock_resp = HTTP.Response(200, me_fixture)
        patch = @patch HTTP.request(args...; kwargs...) = mock_resp
        
        apply(patch) do
            me = Accord.get_current_user(client.ratelimiter; token=client.token)
            @test me isa User
            @test me.username != ""
        end
    end

    @testset "Create Message" begin
        mock_resp = HTTP.Response(200, msg_fixture)
        patch = @patch HTTP.request(args...; kwargs...) = mock_resp
        
        apply(patch) do
            msg = create_message(client, Snowflake(123456789); content="Hello Mock!")
            @test msg isa Message
            @test msg.content != ""
        end
    end

    # Stop rate limiter
    Accord.stop_ratelimiter!(client.ratelimiter)
end
