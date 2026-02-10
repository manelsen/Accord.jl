# Soundboard REST endpoints

function list_default_soundboard_sounds(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/soundboard-default-sounds"; token)
    parse_response_array(SoundboardSound, resp)
end

function list_guild_soundboard_sounds(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/soundboard-sounds"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

function create_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/soundboard-sounds"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

function modify_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

function delete_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function send_soundboard_sound(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict)
    discord_post(rl, "/channels/$(channel_id)/send-soundboard-sound"; token, body, major_params=["channel_id" => string(channel_id)])
end
