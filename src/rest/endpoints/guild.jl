# Guild REST endpoints

"""
    get_guild(rl::RateLimiter, guild_id::Snowflake; token::String, with_counts::Bool=false) -> Guild

Retrieve a guild by its ID.

Use this when a bot needs to fetch guild information, such as guild settings,
features, or member counts.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild to retrieve.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_counts::Bool` — Include approximate member and presence counts.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild)
"""
function get_guild(rl::RateLimiter, guild_id::Snowflake; token::String, with_counts::Bool=false)
    resp = discord_get(rl, "/guilds/$(guild_id)"; token, query=with_counts ? ["with_counts" => "true"] : nothing,
        major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

"""
    get_guild_preview(rl::RateLimiter, guild_id::Snowflake; token::String) -> Guild

Get a guild preview object for a public guild.

Use this when a bot needs to display information about a public guild
before the user joins, such as for guild discovery features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the public guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the guild is not public or does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-preview)
"""
function get_guild_preview(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/preview"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

"""
    modify_guild(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Guild

Modify a guild's settings.

Use this when a bot needs to update guild configuration such as name, icon,
verification level, default notifications, or explicit content filter.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Guild fields to update.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild)
"""
function modify_guild(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

"""
    delete_guild(rl::RateLimiter, guild_id::Snowflake; token::String)

Delete a guild permanently.

Use this when a bot needs to delete a guild it owns. This action is irreversible.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
The bot must be the owner of the guild.

# Errors
- HTTP 403 if the bot is not the guild owner.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#delete-guild)
"""
function delete_guild(rl::RateLimiter, guild_id::Snowflake; token::String)
    discord_delete(rl, "/guilds/$(guild_id)"; token, major_params=["guild_id" => string(guild_id)])
end

"""
    get_guild_channels(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{DiscordChannel}

Get all channels in a guild.

Use this when a bot needs to list all channels in a guild, such as for
channel management commands or initialization.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `VIEW_CHANNEL` for channels the bot can see.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-channels)
"""
function get_guild_channels(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/channels"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(DiscordChannel, resp)
end

"""
    create_guild_channel(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> DiscordChannel

Create a new channel in a guild.

Use this when a bot needs to create channels programmatically, such as for
temporary channels, ticket systems, or dynamic channel creation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Channel settings (name, type, parent, permission overwrites, etc.).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_CHANNELS`.

# Errors
- HTTP 403 if missing required permissions or channel limit reached.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#create-guild-channel)
"""
function create_guild_channel(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/channels"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(DiscordChannel, resp)
end

"""
    modify_guild_channel_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector)

Modify the positions of channels in a guild.

Use this when a bot needs to reorder channels, such as for automatic
category organization or dynamic channel sorting.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Vector` — Array of channel position updates (id, position, lock_permissions).

# Permissions
Requires `MANAGE_CHANNELS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions)
"""
function modify_guild_channel_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector)
    discord_patch(rl, "/guilds/$(guild_id)/channels"; token, body=body, major_params=["guild_id" => string(guild_id)])
end

"""
    list_active_guild_threads(rl::RateLimiter, guild_id::Snowflake; token::String) -> Dict{String, Any}

Get all active threads in a guild.

Use this when a bot needs to list active threads for thread management,
moderation, or archival purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#list-active-guild-threads)
"""
function list_active_guild_threads(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/threads/active"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String) -> Member

Get a guild member by user ID.

Use this when a bot needs to fetch specific member information such as
roles, nickname, join date, or permissions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the user.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the member or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-member)
"""
function get_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

"""
    list_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1, after::Optional{Snowflake}=missing) -> Vector{Member}

List members in a guild.

Use this when a bot needs to retrieve guild members for member listing,
searching, or batch processing operations.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum members to return (1-1000, default 1).
- `after::Snowflake` — Get members after this user ID (for pagination).

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#list-guild-members)
"""
function list_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1, after::Optional{Snowflake}=missing)
    query = ["limit" => string(limit)]
    !ismissing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/guilds/$(guild_id)/members"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Member, resp)
end

"""
    search_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, query_str::String, limit::Int=1) -> Vector{Member}

Search for guild members by username or nickname.

Use this when a bot needs to find specific members by name, such as for
user lookup commands or autocomplete functionality.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `query_str::String` — Query string to match against username/nickname.
- `limit::Int` — Maximum members to return (1-1000, default 1).

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#search-guild-members)
"""
function search_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, query_str::String, limit::Int=1)
    resp = discord_get(rl, "/guilds/$(guild_id)/members/search"; token,
        query=["query" => query_str, "limit" => string(limit)],
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(Member, resp)
end

"""
    modify_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict, reason=nothing) -> Member

Modify attributes of a guild member.

Use this when a bot needs to change a member's roles, nickname, timeout,
or voice channel status.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the member to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Member fields to update (nick, roles, mute, deaf, etc.).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
- `MANAGE_NICKNAMES` for changing nicknames.
- `MANAGE_ROLES` for managing roles.
- `MODERATE_MEMBERS` for timeouts.
- `MOVE_MEMBERS` for moving between voice channels.

# Errors
- HTTP 403 if missing required permissions or role hierarchy violation.
- HTTP 404 if the member or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-member)
"""
function modify_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

"""
    modify_current_member(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Member

Modify the current bot member's attributes.

Use this when a bot needs to change its own nickname in a guild.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Member fields to update (currently only `nick` is supported).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `CHANGE_NICKNAME` or `MANAGE_NICKNAMES`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-current-member)
"""
function modify_current_member(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/members/@me"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

"""
    add_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)

Add a role to a guild member.

Use this when a bot needs to assign roles to users, such as for reaction
roles, leveling systems, or automated moderation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the member.
- `role_id::Snowflake` — The ID of the role to add.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_ROLES` with the bot's top role higher than the target role.

# Errors
- HTTP 403 if missing required permissions or role hierarchy violation.
- HTTP 404 if the member, role, or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#add-guild-member-role)
"""
function add_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_put(rl, "/guilds/$(guild_id)/members/$(user_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    remove_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)

Remove a role from a guild member.

Use this when a bot needs to remove roles from users, such as for temporary
role assignments, reaction roles, or demotion systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the member.
- `role_id::Snowflake` — The ID of the role to remove.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_ROLES` with the bot's top role higher than the target role.

# Errors
- HTTP 403 if missing required permissions or role hierarchy violation.
- HTTP 404 if the member, role, or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#remove-guild-member-role)
"""
function remove_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/members/$(user_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    remove_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)

Remove a member from a guild (kick).

Use this when a bot needs to kick users from the guild, such as for
moderation commands or automated removal systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the member to remove.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the removal (optional).

# Permissions
Requires `KICK_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the member or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#remove-guild-member)
"""
function remove_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    get_guild_bans(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1000) -> Vector{Ban}

Get all bans in a guild.

Use this when a bot needs to list banned users, such as for ban management
commands or displaying ban lists to moderators.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum bans to return (default 1000).

# Permissions
Requires `BAN_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-bans)
"""
function get_guild_bans(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1000)
    resp = discord_get(rl, "/guilds/$(guild_id)/bans"; token, query=["limit" => string(limit)],
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(Ban, resp)
end

"""
    get_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String) -> Ban

Get a specific ban for a user.

Use this when a bot needs to check if a user is banned and see their ban
reason, such as before attempting to unban or for ban information commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the user to check.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `BAN_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the user is not banned or the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-ban)
"""
function get_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Ban, resp)
end

"""
    create_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)

Ban a user from a guild.

Use this when a bot needs to ban users, such as for moderation commands
or automated ban systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the user to ban.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Ban options (delete_message_days, delete_message_seconds).
- `reason::String` — Audit log reason for the ban (optional).

# Permissions
Requires `BAN_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions or if the bot cannot ban the target.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#create-guild-ban)
"""
function create_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    discord_put(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    remove_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)

Unban a user from a guild.

Use this when a bot needs to remove bans, such as for unban commands,
temporary bans, or ban appeal systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the user to unban.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the unban (optional).

# Permissions
Requires `BAN_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the user is not banned or the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#remove-guild-ban)
"""
function remove_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    bulk_guild_ban(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Dict{String, Any}

Ban up to 200 users from a guild.

Use this when a bot needs to ban multiple users at once, such as for raid
protection or mass moderation actions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Contains `user_ids` array and optional `delete_message_seconds`.
- `reason::String` — Audit log reason for the bans (optional).

# Permissions
Requires `BAN_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#bulk-guild-ban)
"""
function bulk_guild_ban(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/bulk-ban"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_roles(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Role}

Get all roles in a guild.

Use this when a bot needs to list guild roles, such as for role management
commands or permission checking.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-roles)
"""
function get_guild_roles(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/roles"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Role, resp)
end

"""
    create_guild_role(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing) -> Role

Create a new role in a guild.

Use this when a bot needs to create roles programmatically, such as for
reaction roles, self-assignable roles, or temporary role systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Role settings (name, permissions, color, hoist, mentionable, etc.).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_ROLES`.

# Errors
- HTTP 403 if missing required permissions or role limit reached.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#create-guild-role)
"""
function create_guild_role(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/roles"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

"""
    modify_guild_role_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector, reason=nothing) -> Vector{Role}

Modify the positions of roles in a guild.

Use this when a bot needs to reorder roles, such as for role hierarchy
management or sorting by activity/level.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Vector` — Array of role position updates (id, position).
- `reason::String` — Audit log reason for the changes (optional).

# Permissions
Requires `MANAGE_ROLES`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-role-positions)
"""
function modify_guild_role_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/roles"; token, body=body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Role, resp)
end

"""
    modify_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, body::Dict, reason=nothing) -> Role

Modify a guild role.

Use this when a bot needs to update role properties such as name, color,
permissions, or mentionability.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `role_id::Snowflake` — The ID of the role to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Role fields to update.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_ROLES` and the bot's top role must be higher than the target role.

# Errors
- HTTP 403 if missing required permissions or role hierarchy violation.
- HTTP 404 if the role or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-role)
"""
function modify_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

"""
    delete_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)

Delete a guild role.

Use this when a bot needs to remove roles, such as for cleanup of temporary
roles or automated role removal.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `role_id::Snowflake` — The ID of the role to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_ROLES` and the bot's top role must be higher than the target role.

# Errors
- HTTP 403 if missing required permissions or role hierarchy violation.
- HTTP 404 if the role or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#delete-guild-role)
"""
function delete_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    get_guild_prune_count(rl::RateLimiter, guild_id::Snowflake; token::String, days::Int=7, include_roles::String="") -> Dict{String, Any}

Get the number of members that would be pruned.

Use this when a bot needs to preview the results of a prune operation
without actually removing members.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `days::Int` — Number of days of inactivity to count (1-30, default 7).
- `include_roles` — Comma-separated list of role IDs to include.

# Permissions
Requires `KICK_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-prune-count)
"""
function get_guild_prune_count(rl::RateLimiter, guild_id::Snowflake; token::String, days::Int=7, include_roles::String="")
    query = ["days" => string(days)]
    !isempty(include_roles) && push!(query, "include_roles" => include_roles)
    resp = discord_get(rl, "/guilds/$(guild_id)/prune"; token, query, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    begin_guild_prune(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Dict{String, Any}

Prune inactive members from a guild.

Use this when a bot needs to remove members who haven't been active for
a specified number of days.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Prune options (days, compute_prune_count, include_roles, etc.).
- `reason::String` — Audit log reason for the prune (optional).

# Permissions
Requires `KICK_MEMBERS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#begin-guild-prune)
"""
function begin_guild_prune(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/prune"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_voice_regions(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{VoiceRegion}

Get available voice regions for a guild.

Use this when a bot needs to list voice regions available to the guild,
which may differ from the global list due to VIP server status.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-voice-regions)
"""
function get_guild_voice_regions(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/regions"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(VoiceRegion, resp)
end

"""
    get_guild_invites(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Invite}

Get all invites in a guild.

Use this when a bot needs to list active invites for moderation, analytics,
or invite management purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-invites)
"""
function get_guild_invites(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/invites"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Invite, resp)
end

"""
    get_guild_integrations(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Integration}

Get all integrations for a guild.

Use this when a bot needs to list connected integrations such as Twitch,
YouTube, or other third-party services.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-integrations)
"""
function get_guild_integrations(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/integrations"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Integration, resp)
end

"""
    delete_guild_integration(rl::RateLimiter, guild_id::Snowflake, integration_id::Snowflake; token::String, reason=nothing)

Delete an integration from a guild.

Use this when a bot needs to remove third-party integrations from the guild.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `integration_id::Snowflake` — The ID of the integration to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the integration or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#delete-guild-integration)
"""
function delete_guild_integration(rl::RateLimiter, guild_id::Snowflake, integration_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/integrations/$(integration_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

"""
    get_guild_widget_settings(rl::RateLimiter, guild_id::Snowflake; token::String) -> Dict{String, Any}

Get the guild widget settings.

Use this when a bot needs to check the widget configuration, such as
whether the widget is enabled and which channel it displays.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-widget-settings)
"""
function get_guild_widget_settings(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/widget"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    modify_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Dict{String, Any}

Modify the guild widget settings.

Use this when a bot needs to enable/disable the widget or change the
widget channel.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Widget settings (enabled, channel_id).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-widget)
"""
function modify_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/widget"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String) -> Dict{String, Any}

Get the guild widget JSON data.

Use this when a bot needs to retrieve public widget data for the guild,
which can be used to display online members and invite links.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the guild widget is disabled or the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-widget)
"""
function get_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/widget.json"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    get_guild_vanity_url(rl::RateLimiter, guild_id::Snowflake; token::String) -> Invite

Get the vanity URL for a guild.

Use this when a bot needs to retrieve or display a guild's custom invite URL.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild has no vanity URL.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-vanity-url)
"""
function get_guild_vanity_url(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/vanity-url"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Invite, resp)
end

"""
    get_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String) -> WelcomeScreen

Get the welcome screen for a guild.

Use this when a bot needs to display or cache the guild's welcome screen,
which shows description and recommended channels for new members.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the guild has no welcome screen enabled.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen)
"""
function get_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/welcome-screen"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(WelcomeScreen, resp)
end

"""
    modify_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> WelcomeScreen

Modify the welcome screen for a guild.

Use this when a bot needs to update the guild's welcome screen, such as
changing the description or recommended channels.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Welcome screen settings (enabled, description, welcome_channels).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen)
"""
function modify_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/welcome-screen"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(WelcomeScreen, resp)
end

"""
    get_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String) -> Onboarding

Get the onboarding configuration for a guild.

Use this when a bot needs to retrieve the guild's onboarding prompts and
settings for new member guidance.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-onboarding)
"""
function get_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/onboarding"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Onboarding, resp)
end

"""
    modify_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> Onboarding

Modify the onboarding configuration for a guild.

Use this when a bot needs to update the guild's onboarding prompts,
default channels, or other new member guidance settings.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Onboarding configuration (prompts, default_channel_ids, etc.).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#modify-guild-onboarding)
"""
function modify_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_put(rl, "/guilds/$(guild_id)/onboarding"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Onboarding, resp)
end

"""
    get_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String) -> Role

Get a specific role by ID.

Use this when a bot needs to retrieve detailed information about a single
role, such as for role management or permission checking.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `role_id::Snowflake` — The ID of the role.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the role or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#get-guild-role)
"""
function get_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

"""
    add_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict) -> Member

Add a user to a guild using an OAuth2 access token.

Use this when a bot needs to add users to guilds through OAuth2 authorization,
such as for guild join systems or membership management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `user_id::Snowflake` — The ID of the user to add.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Must contain `access_token` and optionally `nick` and `roles`.

# Permissions
Requires `CREATE_INSTANT_INVITE`.

# Errors
- HTTP 403 if missing required permissions or the user is already in the guild.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild#add-guild-member)
"""
function add_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict)
    resp = discord_put(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, body, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end
