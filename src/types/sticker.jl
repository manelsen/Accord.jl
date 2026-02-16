"""
    StickerItem

The smallest amount of data required to render a sticker. A partial representation of a larger sticker object.

[Discord docs](https://discord.com/developers/docs/resources/sticker#sticker-item-object)

# Fields
- `id::Snowflake` — ID of the sticker.
- `name::String` — Name of the sticker.
- `format_type::Int` — Type of sticker format. See [`StickerFormatTypes`](@ref) module.
"""
@discord_struct StickerItem begin
    id::Snowflake
    name::String
    format_type::Int
end

"""
    Sticker

Represents a sticker that can be sent in messages.

[Discord docs](https://discord.com/developers/docs/resources/sticker#sticker-object)

# Fields
- `id::Snowflake` — ID of the sticker.
- `pack_id::Optional{Snowflake}` — For standard stickers, ID of the pack the sticker is from.
- `name::String` — Name of the sticker (2-30 characters).
- `description::Nullable{String}` — Description of the sticker (empty string for guild stickers, may be `nothing` for standard stickers).
- `tags::String` — Autocomplete/suggestion tags for the sticker (max 200 characters). For guild stickers, this is the emoji associated with the sticker.
- `type::Int` — Type of sticker. See [`StickerTypes`](@ref) module.
- `format_type::Int` — Type of sticker format. See [`StickerFormatTypes`](@ref) module.
- `available::Optional{Bool}` — Whether this guild sticker can be used, may be false due to loss of Server Boosts.
- `guild_id::Optional{Snowflake}` — ID of the guild that owns this sticker. Only for guild stickers.
- `user::Optional{User}` — User that uploaded this sticker. Only for guild stickers.
- `sort_value::Optional{Int}` — Standard sticker's sort order within its pack. Only for standard stickers.
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

Represents a pack of standard stickers.

[Discord docs](https://discord.com/developers/docs/resources/sticker#sticker-pack-object)

# Fields
- `id::Snowflake` — ID of the sticker pack.
- `stickers::Vector{Sticker}` — Stickers in the pack.
- `name::String` — Name of the sticker pack.
- `sku_id::Snowflake` — ID of the pack's SKU.
- `cover_sticker_id::Optional{Snowflake}` — ID of a sticker in the pack which is shown as the pack's icon.
- `description::String` — Description of the sticker pack.
- `banner_asset_id::Optional{Snowflake}` — ID of the sticker pack's banner image.
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
