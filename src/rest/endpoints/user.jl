# User REST endpoints

function get_current_user(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/users/@me"; token)
    parse_response(User, resp)
end

function get_user(rl::RateLimiter, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/$(user_id)"; token)
    parse_response(User, resp)
end

function modify_current_user(rl::RateLimiter; token::String, body::Dict)
    resp = discord_patch(rl, "/users/@me"; token, body)
    parse_response(User, resp)
end

function get_current_user_guilds(rl::RateLimiter; token::String, limit::Int=200)
    resp = discord_get(rl, "/users/@me/guilds"; token, query=["limit" => string(limit)])
    parse_response_array(Guild, resp)
end

function get_current_user_guild_member(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/@me/guilds/$(guild_id)/member"; token)
    parse_response(Member, resp)
end

function leave_guild(rl::RateLimiter, guild_id::Snowflake; token::String)
    discord_delete(rl, "/users/@me/guilds/$(guild_id)"; token)
end

function create_dm(rl::RateLimiter; token::String, recipient_id::Snowflake)
    body = Dict("recipient_id" => string(recipient_id))
    resp = discord_post(rl, "/users/@me/channels"; token, body)
    parse_response(DiscordChannel, resp)
end

function get_current_user_connections(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/users/@me/connections"; token)
    parse_response_array(Connection, resp)
end

function get_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/@me/applications/$(application_id)/role-connection"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

function update_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_put(rl, "/users/@me/applications/$(application_id)/role-connection"; token, body)
    JSON3.read(resp.body, Dict{String, Any})
end
