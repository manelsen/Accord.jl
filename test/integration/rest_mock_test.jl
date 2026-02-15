@testitem "REST Mock Integration" tags=[:integration] begin
    using Accord, HTTP, JSON3
    using Accord: parse_response, parse_response_array, discord_get, discord_post,
        discord_put, discord_patch, discord_delete, discord_request,
        start_ratelimiter!, stop_ratelimiter!, submit_rest, RestJob, Route, url,
        API_BASE, USER_AGENT, RateLimiter,
        Connection, Integration, WelcomeScreen, Onboarding,
        SoundboardSound, SKU, Entitlement, Subscription

# ─── Helper ──────────────────────────────────────────────────────────────────

"""Run `f(rl, token)` with a mock RateLimiter that captures requests."""
function with_mock_rl(f, handler)
    rl = RateLimiter()
    rl.request_handler = handler
    start_ratelimiter!(rl)
    try
        f(rl, "Bot mock_token")
    finally
        stop_ratelimiter!(rl)
    end
end

"""Create a mock HTTP.Response with JSON body."""
mock_json(body; status=200) = HTTP.Response(status, JSON3.write(body))

"""Minimal JSON for a User."""
user_json() = Dict("id" => "100", "username" => "testuser", "discriminator" => "0001")

"""Minimal JSON for a Guild."""
guild_json() = Dict("id" => "200", "name" => "Test Guild")

"""Minimal JSON for a DiscordChannel."""
channel_json() = Dict("id" => "300", "type" => 0)

"""Minimal JSON for a Message."""
message_json() = Dict("id" => "400", "channel_id" => "300", "type" => 0, "content" => "hello", "author" => user_json())

"""Minimal JSON for a Role."""
role_json() = Dict("id" => "500", "name" => "Test Role", "color" => 0, "hoist" => false, "position" => 1, "permissions" => "0", "managed" => false, "mentionable" => false)

"""Minimal JSON for a Member."""
member_json() = Dict("user" => user_json(), "roles" => [], "joined_at" => "2020-01-01T00:00:00Z", "deaf" => false, "mute" => false)

"""Minimal JSON for an Embed."""
embed_json() = Dict("title" => "Test", "type" => "rich")

"""Minimal JSON for an Invite."""
invite_json() = Dict("code" => "abc123")

"""Minimal JSON for a Webhook."""
webhook_json() = Dict("id" => "600", "type" => 1, "channel_id" => "300")

"""Minimal JSON for a Ban."""
ban_json() = Dict("user" => user_json(), "reason" => "test")

"""Minimal JSON for an Emoji."""
emoji_json() = Dict("id" => "700", "name" => "test_emoji")

"""Minimal JSON for a Sticker."""
sticker_json() = Dict("id" => "800", "name" => "test_sticker", "format_type" => 1)

"""Minimal JSON for an ApplicationCommand."""
app_cmd_json() = Dict("id" => "900", "application_id" => "1000", "name" => "test", "description" => "test cmd", "type" => 1)

"""Minimal JSON for an AuditLog."""
audit_log_json() = Dict("audit_log_entries" => [], "users" => [], "integrations" => [], "webhooks" => [], "guild_scheduled_events" => [], "threads" => [], "application_commands" => [], "auto_moderation_rules" => [])

"""Minimal JSON for an AutoModRule."""
automod_rule_json() = Dict("id" => "1100", "guild_id" => "200", "name" => "test rule", "creator_id" => "100", "event_type" => 1, "trigger_type" => 1, "trigger_metadata" => Dict(), "actions" => [], "enabled" => true, "exempt_roles" => [], "exempt_channels" => [])

"""Minimal JSON for a ScheduledEvent."""
scheduled_event_json() = Dict("id" => "1200", "guild_id" => "200", "name" => "Test Event", "scheduled_start_time" => "2025-01-01T00:00:00Z", "privacy_level" => 2, "status" => 1, "entity_type" => 3)

"""Minimal JSON for a StageInstance."""
stage_instance_json() = Dict("id" => "1300", "guild_id" => "200", "channel_id" => "300", "topic" => "Test Stage", "privacy_level" => 2)

"""Minimal JSON for a SoundboardSound."""
soundboard_json() = Dict("sound_id" => "1400", "name" => "test_sound", "volume" => 1.0)

"""Minimal JSON for a VoiceRegion."""
voice_region_json() = Dict("id" => "us-west", "name" => "US West", "optimal" => true, "deprecated" => false, "custom" => false)

"""Minimal JSON for a GuildTemplate."""
guild_template_json() = Dict("code" => "abc", "name" => "Test Template", "usage_count" => 0, "creator_id" => "100", "source_guild_id" => "200", "serialized_source_guild" => guild_json(), "created_at" => "2020-01-01T00:00:00Z", "updated_at" => "2020-01-01T00:00:00Z")

"""Minimal JSON for a Connection."""
connection_json() = Dict("id" => "1500", "name" => "test", "type" => "twitch", "verified" => true, "friend_sync" => false, "show_activity" => true, "visibility" => 1)

"""Minimal JSON for a ThreadMember."""
thread_member_json() = Dict("join_timestamp" => "2020-01-01T00:00:00Z", "flags" => 0)

"""Minimal JSON for an Integration."""
integration_json() = Dict("id" => "1600", "name" => "test", "type" => "twitch", "enabled" => true)

"""Minimal JSON for a WelcomeScreen."""
welcome_screen_json() = Dict("description" => "Welcome!", "welcome_channels" => [])

"""Minimal JSON for an Onboarding."""
onboarding_json() = Dict("guild_id" => "200", "prompts" => [], "default_channel_ids" => [], "enabled" => false)

"""Minimal JSON for a SKU."""
sku_json() = Dict("id" => "1700", "type" => 5, "application_id" => "1000", "name" => "Test SKU", "slug" => "test-sku")

"""Minimal JSON for an Entitlement."""
entitlement_json() = Dict("id" => "1800", "sku_id" => "1700", "application_id" => "1000", "type" => 1)

"""Minimal JSON for a Subscription."""
subscription_json() = Dict("id" => "1900", "user_id" => "100", "sku_ids" => ["1700"], "entitlement_ids" => ["1800"], "current_period_start" => "2025-01-01T00:00:00Z", "current_period_end" => "2025-02-01T00:00:00Z", "status" => 0, "canceled_at" => nothing, "country" => nothing)

# ─── Captured request info ───────────────────────────────────────────────────

"""Create a handler that captures (method, url) and returns a mock response."""
function capture_handler(response)
    captured = Ref{Tuple{String,String}}(("", ""))
    handler = (method, url, headers, body) -> begin
        captured[] = (method, url)
        return response
    end
    return handler, captured
end

# ═════════════════════════════════════════════════════════════════════════════
# USER ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════



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

# ═════════════════════════════════════════════════════════════════════════════
# MESSAGE ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# GUILD ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# CHANNEL ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# INTERACTION / APPLICATION COMMAND ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# WEBHOOK ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# EMOJI ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Emoji Endpoints" begin
    g_id = Snowflake(200)
    e_id = Snowflake(700)

    @testset "list_guild_emojis" begin
        handler, cap = capture_handler(mock_json([emoji_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_guild_emojis(rl, g_id; token)
            @test result isa Vector{Emoji}
            @test cap[][1] == "GET"
        end
    end

    @testset "get_guild_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_emoji(rl, g_id, e_id; token)
            @test result isa Emoji
            @test cap[][1] == "GET"
        end
    end

    @testset "create_guild_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_guild_emoji(rl, g_id; token, body=Dict("name" => "test", "image" => "data:..."))
            @test result isa Emoji
            @test cap[][1] == "POST"
        end
    end

    @testset "modify_guild_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_guild_emoji(rl, g_id, e_id; token, body=Dict("name" => "renamed"))
            @test result isa Emoji
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_guild_emoji" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_guild_emoji(rl, g_id, e_id; token)
            @test cap[][1] == "DELETE"
        end
    end

    @testset "list_application_emojis" begin
        handler, cap = capture_handler(mock_json(Dict("items" => [emoji_json()])))
        with_mock_rl(handler) do rl, token
            result = Accord.list_application_emojis(rl, Snowflake(1000); token)
            @test result isa Dict
            @test cap[][1] == "GET"
        end
    end

    @testset "get_application_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_application_emoji(rl, Snowflake(1000), e_id; token)
            @test result isa Emoji
            @test cap[][1] == "GET"
        end
    end

    @testset "create_application_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_application_emoji(rl, Snowflake(1000); token, body=Dict("name" => "test", "image" => "data:..."))
            @test result isa Emoji
            @test cap[][1] == "POST"
        end
    end

    @testset "modify_application_emoji" begin
        handler, cap = capture_handler(mock_json(emoji_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_application_emoji(rl, Snowflake(1000), e_id; token, body=Dict("name" => "renamed"))
            @test result isa Emoji
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_application_emoji" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_application_emoji(rl, Snowflake(1000), e_id; token)
            @test cap[][1] == "DELETE"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# STICKER ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Sticker Endpoints" begin
    g_id = Snowflake(200)
    s_id = Snowflake(800)

    @testset "get_sticker" begin
        handler, cap = capture_handler(mock_json(sticker_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_sticker(rl, s_id; token)
            @test result isa Sticker
            @test cap[][1] == "GET"
        end
    end

    @testset "list_sticker_packs" begin
        handler, cap = capture_handler(mock_json(Dict("sticker_packs" => [])))
        with_mock_rl(handler) do rl, token
            result = Accord.list_sticker_packs(rl; token)
            @test result isa Dict
            @test cap[][1] == "GET"
        end
    end

    @testset "list_guild_stickers" begin
        handler, cap = capture_handler(mock_json([sticker_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_guild_stickers(rl, g_id; token)
            @test result isa Vector{Sticker}
            @test cap[][1] == "GET"
        end
    end

    @testset "get_guild_sticker" begin
        handler, cap = capture_handler(mock_json(sticker_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_sticker(rl, g_id, s_id; token)
            @test result isa Sticker
            @test cap[][1] == "GET"
        end
    end

    @testset "modify_guild_sticker" begin
        handler, cap = capture_handler(mock_json(sticker_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_guild_sticker(rl, g_id, s_id; token, body=Dict("name" => "renamed"))
            @test result isa Sticker
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_guild_sticker" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_guild_sticker(rl, g_id, s_id; token)
            @test cap[][1] == "DELETE"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# INVITE ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Invite Endpoints" begin
    @testset "get_invite" begin
        handler, cap = capture_handler(mock_json(invite_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_invite(rl, "abc123"; token)
            @test result isa Invite
            @test cap[][1] == "GET"
            @test contains(cap[][2], "/invites/abc123")
        end
    end

    @testset "delete_invite" begin
        handler, cap = capture_handler(mock_json(invite_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.delete_invite(rl, "abc123"; token)
            @test result isa Invite
            @test cap[][1] == "DELETE"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# AUDIT LOG ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Audit Log Endpoints" begin
    @testset "get_guild_audit_log" begin
        handler, cap = capture_handler(mock_json(audit_log_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_audit_log(rl, Snowflake(200); token)
            @test result isa AuditLog
            @test cap[][1] == "GET"
            @test contains(cap[][2], "/guilds/200/audit-logs")
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# AUTOMOD ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "AutoMod Endpoints" begin
    g_id = Snowflake(200)
    rule_id = Snowflake(1100)

    @testset "list_auto_moderation_rules" begin
        handler, cap = capture_handler(mock_json([automod_rule_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_auto_moderation_rules(rl, g_id; token)
            @test result isa Vector{AutoModRule}
            @test cap[][1] == "GET"
        end
    end

    @testset "get_auto_moderation_rule" begin
        handler, cap = capture_handler(mock_json(automod_rule_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_auto_moderation_rule(rl, g_id, rule_id; token)
            @test result isa AutoModRule
            @test cap[][1] == "GET"
        end
    end

    @testset "create_auto_moderation_rule" begin
        handler, cap = capture_handler(mock_json(automod_rule_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_auto_moderation_rule(rl, g_id; token, body=Dict("name" => "rule"))
            @test result isa AutoModRule
            @test cap[][1] == "POST"
        end
    end

    @testset "modify_auto_moderation_rule" begin
        handler, cap = capture_handler(mock_json(automod_rule_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_auto_moderation_rule(rl, g_id, rule_id; token, body=Dict("name" => "updated"))
            @test result isa AutoModRule
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_auto_moderation_rule" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_auto_moderation_rule(rl, g_id, rule_id; token)
            @test cap[][1] == "DELETE"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# SCHEDULED EVENT ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Scheduled Event Endpoints" begin
    g_id = Snowflake(200)
    ev_id = Snowflake(1200)

    @testset "list_scheduled_events" begin
        handler, cap = capture_handler(mock_json([scheduled_event_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_scheduled_events(rl, g_id; token)
            @test result isa Vector{ScheduledEvent}
            @test cap[][1] == "GET"
        end
    end

    @testset "create_guild_scheduled_event" begin
        handler, cap = capture_handler(mock_json(scheduled_event_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_guild_scheduled_event(rl, g_id; token, body=Dict("name" => "Event"))
            @test result isa ScheduledEvent
            @test cap[][1] == "POST"
        end
    end

    @testset "get_guild_scheduled_event" begin
        handler, cap = capture_handler(mock_json(scheduled_event_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_scheduled_event(rl, g_id, ev_id; token)
            @test result isa ScheduledEvent
            @test cap[][1] == "GET"
        end
    end

    @testset "modify_guild_scheduled_event" begin
        handler, cap = capture_handler(mock_json(scheduled_event_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_guild_scheduled_event(rl, g_id, ev_id; token, body=Dict("name" => "Updated"))
            @test result isa ScheduledEvent
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_guild_scheduled_event" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_guild_scheduled_event(rl, g_id, ev_id; token)
            @test cap[][1] == "DELETE"
        end
    end

    @testset "get_guild_scheduled_event_users" begin
        handler, cap = capture_handler(mock_json(Dict("users" => [])))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_scheduled_event_users(rl, g_id, ev_id; token)
            @test result isa Dict
            @test cap[][1] == "GET"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# STAGE INSTANCE ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Stage Instance Endpoints" begin
    @testset "create_stage_instance" begin
        handler, cap = capture_handler(mock_json(stage_instance_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_stage_instance(rl; token, body=Dict("channel_id" => "300", "topic" => "Test"))
            @test result isa StageInstance
            @test cap[][1] == "POST"
        end
    end

    @testset "get_stage_instance" begin
        handler, cap = capture_handler(mock_json(stage_instance_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_stage_instance(rl, Snowflake(300); token)
            @test result isa StageInstance
            @test cap[][1] == "GET"
        end
    end

    @testset "modify_stage_instance" begin
        handler, cap = capture_handler(mock_json(stage_instance_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_stage_instance(rl, Snowflake(300); token, body=Dict("topic" => "Updated"))
            @test result isa StageInstance
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_stage_instance" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_stage_instance(rl, Snowflake(300); token)
            @test cap[][1] == "DELETE"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# SOUNDBOARD ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Soundboard Endpoints" begin
    g_id = Snowflake(200)
    snd_id = Snowflake(1400)

    @testset "list_default_soundboard_sounds" begin
        handler, cap = capture_handler(mock_json([soundboard_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_default_soundboard_sounds(rl; token)
            @test result isa Vector{SoundboardSound}
            @test cap[][1] == "GET"
        end
    end

    @testset "list_guild_soundboard_sounds" begin
        handler, cap = capture_handler(mock_json(Dict("items" => [soundboard_json()])))
        with_mock_rl(handler) do rl, token
            result = Accord.list_guild_soundboard_sounds(rl, g_id; token)
            @test result isa Dict
            @test cap[][1] == "GET"
        end
    end

    @testset "get_guild_soundboard_sound" begin
        handler, cap = capture_handler(mock_json(soundboard_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_soundboard_sound(rl, g_id, snd_id; token)
            @test result isa SoundboardSound
            @test cap[][1] == "GET"
        end
    end

    @testset "create_guild_soundboard_sound" begin
        handler, cap = capture_handler(mock_json(soundboard_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_guild_soundboard_sound(rl, g_id; token, body=Dict("name" => "test", "sound" => "data:..."))
            @test result isa SoundboardSound
            @test cap[][1] == "POST"
        end
    end

    @testset "modify_guild_soundboard_sound" begin
        handler, cap = capture_handler(mock_json(soundboard_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_guild_soundboard_sound(rl, g_id, snd_id; token, body=Dict("name" => "renamed"))
            @test result isa SoundboardSound
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_guild_soundboard_sound" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_guild_soundboard_sound(rl, g_id, snd_id; token)
            @test cap[][1] == "DELETE"
        end
    end

    @testset "send_soundboard_sound" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.send_soundboard_sound(rl, Snowflake(300); token, body=Dict("sound_id" => "1400"))
            @test cap[][1] == "POST"
            @test contains(cap[][2], "/send-soundboard-sound")
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# VOICE ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Voice Endpoints" begin
    @testset "list_voice_regions" begin
        handler, cap = capture_handler(mock_json([voice_region_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_voice_regions(rl; token)
            @test result isa Vector{VoiceRegion}
            @test cap[][1] == "GET"
            @test contains(cap[][2], "/voice/regions")
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# SKU / ENTITLEMENT / SUBSCRIPTION ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "SKU/Entitlement/Subscription Endpoints" begin
    app_id = Snowflake(1000)
    sku_id = Snowflake(1700)
    ent_id = Snowflake(1800)

    @testset "list_skus" begin
        handler, cap = capture_handler(mock_json([sku_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_skus(rl, app_id; token)
            @test result isa Vector{SKU}
            @test cap[][1] == "GET"
        end
    end

    @testset "list_entitlements" begin
        handler, cap = capture_handler(mock_json([entitlement_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_entitlements(rl, app_id; token)
            @test result isa Vector{Entitlement}
            @test cap[][1] == "GET"
        end
    end

    @testset "create_test_entitlement" begin
        handler, cap = capture_handler(mock_json(entitlement_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_test_entitlement(rl, app_id; token, body=Dict("sku_id" => "1700", "owner_id" => "100", "owner_type" => 2))
            @test result isa Entitlement
            @test cap[][1] == "POST"
        end
    end

    @testset "delete_test_entitlement" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_test_entitlement(rl, app_id, ent_id; token)
            @test cap[][1] == "DELETE"
        end
    end

    @testset "consume_entitlement" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.consume_entitlement(rl, app_id, ent_id; token)
            @test cap[][1] == "POST"
            @test contains(cap[][2], "/consume")
        end
    end

    @testset "get_entitlement" begin
        handler, cap = capture_handler(mock_json(entitlement_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_entitlement(rl, app_id, ent_id; token)
            @test result isa Entitlement
            @test cap[][1] == "GET"
        end
    end

    @testset "list_sku_subscriptions" begin
        handler, cap = capture_handler(mock_json([subscription_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.list_sku_subscriptions(rl, sku_id; token)
            @test result isa Vector{Subscription}
            @test cap[][1] == "GET"
        end
    end

    @testset "get_sku_subscription" begin
        handler, cap = capture_handler(mock_json(subscription_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.get_sku_subscription(rl, sku_id, Snowflake(1900); token)
            @test result isa Subscription
            @test cap[][1] == "GET"
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# GUILD TEMPLATE ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@testset "Guild Template Endpoints" begin
    g_id = Snowflake(200)

    @testset "get_guild_templates" begin
        handler, cap = capture_handler(mock_json([guild_template_json()]))
        with_mock_rl(handler) do rl, token
            result = Accord.get_guild_templates(rl, g_id; token)
            @test result isa Vector{GuildTemplate}
            @test cap[][1] == "GET"
            @test contains(cap[][2], "/guilds/200/templates")
        end
    end

    @testset "create_guild_template" begin
        handler, cap = capture_handler(mock_json(guild_template_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_guild_template(rl, g_id; token, body=Dict("name" => "Template"))
            @test result isa GuildTemplate
            @test cap[][1] == "POST"
        end
    end

    @testset "sync_guild_template" begin
        handler, cap = capture_handler(mock_json(guild_template_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.sync_guild_template(rl, g_id, "abc"; token)
            @test result isa GuildTemplate
            @test cap[][1] == "PUT"
        end
    end

    @testset "modify_guild_template" begin
        handler, cap = capture_handler(mock_json(guild_template_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.modify_guild_template(rl, g_id, "abc"; token, body=Dict("name" => "Updated"))
            @test result isa GuildTemplate
            @test cap[][1] == "PATCH"
        end
    end

    @testset "delete_guild_template" begin
        handler, cap = capture_handler(HTTP.Response(204))
        with_mock_rl(handler) do rl, token
            Accord.delete_guild_template(rl, g_id, "abc"; token)
            @test cap[][1] == "DELETE"
        end
    end

    @testset "create_guild_from_template" begin
        handler, cap = capture_handler(mock_json(guild_json()))
        with_mock_rl(handler) do rl, token
            result = Accord.create_guild_from_template(rl, "abc"; token, body=Dict("name" => "New Guild"))
            @test result isa Guild
            @test cap[][1] == "POST"
            @test contains(cap[][2], "/guilds/templates/abc")
        end
    end
end

# ═════════════════════════════════════════════════════════════════════════════
# APPLICATION ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

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

# ═════════════════════════════════════════════════════════════════════════════
# HTTP CLIENT LAYER
# ═════════════════════════════════════════════════════════════════════════════

@testset "HTTP Client Layer" begin
    @testset "parse_response success" begin
        resp = mock_json(user_json())
        result = parse_response(User, resp)
        @test result isa User
        @test result.username == "testuser"
    end

    @testset "parse_response error" begin
        resp = HTTP.Response(400, JSON3.write(Dict("message" => "Bad Request")))
        @test_throws ErrorException parse_response(User, resp)
    end

    @testset "parse_response_array success" begin
        resp = mock_json([user_json(), user_json()])
        result = parse_response_array(User, resp)
        @test result isa Vector{User}
        @test length(result) == 2
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
        @test url(route) == "$(API_BASE)/guilds/123/channels"
    end

    @testset "Route bucket key without major params" begin
        route = Route("GET", "/gateway/bot")
        @test route.method == "GET"
        @test route.path == "/gateway/bot"
    end
end

end
