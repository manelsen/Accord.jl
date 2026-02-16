@testitem "REST Interaction Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP

    @testset "Interaction Endpoints" begin
        app_id = Snowflake(1000)
        g_id = Snowflake(200)
        cmd_id = Snowflake(900)

        @testset "get_global_application_commands" begin
            handler, cap = capture_handler(mock_json([app_cmd_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_global_application_commands(rl, app_id; token)
                @test result isa Vector{ApplicationCommand}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/applications/1000/commands")
            end
        end

        @testset "create_global_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_global_application_command(rl, app_id; token, body=Dict("name" => "test", "description" => "test"))
                @test result isa ApplicationCommand
                @test cap[][1] == "POST"
            end
        end

        @testset "get_global_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_global_application_command(rl, app_id, cmd_id; token)
                @test result isa ApplicationCommand
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/commands/900")
            end
        end

        @testset "edit_global_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_global_application_command(rl, app_id, cmd_id; token, body=Dict("name" => "edited"))
                @test result isa ApplicationCommand
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_global_application_command" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_global_application_command(rl, app_id, cmd_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/commands/900")
            end
        end

        @testset "bulk_overwrite_global_application_commands" begin
            handler, cap = capture_handler(mock_json([app_cmd_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.bulk_overwrite_global_application_commands(rl, app_id; token, body=[Dict("name" => "test", "description" => "test")])
                @test result isa Vector{ApplicationCommand}
                @test cap[][1] == "PUT"
            end
        end

        @testset "get_guild_application_commands" begin
            handler, cap = capture_handler(mock_json([app_cmd_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_application_commands(rl, app_id, g_id; token)
                @test result isa Vector{ApplicationCommand}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/commands")
            end
        end

        @testset "create_guild_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_application_command(rl, app_id, g_id; token, body=Dict("name" => "test", "description" => "test"))
                @test result isa ApplicationCommand
                @test cap[][1] == "POST"
            end
        end

        @testset "get_guild_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_application_command(rl, app_id, g_id, cmd_id; token)
                @test result isa ApplicationCommand
                @test cap[][1] == "GET"
            end
        end

        @testset "edit_guild_application_command" begin
            handler, cap = capture_handler(mock_json(app_cmd_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_guild_application_command(rl, app_id, g_id, cmd_id; token, body=Dict("name" => "edited"))
                @test result isa ApplicationCommand
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_application_command" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_application_command(rl, app_id, g_id, cmd_id; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "bulk_overwrite_guild_application_commands" begin
            handler, cap = capture_handler(mock_json([app_cmd_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.bulk_overwrite_guild_application_commands(rl, app_id, g_id; token, body=[])
                @test result isa Vector{ApplicationCommand}
                @test cap[][1] == "PUT"
            end
        end

        @testset "get_original_interaction_response" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_original_interaction_response(rl, app_id, "mock_interaction_token"; token)
                @test result isa Message
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/webhooks/1000/mock_interaction_token/messages/@original")
            end
        end

        @testset "edit_original_interaction_response" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_original_interaction_response(rl, app_id, "mock_token"; token, body=Dict("content" => "edited"))
                @test result isa Message
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_original_interaction_response" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_original_interaction_response(rl, app_id, "mock_token"; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/messages/@original")
            end
        end

        @testset "create_followup_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_followup_message(rl, app_id, "mock_token"; token, body=Dict("content" => "followup"))
                @test result isa Message
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/webhooks/1000/mock_token")
            end
        end

        @testset "get_followup_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_followup_message(rl, app_id, "mock_token", Snowflake(400); token)
                @test result isa Message
                @test cap[][1] == "GET"
            end
        end

        @testset "edit_followup_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_followup_message(rl, app_id, "mock_token", Snowflake(400); token, body=Dict("content" => "edited"))
                @test result isa Message
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_followup_message" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_followup_message(rl, app_id, "mock_token", Snowflake(400); token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "get_guild_application_command_permissions" begin
            handler, cap = capture_handler(mock_json([Dict("id" => "900", "application_id" => "1000", "guild_id" => "200", "permissions" => [])]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_application_command_permissions(rl, app_id, g_id; token)
                @test result isa Vector
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/commands/permissions")
            end
        end

        @testset "get_application_command_permissions" begin
            handler, cap = capture_handler(mock_json(Dict("id" => "900", "permissions" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.get_application_command_permissions(rl, app_id, g_id, cmd_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
            end
        end

        @testset "edit_application_command_permissions" begin
            handler, cap = capture_handler(mock_json(Dict("id" => "900", "permissions" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_application_command_permissions(rl, app_id, g_id, cmd_id; token, body=Dict("permissions" => []))
                @test result isa Dict
                @test cap[][1] == "PUT"
            end
        end
    end
end
