@testitem "REST Channel Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP, JSON3
    using Accord: Connection, Integration, WelcomeScreen, Onboarding, SoundboardSound, SKU, Entitlement, Subscription, parse_response, parse_response_array, url, API_BASE

    @testset "Channel Endpoints" begin
        ch_id = Snowflake(300)

        @testset "get_channel" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_channel(rl, ch_id; token)
                @test result isa DiscordChannel
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/channels/300")
            end
        end

        @testset "modify_channel" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_channel(rl, ch_id; token, body=Dict("name" => "renamed"))
                @test result isa DiscordChannel
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_channel" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.delete_channel(rl, ch_id; token)
                @test result isa DiscordChannel
                @test cap[][1] == "DELETE"
            end
        end

        @testset "edit_channel_permissions" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.edit_channel_permissions(rl, ch_id, Snowflake(500); token, body=Dict("allow" => "0", "deny" => "0", "type" => 0))
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/permissions/500")
            end
        end

        @testset "delete_channel_permission" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_channel_permission(rl, ch_id, Snowflake(500); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/permissions/500")
            end
        end

        @testset "get_channel_invites" begin
            handler, cap = capture_handler(mock_json([invite_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_channel_invites(rl, ch_id; token)
                @test result isa Vector{Invite}
                @test cap[][1] == "GET"
            end
        end

        @testset "create_channel_invite" begin
            handler, cap = capture_handler(mock_json(invite_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_channel_invite(rl, ch_id; token)
                @test result isa Invite
                @test cap[][1] == "POST"
            end
        end

        @testset "follow_announcement_channel" begin
            handler, cap = capture_handler(mock_json(Dict("channel_id" => "300", "webhook_id" => "600")))
            with_mock_rl(handler) do rl, token
                result = Accord.follow_announcement_channel(rl, ch_id; token, body=Dict("webhook_channel_id" => "301"))
                @test result isa Dict
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/followers")
            end
        end

        @testset "trigger_typing_indicator" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.trigger_typing_indicator(rl, ch_id; token)
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/typing")
            end
        end

        @testset "get_pinned_messages" begin
            handler, cap = capture_handler(mock_json([message_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_pinned_messages(rl, ch_id; token)
                @test result isa Vector{Message}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/pins")
            end
        end

        @testset "pin_message" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.pin_message(rl, ch_id, Snowflake(400); token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/pins/400")
            end
        end

        @testset "unpin_message" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.unpin_message(rl, ch_id, Snowflake(400); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/pins/400")
            end
        end

        @testset "start_thread_from_message" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.start_thread_from_message(rl, ch_id, Snowflake(400); token, body=Dict("name" => "Thread"))
                @test result isa DiscordChannel
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/messages/400/threads")
            end
        end

        @testset "start_thread_without_message" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.start_thread_without_message(rl, ch_id; token, body=Dict("name" => "Thread", "type" => 11))
                @test result isa DiscordChannel
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/channels/300/threads")
            end
        end

        @testset "start_thread_in_forum" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.start_thread_in_forum(rl, ch_id; token, body=Dict("name" => "Thread", "message" => Dict("content" => "hi")))
                @test result isa DiscordChannel
                @test cap[][1] == "POST"
            end
        end

        @testset "join_thread" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.join_thread(rl, ch_id; token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/thread-members/@me")
            end
        end

        @testset "add_thread_member" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.add_thread_member(rl, ch_id, Snowflake(100); token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/thread-members/100")
            end
        end

        @testset "leave_thread" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.leave_thread(rl, ch_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/thread-members/@me")
            end
        end

        @testset "remove_thread_member" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.remove_thread_member(rl, ch_id, Snowflake(100); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/thread-members/100")
            end
        end

        @testset "get_thread_member" begin
            handler, cap = capture_handler(mock_json(thread_member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_thread_member(rl, ch_id, Snowflake(100); token)
                @test result isa ThreadMember
                @test cap[][1] == "GET"
            end
        end

        @testset "list_thread_members" begin
            handler, cap = capture_handler(mock_json([thread_member_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_thread_members(rl, ch_id; token)
                @test result isa Vector{ThreadMember}
                @test cap[][1] == "GET"
            end
        end

        @testset "list_public_archived_threads" begin
            handler, cap = capture_handler(mock_json(Dict("threads" => [], "members" => [], "has_more" => false)))
            with_mock_rl(handler) do rl, token
                result = Accord.list_public_archived_threads(rl, ch_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/threads/archived/public")
            end
        end

        @testset "list_private_archived_threads" begin
            handler, cap = capture_handler(mock_json(Dict("threads" => [], "members" => [], "has_more" => false)))
            with_mock_rl(handler) do rl, token
                result = Accord.list_private_archived_threads(rl, ch_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/threads/archived/private")
            end
        end

        @testset "list_joined_private_archived_threads" begin
            handler, cap = capture_handler(mock_json(Dict("threads" => [], "members" => [], "has_more" => false)))
            with_mock_rl(handler) do rl, token
                result = Accord.list_joined_private_archived_threads(rl, ch_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/threads/archived/private")
            end
        end
    end
end
