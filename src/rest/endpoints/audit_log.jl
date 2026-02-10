# Audit Log REST endpoints

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
