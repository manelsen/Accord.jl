# User REST endpoints

"""
    get_current_user(rl::RateLimiter; token::String) -> User

Get the bot's own user object.

Use this when a bot needs to retrieve its own user information, such as
username, ID, avatar, and discriminator. This is commonly used during
initialization to confirm authentication.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid or expired.

[Discord docs](https://discord.com/developers/docs/resources/user#get-current-user)
"""
function get_current_user(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/users/@me"; token)
    parse_response(User, resp)
end

"""
    get_user(rl::RateLimiter, user_id::Snowflake; token::String) -> User

Get a user by ID.

Use this when a bot needs to retrieve information about a specific user,
such as username, avatar, or public flags. Only returns public information.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `user_id::Snowflake` — The ID of the user to retrieve.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the user does not exist.

[Discord docs](https://discord.com/developers/docs/resources/user#get-user)
"""
function get_user(rl::RateLimiter, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/$(user_id)"; token)
    parse_response(User, resp)
end

"""
    modify_current_user(rl::RateLimiter; token::String, body::Dict) -> User

Modify the bot's own user account settings.

Use this when a bot needs to update its own profile, such as changing its
username or avatar. Use with caution as username changes are rate limited.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — User fields to update (username, avatar base64).

# Rate Limits
Username changes are heavily rate limited (typically twice per hour).

# Errors
- HTTP 400 if the username or avatar is invalid.
- HTTP 401 if the token is invalid.
- HTTP 429 if too many username changes attempted.

[Discord docs](https://discord.com/developers/docs/resources/user#modify-current-user)
"""
function modify_current_user(rl::RateLimiter; token::String, body::Dict)
    resp = discord_patch(rl, "/users/@me"; token, body)
    parse_response(User, resp)
end

"""
    get_current_user_guilds(rl::RateLimiter; token::String, limit::Int=200, before::Optional{Snowflake}=missing, after::Optional{Snowflake}=missing) -> Vector{Guild}

Get the guilds the bot is a member of.

Use this when a bot needs to list the servers it has joined, such as for
guild management features or admin dashboards.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum guilds to return (1-200, default 200).
- `before::Snowflake` — Get guilds before this guild ID.
- `after::Snowflake` — Get guilds after this guild ID.

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/user#get-current-user-guilds)
"""
function get_current_user_guilds(rl::RateLimiter; token::String, limit::Int=200, before::Optional{Snowflake}=missing, after::Optional{Snowflake}=missing)
    query = ["limit" => string(limit)]
    !ismissing(before) && push!(query, "before" => string(before))
    !ismissing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/users/@me/guilds"; token, query=query)
    parse_response_array(Guild, resp)
end

"""
    get_current_user_guild_member(rl::RateLimiter, guild_id::Snowflake; token::String) -> Member

Get the bot's guild member object for a specific guild.

Use this when a bot needs to check its own permissions, roles, or nickname
in a particular server, such as for permission validation before actions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the bot is not a member of the guild.

[Discord docs](https://discord.com/developers/docs/resources/user#get-current-user-guild-member)
"""
function get_current_user_guild_member(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/@me/guilds/$(guild_id)/member"; token)
    parse_response(Member, resp)
end

"""
    leave_guild(rl::RateLimiter, guild_id::Snowflake; token::String)

Leave a guild (server).

Use this when a bot needs to programmatically leave a server, such as for
bot removal commands or guild blacklisting systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild to leave.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the bot is not a member of the guild.

[Discord docs](https://discord.com/developers/docs/resources/user#leave-guild)
"""
function leave_guild(rl::RateLimiter, guild_id::Snowflake; token::String)
    discord_delete(rl, "/users/@me/guilds/$(guild_id)"; token)
end

"""
    create_dm(rl::RateLimiter; token::String, recipient_id::Snowflake) -> DiscordChannel

Create a direct message channel with a user.

Use this when a bot needs to initiate a private conversation with a user,
such as for sending DMs, confirmation messages, or support interactions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `recipient_id::Snowflake` — The ID of the user to create a DM with.

# Notes
- You should not use this endpoint to spam users or send unsolicited messages.
- The bot cannot DM users who have not enabled DMs from server members.

# Errors
- HTTP 400 if the user cannot be messaged.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/user#create-dm)
"""
function create_dm(rl::RateLimiter; token::String, recipient_id::Snowflake)
    body = Dict("recipient_id" => string(recipient_id))
    resp = discord_post(rl, "/users/@me/channels"; token, body)
    parse_response(DiscordChannel, resp)
end

"""
    get_current_user_connections(rl::RateLimiter; token::String) -> Vector{Connection}

Get the third-party connections linked to the bot's account.

Use this when a bot needs to retrieve connected services such as Twitch,
YouTube, Spotify, or other OAuth-linked platforms. Note that bots typically
do not have connections, this is more useful for OAuth2 applications.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Authentication token (can be OAuth2 user token).

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/user#get-user-connections)
"""
function get_current_user_connections(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/users/@me/connections"; token)
    parse_response_array(Connection, resp)
end

"""
    get_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String) -> Dict{String, Any}

Get the role connection metadata for the bot's account.

Use this when a bot needs to retrieve Linked Role verification data for
the current user (typically used with OAuth2 applications for role verification).

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Authentication token (typically OAuth2 user token).

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if no role connection exists.

[Discord docs](https://discord.com/developers/docs/resources/user#get-user-application-role-connection)
"""
function get_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/users/@me/applications/$(application_id)/role-connection"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    update_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict) -> Dict{String, Any}

Update the role connection metadata for the bot's account.

Use this when a bot needs to update Linked Role verification data, such as
for applications that provide role verification based on external platform data.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Authentication token (typically OAuth2 user token).
- `body::Dict` — Role connection metadata (platform_name, platform_username, metadata).

# Errors
- HTTP 400 if the metadata is invalid.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/user#update-user-application-role-connection)
"""
function update_current_user_application_role_connection(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_put(rl, "/users/@me/applications/$(application_id)/role-connection"; token, body)
    JSON3.read(resp.body, Dict{String, Any})
end
