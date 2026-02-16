@testitem "REST Message Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP

    @testset "Message Endpoints" begin
        ch_id = Snowflake(300)
        msg_id = Snowflake(400)

        @testset "get_channel_messages" begin
            handler, cap = capture_handler(mock_json([message_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_channel_messages(rl, ch_id; token)
                @test result isa Vector{Message}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/channels/300/messages")
            end
        end

        @testset "get_channel_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_channel_message(rl, ch_id, msg_id; token)
                @test result isa Message
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/channels/300/messages/400")
            end
        end

        @testset "create_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_message(rl, ch_id; token, body=Dict("content" => "hi"))
                @test result isa Message
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/channels/300/messages")
            end
        end

        @testset "crosspost_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.crosspost_message(rl, ch_id, msg_id; token)
                @test result isa Message
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/channels/300/messages/400/crosspost")
            end
        end

        @testset "edit_message" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.edit_message(rl, ch_id, msg_id; token, body=Dict("content" => "edited"))
                @test result isa Message
                @test cap[][1] == "PATCH"
                @test contains(cap[][2], "/channels/300/messages/400")
            end
        end

        @testset "delete_message" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_message(rl, ch_id, msg_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/channels/300/messages/400")
            end
        end

        @testset "bulk_delete_messages" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.bulk_delete_messages(rl, ch_id; token, message_ids=[Snowflake(1), Snowflake(2)])
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/channels/300/messages/bulk-delete")
            end
        end

        @testset "create_reaction" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.create_reaction(rl, ch_id, msg_id, "👍"; token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/reactions/")
                @test contains(cap[][2], "/@me")
            end
        end

        @testset "delete_own_reaction" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_own_reaction(rl, ch_id, msg_id, "👍"; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/reactions/")
                @test contains(cap[][2], "/@me")
            end
        end

        @testset "delete_user_reaction" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_user_reaction(rl, ch_id, msg_id, "👍", Snowflake(100); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/reactions/")
                @test contains(cap[][2], "/100")
            end
        end

        @testset "get_reactions" begin
            handler, cap = capture_handler(mock_json([user_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_reactions(rl, ch_id, msg_id, "👍"; token)
                @test result isa Vector{User}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/reactions/")
            end
        end

        @testset "delete_all_reactions" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_all_reactions(rl, ch_id, msg_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/channels/300/messages/400/reactions")
            end
        end

        @testset "delete_all_reactions_for_emoji" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_all_reactions_for_emoji(rl, ch_id, msg_id, "👍"; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/reactions/")
            end
        end

        @testset "get_answer_voters" begin
            handler, cap = capture_handler(mock_json(Dict("users" => [user_json()])))
            with_mock_rl(handler) do rl, token
                result = Accord.get_answer_voters(rl, ch_id, msg_id, 1; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/polls/400/answers/1")
            end
        end

        @testset "end_poll" begin
            handler, cap = capture_handler(mock_json(message_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.end_poll(rl, ch_id, msg_id; token)
                @test result isa Message
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/polls/400/expire")
            end
        end
    end
end
