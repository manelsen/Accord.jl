@testitem "REST Application and Client Layer" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP, JSON3

    @testset "Application Endpoints" begin
        @testset "get_current_application" begin
            handler, cap = capture_handler(mock_json(Dict("id" => "1000", "name" => "TestApp")))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_application(rl; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/applications/@me")
            end
        end

        @testset "modify_current_application" begin
            handler, cap = capture_handler(mock_json(Dict("id" => "1000", "name" => "Updated")))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_current_application(rl; token, body=Dict("description" => "new desc"))
                @test result isa Dict
                @test cap[][1] == "PATCH"
            end
        end

        @testset "get_application_role_connection_metadata_records" begin
            handler, cap = capture_handler(mock_json([Dict("type" => 1, "key" => "test", "name" => "Test")]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_application_role_connection_metadata_records(rl, Snowflake(1000); token)
                @test result isa Vector
                @test cap[][1] == "GET"
            end
        end

        @testset "update_application_role_connection_metadata_records" begin
            handler, cap = capture_handler(mock_json([Dict("type" => 1, "key" => "test", "name" => "Test")]))
            with_mock_rl(handler) do rl, token
                result = Accord.update_application_role_connection_metadata_records(rl, Snowflake(1000); token, body=[])
                @test result isa Vector
                @test cap[][1] == "PUT"
            end
        end
    end

    @testset "HTTP Client Layer" begin
        @testset "parse_response success" begin
            resp = mock_json(user_json())
            result = parse_response(User, resp)
            @test result isa User
            @test result.username == "testuser"
        end

        @testset "parse_response error" begin
            resp = HTTP.Response(400, "{\"message\": \"Bad Request\", \"code\": 400}")
            @test_throws ErrorException parse_response(User, resp)
        end

        @testset "parse_response_array success" begin
            resp = mock_json([user_json()])
            result = parse_response_array(User, resp)
            @test result isa Vector{User}
            @test result[1].username == "testuser"
        end

        @testset "parse_response_array error" begin
            resp = HTTP.Response(403, JSON3.write(Dict("message" => "Forbidden")))
            @test_throws ErrorException parse_response_array(User, resp)
        end

        @testset "Route construction" begin
            route = Route("GET", "/guilds/{guild_id}/channels", "guild_id" => "123")
            @test route.method == "GET"
            @test route.path == "/guilds/123/channels"
            @test contains(route.bucket_key, "guild_id:123")
            @test url(route) == "https://discord.com/api/v10/guilds/123/channels"
        end

        @testset "Route bucket key without major params" begin
            route = Route("GET", "/gateway/bot")
            @test route.method == "GET"
            @test route.path == "/gateway/bot"
        end
    end
end
