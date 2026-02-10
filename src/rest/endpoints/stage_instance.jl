# Stage Instance REST endpoints

function create_stage_instance(rl::RateLimiter; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/stage-instances"; token, body, reason=reason)
    parse_response(StageInstance, resp)
end

function get_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/stage-instances/$(channel_id)"; token)
    parse_response(StageInstance, resp)
end

function modify_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/stage-instances/$(channel_id)"; token, body, reason)
    parse_response(StageInstance, resp)
end

function delete_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/stage-instances/$(channel_id)"; token, reason)
end
