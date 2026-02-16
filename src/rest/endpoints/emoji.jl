# Emoji REST endpoints

"""
    list_guild_emojis(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Emoji}

Get all custom emojis in a guild.

Use this when a bot needs to list available custom emojis, such as for
emoji management commands or reaction role systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#list-guild-emojis)
"""
function list_guild_emojis(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/emojis"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Emoji, resp)
end

"""
    get_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String) -> Emoji

Get a specific custom emoji from a guild.

Use this when a bot needs to retrieve information about a single emoji,
such as its name, roles, or creator.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `emoji_id::Snowflake` — The ID of the emoji.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the emoji or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#get-guild-emoji)
"""
function get_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

"""
    create_guild_emoji(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Emoji

Create a new custom emoji in a guild.

Use this when a bot needs to upload custom emojis programmatically, such as
for emoji management tools or automated emoji creation systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Emoji data (name, image base64, roles).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Emoji Requirements
- Image must be at most 256KB in size.
- Dimensions must be at least 128x128 pixels.
- Supports PNG, JPEG, or GIF formats (animated GIFs allowed with appropriate plan).

# Errors
- HTTP 400 if the image is too large or invalid format.
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#create-guild-emoji)
"""
function create_guild_emoji(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/emojis"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

"""
    modify_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict, reason=nothing) -> Emoji

Modify a custom emoji in a guild.

Use this when a bot needs to update emoji properties such as name or
role restrictions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `emoji_id::Snowflake` — The ID of the emoji to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated emoji fields (name, roles).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 400 if the name is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the emoji or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#modify-guild-emoji)
"""
function modify_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Emoji, resp)
end

"""
    delete_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, reason=nothing)

Delete a custom emoji from a guild.

Use this when a bot needs to remove custom emojis, such as for emoji
cleanup or management systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `emoji_id::Snowflake` — The ID of the emoji to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_GUILD_EXPRESSIONS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the emoji or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#delete-guild-emoji)
"""
function delete_guild_emoji(rl::RateLimiter, guild_id::Snowflake, emoji_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/emojis/$(emoji_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    list_application_emojis(rl::RateLimiter, application_id::Snowflake; token::String) -> Dict{String, Any}

Get all custom emojis for an application.

Use this when a bot needs to list application-owned emojis that can be
used across all guilds the bot is in, such as for premium feature emojis.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the application does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#list-application-emojis)
"""
function list_application_emojis(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/emojis"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String) -> Emoji

Get a specific application-owned emoji.

Use this when a bot needs to retrieve details about an application emoji,
such as for management or configuration purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `emoji_id::Snowflake` — The ID of the emoji.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the emoji or application does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#get-application-emoji)
"""
function get_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token)
    parse_response(Emoji, resp)
end

"""
    create_application_emoji(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict) -> Emoji

Create a new application-owned emoji.

Use this when a bot needs to upload emojis that can be used across all
guilds the bot is in, useful for premium features or consistent branding.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Emoji data (name, image base64).

# Emoji Requirements
- Image must be at most 256KB in size.
- Dimensions must be at least 128x128 pixels.
- Supports PNG, JPEG, or GIF formats.

# Errors
- HTTP 400 if the image is too large or invalid format.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/emoji#create-application-emoji)
"""
function create_application_emoji(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/emojis"; token, body)
    parse_response(Emoji, resp)
end

"""
    modify_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict) -> Emoji

Modify an application-owned emoji.

Use this when a bot needs to update application emoji properties such as name.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `emoji_id::Snowflake` — The ID of the emoji to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated emoji fields (name).

# Errors
- HTTP 400 if the name is invalid.
- HTTP 401 if the token is invalid.
- HTTP 404 if the emoji does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#modify-application-emoji)
"""
function modify_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token, body)
    parse_response(Emoji, resp)
end

"""
    delete_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String)

Delete an application-owned emoji.

Use this when a bot needs to remove application emojis, such as for
cleanup or emoji management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `emoji_id::Snowflake` — The ID of the emoji to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the emoji does not exist.

[Discord docs](https://discord.com/developers/docs/resources/emoji#delete-application-emoji)
"""
function delete_application_emoji(rl::RateLimiter, application_id::Snowflake, emoji_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/emojis/$(emoji_id)"; token)
end
