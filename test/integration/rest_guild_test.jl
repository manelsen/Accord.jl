@testitem "REST Guild Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP, JSON3
    using Accord: Connection, Integration, WelcomeScreen, Onboarding, SoundboardSound, SKU, Entitlement, Subscription, parse_response, parse_response_array, url, API_BASE

    @testset "Guild Endpoints" begin
        g_id = Snowflake(200)

        @testset "get_guild" begin
            handler, cap = capture_handler(mock_json(guild_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild(rl, g_id; token)
                @test result isa Guild
                @test result.name == "Test Guild"
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200")
            end
        end

        @testset "get_guild_preview" begin
            handler, cap = capture_handler(mock_json(guild_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_preview(rl, g_id; token)
                @test result isa Guild
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/preview")
            end
        end

        @testset "modify_guild" begin
            handler, cap = capture_handler(mock_json(guild_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild(rl, g_id; token, body=Dict("name" => "New Name"))
                @test result isa Guild
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild(rl, g_id; token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/guilds/200")
            end
        end

        @testset "get_guild_channels" begin
            handler, cap = capture_handler(mock_json([channel_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_channels(rl, g_id; token)
                @test result isa Vector{DiscordChannel}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/channels")
            end
        end

        @testset "create_guild_channel" begin
            handler, cap = capture_handler(mock_json(channel_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_channel(rl, g_id; token, body=Dict("name" => "new-channel"))
                @test result isa DiscordChannel
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_guild_channel_positions" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.modify_guild_channel_positions(rl, g_id; token, body=[Dict("id" => "300", "position" => 1)])
                @test cap[][1] == "PATCH"
                @test contains(cap[][2], "/guilds/200/channels")
            end
        end

        @testset "list_active_guild_threads" begin
            handler, cap = capture_handler(mock_json(Dict("threads" => [], "members" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.list_active_guild_threads(rl, g_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/threads/active")
            end
        end

        @testset "get_guild_member" begin
            handler, cap = capture_handler(mock_json(member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_member(rl, g_id, Snowflake(100); token)
                @test result isa Member
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/members/100")
            end
        end

        @testset "list_guild_members" begin
            handler, cap = capture_handler(mock_json([member_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_guild_members(rl, g_id; token)
                @test result isa Vector{Member}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/members")
            end
        end

        @testset "search_guild_members" begin
            handler, cap = capture_handler(mock_json([member_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.search_guild_members(rl, g_id; token, query_str="test")
                @test result isa Vector{Member}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/members/search")
            end
        end

        @testset "modify_guild_member" begin
            handler, cap = capture_handler(mock_json(member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_member(rl, g_id, Snowflake(100); token, body=Dict("nick" => "new"))
                @test result isa Member
                @test cap[][1] == "PATCH"
            end
        end

        @testset "modify_current_member" begin
            handler, cap = capture_handler(mock_json(member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_current_member(rl, g_id; token, body=Dict("nick" => "me"))
                @test result isa Member
                @test cap[][1] == "PATCH"
                @test contains(cap[][2], "/members/@me")
            end
        end

        @testset "add_guild_member" begin
            handler, cap = capture_handler(mock_json(member_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.add_guild_member(rl, g_id, Snowflake(100); token, body=Dict("access_token" => "tok"))
                @test result isa Member
                @test cap[][1] == "PUT"
            end
        end

        @testset "add_guild_member_role" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.add_guild_member_role(rl, g_id, Snowflake(100), Snowflake(500); token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/members/100/roles/500")
            end
        end

        @testset "remove_guild_member_role" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.remove_guild_member_role(rl, g_id, Snowflake(100), Snowflake(500); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/members/100/roles/500")
            end
        end

        @testset "remove_guild_member" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.remove_guild_member(rl, g_id, Snowflake(100); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/guilds/200/members/100")
            end
        end

        @testset "get_guild_bans" begin
            handler, cap = capture_handler(mock_json([ban_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_bans(rl, g_id; token)
                @test result isa Vector{Ban}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/bans")
            end
        end

        @testset "get_guild_ban" begin
            handler, cap = capture_handler(mock_json(ban_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_ban(rl, g_id, Snowflake(100); token)
                @test result isa Ban
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/bans/100")
            end
        end

        @testset "create_guild_ban" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.create_guild_ban(rl, g_id, Snowflake(100); token)
                @test cap[][1] == "PUT"
                @test contains(cap[][2], "/guilds/200/bans/100")
            end
        end

        @testset "remove_guild_ban" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.remove_guild_ban(rl, g_id, Snowflake(100); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/guilds/200/bans/100")
            end
        end

        @testset "bulk_guild_ban" begin
            handler, cap = capture_handler(mock_json(Dict("banned_users" => ["100"], "failed_users" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.bulk_guild_ban(rl, g_id; token, body=Dict("user_ids" => ["100"]))
                @test result isa Dict
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/guilds/200/bulk-ban")
            end
        end

        @testset "get_guild_roles" begin
            handler, cap = capture_handler(mock_json([role_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_roles(rl, g_id; token)
                @test result isa Vector{Role}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/roles")
            end
        end

        @testset "get_guild_role" begin
            handler, cap = capture_handler(mock_json(role_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_role(rl, g_id, Snowflake(500); token)
                @test result isa Role
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/roles/500")
            end
        end

        @testset "create_guild_role" begin
            handler, cap = capture_handler(mock_json(role_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_role(rl, g_id; token)
                @test result isa Role
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_guild_role_positions" begin
            handler, cap = capture_handler(mock_json([role_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_role_positions(rl, g_id; token, body=[Dict("id" => "500", "position" => 1)])
                @test result isa Vector{Role}
                @test cap[][1] == "PATCH"
            end
        end

        @testset "modify_guild_role" begin
            handler, cap = capture_handler(mock_json(role_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_role(rl, g_id, Snowflake(500); token, body=Dict("name" => "new"))
                @test result isa Role
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_role" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_role(rl, g_id, Snowflake(500); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/guilds/200/roles/500")
            end
        end

        @testset "get_guild_prune_count" begin
            handler, cap = capture_handler(mock_json(Dict("pruned" => 0)))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_prune_count(rl, g_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/prune")
            end
        end

        @testset "begin_guild_prune" begin
            handler, cap = capture_handler(mock_json(Dict("pruned" => 0)))
            with_mock_rl(handler) do rl, token
                result = Accord.begin_guild_prune(rl, g_id; token, body=Dict("days" => 7))
                @test result isa Dict
                @test cap[][1] == "POST"
            end
        end

        @testset "get_guild_voice_regions" begin
            handler, cap = capture_handler(mock_json([voice_region_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_voice_regions(rl, g_id; token)
                @test result isa Vector{VoiceRegion}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/regions")
            end
        end

        @testset "get_guild_invites" begin
            handler, cap = capture_handler(mock_json([invite_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_invites(rl, g_id; token)
                @test result isa Vector{Invite}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/invites")
            end
        end

        @testset "get_guild_integrations" begin
            handler, cap = capture_handler(mock_json([integration_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_integrations(rl, g_id; token)
                @test result isa Vector{Integration}
                @test cap[][1] == "GET"
            end
        end

        @testset "delete_guild_integration" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_integration(rl, g_id, Snowflake(1600); token)
                @test cap[][1] == "DELETE"
                @test contains(cap[][2], "/integrations/1600")
            end
        end

        @testset "get_guild_widget_settings" begin
            handler, cap = capture_handler(mock_json(Dict("enabled" => false, "channel_id" => nothing)))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_widget_settings(rl, g_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/widget")
            end
        end

        @testset "modify_guild_widget" begin
            handler, cap = capture_handler(mock_json(Dict("enabled" => true)))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_widget(rl, g_id; token, body=Dict("enabled" => true))
                @test result isa Dict
                @test cap[][1] == "PATCH"
            end
        end

        @testset "get_guild_widget" begin
            handler, cap = capture_handler(mock_json(Dict("id" => "200", "name" => "Test")))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_widget(rl, g_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/widget.json")
            end
        end

        @testset "get_guild_vanity_url" begin
            handler, cap = capture_handler(mock_json(invite_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_vanity_url(rl, g_id; token)
                @test result isa Invite
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/vanity-url")
            end
        end

        @testset "get_guild_welcome_screen" begin
            handler, cap = capture_handler(mock_json(welcome_screen_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_welcome_screen(rl, g_id; token)
                @test result isa WelcomeScreen
                @test cap[][1] == "GET"
            end
        end

        @testset "modify_guild_welcome_screen" begin
            handler, cap = capture_handler(mock_json(welcome_screen_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_welcome_screen(rl, g_id; token, body=Dict())
                @test result isa WelcomeScreen
                @test cap[][1] == "PATCH"
            end
        end

        @testset "get_guild_onboarding" begin
            handler, cap = capture_handler(mock_json(onboarding_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_onboarding(rl, g_id; token)
                @test result isa Onboarding
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/onboarding")
            end
        end

        @testset "modify_guild_onboarding" begin
            handler, cap = capture_handler(mock_json(onboarding_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_onboarding(rl, g_id; token, body=Dict())
                @test result isa Onboarding
                @test cap[][1] == "PUT"
            end
        end
    end
end
