# Audit Log REST endpoints

"""
    get_guild_audit_log(rl::RateLimiter, guild_id::Snowflake; token::String,
        user_id=nothing, action_type=nothing, before=nothing, after=nothing, limit::Int=50) -> AuditLog

Get the audit log for a guild.

Use this when a bot needs to retrieve guild moderation history, such as for
audit dashboards, logging systems, or tracking administrative actions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `user_id::Snowflake` — Filter by user who made the changes.
- `action_type::Int` — Filter by action type (see `AuditLogEventTypes`).
- `before::Snowflake` — Filter entries before this entry ID.
- `after::Snowflake` — Filter entries after this entry ID.
- `limit::Int` — Maximum entries to return (1-100, default 50).

# Permissions
Requires `VIEW_AUDIT_LOG`.

# Rate Limits
This endpoint has stricter rate limits than most endpoints due to the
sensitivity of audit log data.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log)
"""
function get_guild_audit_log(rl::RateLimiter, guild_id::Snowflake; token::String,
        user_id=nothing, action_type=nothing, before=nothing, after=nothing, limit::Int=50)
    query = ["limit" => string(limit)]
    !isnothing(user_id) && push!(query, "user_id" => string(user_id))
    !isnothing(action_type) && push!(query, "action_type" => string(action_type))
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/guilds/$(guild_id)/audit-logs"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response(AuditLog, resp)
end
