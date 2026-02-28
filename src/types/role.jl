"""
    RoleTags

Extra attributes describing a special role (e.g., bot role, booster role).

# Fields
- `bot_id::Optional{Snowflake}`: The ID of the bot this role belongs to.
- `integration_id::Optional{Snowflake}`: The ID of the integration this role belongs to.
- `premium_subscriber::Optional{Nothing}`: Present if this is the guild's booster role.
- `subscription_listing_id::Optional{Snowflake}`: ID of the role's subscription SKU.
- `available_for_purchase::Optional{Nothing}`: Present if the role is available for purchase.
- `guild_connections::Optional{Nothing}`: Present if the role is a guild's linked role.

# See Also
- [Discord API: Role Tags Object](https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure)
"""
@discord_struct RoleTags begin
    bot_id::Optional{Snowflake}
    integration_id::Optional{Snowflake}
    premium_subscriber::Optional{Nothing}
    subscription_listing_id::Optional{Snowflake}
    available_for_purchase::Optional{Nothing}
    guild_connections::Optional{Nothing}
end

"""
    Role

Represents a Discord guild role. Roles are used to grant permissions to users
and group them in the member list.

# Fields
- `id::Snowflake`: The unique ID of the role.
- `name::String`: The name of the role (e.g., "@everyone", "Moderator").
- `color::Int`: The integer representation of the hex color code.
- `hoist::Bool`: Whether the role is pinned (hoisted) in the user listing.
- `icon::Optional{String}`: The role's icon hash.
- `unicode_emoji::Optional{String}`: The role's unicode emoji.
- `position::Int`: Position of this role in the hierarchy (higher is higher).
- `permissions::String`: Permission bitfield as a string.
- `managed::Bool`: Whether the role is managed by an integration (bot, etc.).
- `mentionable::Bool`: Whether the role can be mentioned by anyone.
- `tags::Optional{RoleTags}`: Special tags for this role.
- `flags::Int`: Role flags (see [`RoleFlags`](@ref)).

# Example
```julia
roles = guild.roles
mod_role = findfirst(r -> r.name == "Moderator", roles)
println("Moderator role ID: \$(mod_role.id)")
```

# See Also
- [Discord API: Role Object](https://discord.com/developers/docs/resources/guild#role-object)
"""
@discord_struct Role begin
    id::Snowflake
    name::String
    color::Int
    hoist::Bool
    icon::Optional{String}
    unicode_emoji::Optional{String}
    position::Int
    permissions::String
    managed::Bool
    mentionable::Bool
    tags::Optional{RoleTags}
    flags::Int
end
