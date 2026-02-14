using Accord
using Mocking
using Test
using JSON3
using HTTP

# Enable mocking
Mocking.activate()

@testset "REST Mocking Integration" begin
    client = Client("mock_token")
    
    # We mock 'submit_rest' because it's the point where the job is actually processed
    # In a real scenario, submit_rest would use HTTP.jl
    
    @testset "Get Current User (@me)" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "rest_get_me.json")
        fixture_data = read(fixture_path, String)
        
        # Create a mock response
        mock_resp = HTTP.Response(200, fixture_data)
        
        # Apply the mock to Accord.submit_rest
        patch = @patch Accord.submit_rest(rl, job) = mock_resp
        
        apply(patch) do
            me = Accord.get_current_user(client.ratelimiter; token=client.token)
            @test me isa User
            @test me.username != ""
            @info "Mocked Get Me: $(me.username)"
        end
    end

    @testset "Create Message" begin
        fixture_path = joinpath(@__DIR__, "fixtures", "rest_create_message.json")
        fixture_data = read(fixture_path, String)
        mock_resp = HTTP.Response(200, fixture_data)
        
        patch = @patch Accord.submit_rest(rl, job) = mock_resp
        
        apply(patch) do
            msg = create_message(client, Snowflake(12345); content="Hello Mock!")
            @test msg isa Message
            @test msg.content != ""
            @info "Mocked Create Message: $(msg.content)"
        end
    end
end
