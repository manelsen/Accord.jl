# Emoji REST endpoints

function list_guild_emojis(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/emojis"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Emoji, resp)
end

function get_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

function create_guild_emoji(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/emojis"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

function modify_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

function delete_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function list_application_emojis(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/emojis"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

function get_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token)
    parse_response(Emoji, resp)
end

function create_application_emoji(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/emojis"; token, body)
    parse_response(Emoji, resp)
end

function modify_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token, body)
    parse_response(Emoji, resp)
end

function delete_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token)
end
