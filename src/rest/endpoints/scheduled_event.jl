# Scheduled Event REST endpoints

function list_scheduled_events(rl::RateLimiter, guild_id::Snowflake; token::String, with_user_count::Bool=false)
    query = with_user_count ? ["with_user_count" => "true"] : nothing
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response_array(ScheduledEvent, resp)
end

function create_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/scheduled-events"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

function get_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, with_user_count::Bool=false)
    query = with_user_count ? ["with_user_count" => "true"] : nothing
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

function modify_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

function delete_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String)
    discord_delete(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, major_params=["guild_id" => string(guild_id)])
end

function get_guild_scheduled_event_users(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, limit::Int=100, with_member::Bool=false)
    query = ["limit" => string(limit)]
    with_member && push!(query, "with_member" => "true")
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)/users"; token, query, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end
