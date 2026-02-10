@discord_struct StickerItem begin
    id::Snowflake
    name::String
    format_type::Int
end

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

@discord_struct StickerPack begin
    id::Snowflake
    stickers::Vector{Sticker}
    name::String
    sku_id::Snowflake
    cover_sticker_id::Optional{Snowflake}
    description::String
    banner_asset_id::Optional{Snowflake}
end
