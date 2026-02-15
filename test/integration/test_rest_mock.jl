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
    
    @testset "Get Current User (@me)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "rest_get_me.json")
        fixture_data = read(fixture_path, Vector{UInt8})
        
        # Mock HTTP.request directly
        mock_resp = HTTP.Response(200, fixture_data)
        patch = @patch HTTP.request(args...; kwargs...) = mock_resp
        
        apply(patch) do
            me = Accord.get_current_user(client.ratelimiter; token=client.token)
            @test me isa User
            @test me.username != ""
        end
    end

    @testset "Create Message" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "rest_create_message.json")
        fixture_data = read(fixture_path, Vector{UInt8})
        
        mock_resp = HTTP.Response(200, fixture_data)
        patch = @patch HTTP.request(args...; kwargs...) = mock_resp
        
        apply(patch) do
            msg = create_message(client, Snowflake(12345); content="Hello Mock!")
            @test msg isa Message
            @test msg.content != ""
        end
    end

    # Stop rate limiter
    Accord.stop_ratelimiter!(client.ratelimiter)
end
