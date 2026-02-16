@testitem "REST User Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP

    @testset "User Endpoints" begin
        @testset "get_current_user" begin
            handler, cap = capture_handler(mock_json(user_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_user(rl; token)
                @test result isa User
                @test result.username == "testuser"
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/@me")
            end
        end

        @testset "get_user" begin
            handler, cap = capture_handler(mock_json(user_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_user(rl, Snowflake(100); token)
                @test result isa User
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/100")
            end
        end

        @testset "modify_current_user" begin
            handler, cap = capture_handler(mock_json(user_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_current_user(rl; token, body=Dict("username" => "newname"))
                @test result isa User
                @test cap[][1] == "PATCH"
                @test contains(cap[][2], "/users/@me")
            end
        end

        @testset "get_current_user_guilds" begin
            handler, cap = capture_handler(mock_json([guild_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_user_guilds(rl; token)
                @test result isa Vector{Guild}
                @test length(result) == 1
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/@me/guilds")
            end
        end

        @testset "get_current_user_guild_member" begin
            handler, cap = capture_handler(mock_json(member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_user_guild_member(rl, Snowflake(200); token)
                @test result isa Member
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/@me/guilds/200/member")
            end
        end

        @testset "leave_guild" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.leave_guild(rl, Snowflake(200); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/users/@me/guilds/200")
            end
        end

        @testset "create_dm" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_dm(rl; token, recipient_id=Snowflake(100))
                @test result isa DiscordChannel
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/users/@me/channels")
            end
        end

        @testset "get_current_user_connections" begin
            handler, cap = capture_handler(mock_json([connection_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_user_connections(rl; token)
                @test result isa Vector{Connection}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/@me/connections")
            end
        end

        @testset "get_current_user_application_role_connection" begin
            handler, cap = capture_handler(mock_json(Dict("platform_name" => "test")))
            with_mock_rl(handler) do rl, token
                result = Accord.get_current_user_application_role_connection(rl, Snowflake(1000); token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/users/@me/applications/1000/role-connection")
            end
        end

        @testset "update_current_user_application_role_connection" begin
            handler, cap = capture_handler(mock_json(Dict("platform_name" => "test")))
            with_mock_rl(handler) do rl, token
                result = Accord.update_current_user_application_role_connection(rl, Snowflake(1000); token, body=Dict())
                @test result isa Dict
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/users/@me/applications/1000/role-connection")
            end
        end
    end
end
