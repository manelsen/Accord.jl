"""
    StickerItem

A partial representation of a [`Sticker`](@ref), used for rendering.

# See Also
- [Discord API: Sticker Item Object](https://discord.com/developers/docs/resources/sticker#sticker-item-object)
"""
@discord_struct StickerItem begin
    id::Snowflake
    name::String
    format_type::Int
end

"""
    Sticker

Represents a sticker that can be sent in messages.

# Fields
- `id::Snowflake`: Unique ID of the sticker.
- `pack_id::Optional{Snowflake}`: ID of the pack (for standard stickers).
- `name::String`: Name of the sticker.
- `description::Nullable{String}`: Description of the sticker.
- `tags::String`: Autocomplete tags or associated emoji.
- `type::Int`: Sticker type (see [`StickerTypes`](@ref)).
- `format_type::Int`: Format type (see [`StickerFormatTypes`](@ref)).
- `available::Optional{Bool}`: Whether the sticker can be used.
- `guild_id::Optional{Snowflake}`: ID of the guild that owns the sticker.
- `user::Optional{User}`: The user who uploaded the sticker.
- `sort_value::Optional{Int}`: Sort order within a pack.

# See Also
- [Discord API: Sticker Object](https://discord.com/developers/docs/resources/sticker#sticker-object)
"""
@discord_struct Sticker begin
    id::Snowflake
    pack_id::Optional{Snowflake}
    name::String
    description::Nullable{String}
    tags::String
    type::Int
    format_type::Int
    available::Optional{Bool}
    guild_id::Optional{Snowflake}
    user::Optional{User}
    sort_value::Optional{Int}
end

"""
    StickerPack

Represents a collection of standard Discord stickers.

# See Also
- [Discord API: Sticker Pack Object](https://discord.com/developers/docs/resources/sticker#sticker-pack-object)
"""
@discord_struct StickerPack begin
    id::Snowflake
    stickers::Vector{Sticker}
    name::String
    sku_id::Snowflake
    cover_sticker_id::Optional{Snowflake}
    description::String
    banner_asset_id::Optional{Snowflake}
end
