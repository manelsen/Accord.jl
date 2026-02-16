# Soundboard REST endpoints

"""
    list_default_soundboard_sounds(rl::RateLimiter; token::String) -> Vector{SoundboardSound}

Get the list of default soundboard sounds available to all users.

Use this when a bot needs to list Discord's built-in soundboard sounds, such
as for sound previews or integration features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#list-default-soundboard-sounds)
"""
function list_default_soundboard_sounds(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/soundboard-default-sounds"; token)
    parse_response_array(SoundboardSound, resp)
end

"""
    list_guild_soundboard_sounds(rl::RateLimiter, guild_id::Snowflake; token::String) -> Dict{String, Any}

Get all custom soundboard sounds for a guild.

Use this when a bot needs to list guild-specific soundboard sounds, such as
for sound management or discovery features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#list-guild-soundboard-sounds)
"""
function list_guild_soundboard_sounds(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/soundboard-sounds"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String) -> SoundboardSound

Get a specific guild soundboard sound.

Use this when a bot needs to retrieve information about a single soundboard
sound, such as for editing or management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sound_id::Snowflake` — The ID of the sound.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the sound or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#get-guild-soundboard-sound)
"""
function get_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

"""
    create_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> SoundboardSound

Create a new soundboard sound in a guild.

Use this when a bot needs to upload custom soundboard sounds programmatically,
such as for sound management tools or automated sound creation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Sound data (name, sound base64, volume, emoji_id/name).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Sound Requirements
- Must be MP3 or OGG format.
- Max duration: 5 seconds.
- Max file size: 512KB.

# Errors
- HTTP 400 if the sound data is invalid or file too large.
- HTTP 403 if missing required permissions.
- HTTP 429 if sound limit reached for the guild.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#create-guild-soundboard-sound)
"""
function create_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/soundboard-sounds"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

"""
    modify_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, body::Dict, reason=nothing) -> SoundboardSound

Modify a guild soundboard sound.

Use this when a bot needs to update sound properties such as name, volume,
or associated emoji.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sound_id::Snowflake` — The ID of the sound to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated sound fields (name, volume, emoji_id, emoji_name).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 400 if the sound data is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the sound or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#modify-guild-soundboard-sound)
"""
function modify_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(SoundboardSound, resp)
end

"""
    delete_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, reason=nothing)

Delete a guild soundboard sound.

Use this when a bot needs to remove soundboard sounds, such as for sound
management or cleanup systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sound_id::Snowflake` — The ID of the sound to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the sound or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#delete-guild-soundboard-sound)
"""
function delete_guild_soundboard_sound(rl::RateLimiter, guild_id::Snowflake, sound_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/soundboard-sounds/$(sound_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    send_soundboard_sound(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict)

Send a soundboard sound to a voice channel.

Use this when a bot needs to trigger a soundboard sound in a voice channel,
such as for automated announcements or interactive voice features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the voice channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Contains `sound_id` of the sound to play.

# Permissions
Requires `SEND_MESSAGES` and the bot must be connected to the voice channel.

# Errors
- HTTP 400 if the sound ID is invalid.
- HTTP 403 if missing required permissions or not in the voice channel.
- HTTP 404 if the channel or sound does not exist.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#send-soundboard-sound)
"""
function send_soundboard_sound(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict)
    discord_post(rl, "/channels/$(channel_id)/send-soundboard-sound"; token, body, major_params=["channel_id" => string(channel_id)])
end
