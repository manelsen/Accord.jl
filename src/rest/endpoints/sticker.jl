# Sticker REST endpoints

"""
    get_sticker(rl::RateLimiter, sticker_id::Snowflake; token::String) -> Sticker

Get a sticker by ID.

Use this when a bot needs to retrieve sticker information, such as for
sticker preview commands or content management systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `sticker_id::Snowflake` — The ID of the sticker.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the sticker does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sticker#get-sticker)
"""
function get_sticker(rl::RateLimiter, sticker_id::Snowflake; token::String)
    resp = discord_get(rl, "/stickers/$(sticker_id)"; token)
    parse_response(Sticker, resp)
end

"""
    list_sticker_packs(rl::RateLimiter; token::String) -> Dict{String, Any}

Get the list of default sticker packs available to all users.

Use this when a bot needs to list standard Discord sticker packs, such as
for sticker browsing features or recommendations.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/sticker#get-sticker-packs)
"""
function list_sticker_packs(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/sticker-packs"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    list_guild_stickers(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Sticker}

Get all custom stickers in a guild.

Use this when a bot needs to list guild-specific stickers, such as for
sticker management commands or content discovery.

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

[Discord docs](https://discord.com/developers/docs/resources/sticker#list-guild-stickers)
"""
function list_guild_stickers(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/stickers"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Sticker, resp)
end

"""
    get_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String) -> Sticker

Get a specific custom sticker from a guild.

Use this when a bot needs to retrieve information about a single guild sticker.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sticker_id::Snowflake` — The ID of the sticker.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the sticker or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sticker#get-guild-sticker)
"""
function get_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

"""
    create_guild_sticker(rl::RateLimiter, guild_id::Snowflake; token::String, name::String, description::String, tags::String, file, reason=nothing) -> Sticker

Create a new custom sticker in a guild.

Use this when a bot needs to upload custom stickers programmatically, such as
for sticker management tools or automated sticker creation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `name::String` — Name of the sticker (2-30 characters).
- `description::String` — Description of the sticker (empty or 2-100 characters).
- `tags::String` — Autocomplete/suggestion tags for the sticker (max 200 characters).
- `file` — Sticker image file (PNG, APNG, or Lottie JSON, max 512KB).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Sticker Requirements
- Static stickers must be PNG or APNG format, max 320x320 pixels.
- Animated stickers must be APNG format, max 320x320 pixels.
- File size must not exceed 512KB.

# Errors
- HTTP 400 if the sticker data is invalid or file too large.
- HTTP 403 if missing required permissions or sticker limit reached.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sticker#create-guild-sticker)
"""
function create_guild_sticker(rl::RateLimiter, guild_id::Snowflake; token::String, name::String, description::String, tags::String, file, reason=nothing)
    files = [(name * ".png", file, "image/png")]
    body = Dict("name" => name, "description" => description, "tags" => tags)
    resp = discord_post(rl, "/guilds/$(guild_id)/stickers"; token, body, files, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

"""
    modify_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, body::Dict, reason=nothing) -> Sticker

Modify a custom sticker in a guild.

Use this when a bot needs to update sticker properties such as name,
description, or tags.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sticker_id::Snowflake` — The ID of the sticker to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated sticker fields (name, description, tags).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 400 if the sticker data is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the sticker or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sticker#modify-guild-sticker)
"""
function modify_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Sticker, resp)
end

"""
    delete_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, reason=nothing)

Delete a custom sticker from a guild.

Use this when a bot needs to remove custom stickers, such as for sticker
cleanup or management systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `sticker_id::Snowflake` — The ID of the sticker to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the sticker or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sticker#delete-guild-sticker)
"""
function delete_guild_sticker(rl::RateLimiter, guild_id::Snowflake, sticker_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/stickers/$(sticker_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end
