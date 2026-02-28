"""
    Emoji

Represents a Discord emoji. This can be a standard Unicode emoji or a 
custom guild emoji.

# Fields
- `id::Nullable{Snowflake}`: Unique ID for custom emojis (null for Unicode).
- `name::Nullable{String}`: Name of the emoji (e.g., "thinking" or "Julia").
- `roles::Optional{Vector{Snowflake}}`: Roles allowed to use this emoji.
- `user::Optional{User}`: User that created this emoji.
- `require_colons::Optional{Bool}`: Whether the emoji requires colons (custom emojis).
- `managed::Optional{Bool}`: Whether the emoji is managed by an integration.
- `animated::Optional{Bool}`: Whether the emoji is animated.
- `available::Optional{Bool}`: Whether the emoji can be used.

# See Also
- [Discord API: Emoji Object](https://discord.com/developers/docs/resources/emoji#emoji-object)
"""
@discord_struct Emoji begin
    id::Nullable{Snowflake}
    name::Nullable{String}
    roles::Optional{Vector{Snowflake}}
    user::Optional{User}
    require_colons::Optional{Bool}
    managed::Optional{Bool}
    animated::Optional{Bool}
    available::Optional{Bool}
end
