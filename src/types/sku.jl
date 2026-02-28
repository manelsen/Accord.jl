"""
    SKU

Represents a Stock Keeping Unit (SKU) for application monetization.

# See Also
- [Discord API: SKU Object](https://discord.com/developers/docs/resources/sku#sku-object)
"""
@discord_struct SKU begin
    id::Snowflake
    type::Int
    application_id::Snowflake
    name::String
    slug::String
    flags::Int
end

"""
    Entitlement

Represents access to a premium offering (SKU) by a user or guild.

# See Also
- [Discord API: Entitlement Object](https://discord.com/developers/docs/resources/entitlement#entitlement-object)
"""
@discord_struct Entitlement begin
    id::Snowflake
    sku_id::Snowflake
    application_id::Snowflake
    user_id::Optional{Snowflake}
    type::Int
    deleted::Bool
    starts_at::Optional{String}
    ends_at::Optional{String}
    guild_id::Optional{Snowflake}
    consumed::Optional{Bool}
end

"""
    Subscription

Represents a user's subscription to a premium SKU.

# See Also
- [Discord API: Subscription Object](https://discord.com/developers/docs/resources/subscription#subscription-object)
"""
@discord_struct Subscription begin
    id::Snowflake
    user_id::Snowflake
    sku_ids::Vector{Snowflake}
    entitlement_ids::Vector{Snowflake}
    current_period_start::String
    current_period_end::String
    status::Int
    canceled_at::Optional{String}
    country::Optional{String}
end
