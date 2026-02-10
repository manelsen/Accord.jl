# Sticker REST endpoints

function get_sticker(rl::RateLimiter, sticker_id::Snowflake; token::String)
    resp = discord_get(rl, "/stickers/$(sticker_id)"; token)
    parse_response(Sticker, resp)
end

function list_sticker_packs(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/sticker-packs"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

function list_guild_stickers(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/stickers"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Sticker, resp)
end

function get_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

function create_guild_sticker(rl::RateLimiter, guild_id::Snowflake; token::String, name::String, description::String, tags::String, file, reason=nothing)
    files = [(name * ".png", file, "image/png")]
    body = Dict("name" => name, "description" => description, "tags" => tags)
    resp = discord_post(rl, "/guilds/$(guild_id)/stickers"; token, body, files, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

function modify_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

function delete_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end
