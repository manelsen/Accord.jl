using Accord, HTTP, JSON3
using Accord: RateLimiter, start_ratelimiter!, stop_ratelimiter!,
    Connection, Integration, WelcomeScreen, Onboarding,
    SoundboardSound, SKU, Entitlement, Subscription,
    parse_response, parse_response_array, url, API_BASE

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
