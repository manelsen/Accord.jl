@testitem "REST Webhook Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP

    @testset "Webhook Endpoints" begin
        wh_id = Snowflake(600)
        wh_token = "mock_webhook_token"

        @testset "create_webhook" begin
            handler, cap = capture_handler(mock_json(webhook_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_webhook(rl, Snowflake(300); token, body=Dict("name" => "TestHook"))
                @test result isa Webhook
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/channels/300/webhooks")
            end
        end

        @testset "get_channel_webhooks" begin
            handler, cap = capture_handler(mock_json([webhook_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_channel_webhooks(rl, Snowflake(300); token)
                @test result isa Vector{Webhook}
                @test cap[][1] == "GET"
            end
        end

        @testset "get_guild_webhooks" begin
            handler, cap = capture_handler(mock_json([webhook_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_webhooks(rl, Snowflake(200); token)
                @test result isa Vector{Webhook}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/webhooks")
            end
        end

        @testset "get_webhook" begin
            handler, cap = capture_handler(mock_json(webhook_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_webhook(rl, wh_id; token)
                @test result isa Webhook
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/webhooks/600")
            end
        end

        @testset "get_webhook_with_token" begin
            handler, cap = capture_handler(mock_json(webhook_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_webhook_with_token(rl, wh_id, wh_token; token)
                @test result isa Webhook
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/webhooks/600/mock_webhook_token")
            end
        end

        @testset "modify_webhook" begin
            handler, cap = capture_handler(mock_json(webhook_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_webhook(rl, wh_id; token, body=Dict("name" => "NewName"))
                @test result isa Webhook
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_webhook" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_webhook(rl, wh_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/webhooks/600")
            end
        end

        @testset "execute_webhook (no wait)" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                result = Accord.execute_webhook(rl, wh_id, wh_token; token, body=Dict("content" => "hello"))
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/webhooks/600/mock_webhook_token")
            end
        end

        @testset "execute_webhook (wait)" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.execute_webhook(rl, wh_id, wh_token; token, body=Dict("content" => "hello"), wait=true)
                @test result isa Message
                @test cap[][1] == "POST"
            end
        end

        @testset "get_webhook_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_webhook_message(rl, wh_id, wh_token, Snowflake(400); token)
                @test result isa Message
                @test cap[][1] == "GET"
            end
        end

        @testset "edit_webhook_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_webhook_message(rl, wh_id, wh_token, Snowflake(400); token, body=Dict("content" => "edited"))
                @test result isa Message
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_webhook_message" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_webhook_message(rl, wh_id, wh_token, Snowflake(400); token)
                @test cap[][1] == "DELETE"
            end
        end
    end
end
