"""
    RoleTags

Tags describing extra attributes of a role.

[Discord docs](https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure)

# Fields
- `bot_id::Optional{Snowflake}` — ID of the bot this role belongs to.
- `integration_id::Optional{Snowflake}` — ID of the integration this role belongs to.
- `premium_subscriber::Optional{Nothing}` — whether this is the guild's booster role. Present as `nothing` if true; absent otherwise.
- `subscription_listing_id::Optional{Snowflake}` — ID of this role's subscription sku and listing.
- `available_for_purchase::Optional{Nothing}` — whether this role is available for purchase. Present as `nothing` if true; absent otherwise.
- `guild_connections::Optional{Nothing}` — whether this role is a guild's linked role. Present as `nothing` if true; absent otherwise.
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

A role in a guild. Roles are used to group users and grant them permissions. Every guild member has at least the `@everyone` role.

[Discord docs](https://discord.com/developers/docs/topics/permissions#role-object)

# Fields
- `id::Snowflake` — unique role ID.
- `name::String` — role name. For the `@everyone` role, this is the guild name.
- `color::Int` — integer representation of hexadecimal color code.
- `hoist::Bool` — whether the role is pinned in the user listing.
- `icon::Optional{String}` — role icon hash. Only present if the role has an icon.
- `unicode_emoji::Optional{String}` — role unicode emoji. Only present if the role has a unicode emoji.
- `position::Int` — position of this role in the role list. Higher values appear first.
- `permissions::String` — permission bit set as a string. See `Permissions` bitfield type.
- `managed::Bool` — whether this role is managed by an integration.
- `mentionable::Bool` — whether this role is mentionable.
- `tags::Optional{RoleTags}` — tags describing extra attributes of the role. Only present for special roles like boosters or bot roles.
- `flags::Int` — role flags combined as a bitfield.
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
