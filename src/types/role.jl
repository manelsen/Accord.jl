@discord_struct RoleTags begin
    bot_id::Optional{Snowflake}
    integration_id::Optional{Snowflake}
    premium_subscriber::Optional{Nothing}
    subscription_listing_id::Optional{Snowflake}
    available_for_purchase::Optional{Nothing}
    guild_connections::Optional{Nothing}
end

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
