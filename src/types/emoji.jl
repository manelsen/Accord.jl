"""
    Emoji

Represents an emoji, which can be a standard Unicode emoji or a custom guild emoji.

[Discord docs](https://discord.com/developers/docs/resources/emoji#emoji-object)

# Fields
- `id::Nullable{Snowflake}` — emoji ID. `nothing` for standard Unicode emojis.
- `name::Nullable{String}` — emoji name. For custom emojis, this is the custom name. For standard emojis, this may be `nothing` in reaction objects.
- `roles::Optional{Vector{Snowflake}}` — roles allowed to use this emoji. Only for custom guild emojis.
- `user::Optional{User}` — user that created this emoji. Only for custom guild emojis.
- `require_colons::Optional{Bool}` — whether this emoji must be wrapped in colons. Only for custom guild emojis.
- `managed::Optional{Bool}` — whether this emoji is managed by an integration. Only for custom guild emojis.
- `animated::Optional{Bool}` — whether this emoji is animated. Only for custom guild emojis.
- `available::Optional{Bool}` — whether this emoji can be used. May be `false` due to loss of Server Boosts. Only for custom guild emojis.
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
