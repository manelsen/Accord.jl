"""
    SKU

A Stock Keeping Unit (SKU) is a monetization offering that can be used to grant access to premium features.

[Discord docs](https://discord.com/developers/docs/resources/sku#sku-object)

# Fields
- `id::Snowflake` — ID of the SKU.
- `type::Int` — Type of the SKU. See [`SKUTypes`](@ref) module.
- `application_id::Snowflake` — ID of the parent application.
- `name::String` — Customer-facing name of your premium offering.
- `slug::String` — System-generated URL slug based on the SKU's name.
- `flags::Int` — SKU flags combined as a bitfield. See [`SKUFlags`](@ref) module.
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

An entitlement represents that a user or guild has access to a premium offering in your application.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#entitlement-object)

# Fields
- `id::Snowflake` — Unique ID of the entitlement.
- `sku_id::Snowflake` — ID of the SKU this entitlement grants access to.
- `application_id::Snowflake` — ID of the parent application.
- `user_id::Optional{Snowflake}` — ID of the user that is granted access to the entitlement's sku. Only for user subscriptions.
- `type::Int` — Type of entitlement. See [`EntitlementTypes`](@ref) module.
- `deleted::Bool` — Entitlement was deleted.
- `starts_at::Optional{String}` — ISO8601 timestamp for when the entitlement starts.
- `ends_at::Optional{String}` — ISO8601 timestamp for when the entitlement ends.
- `guild_id::Optional{Snowflake}` — ID of the guild that is granted access to the entitlement's sku. Only for guild subscriptions.
- `consumed::Optional{Bool}` — For consumable entitlements, whether or not it has been consumed.
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

A subscription represents a user's subscription to a SKU, including current period and status.

[Discord docs](https://discord.com/developers/docs/resources/subscription#subscription-object)

# Fields
- `id::Snowflake` — Unique ID of the subscription.
- `user_id::Snowflake` — ID of the user who is subscribed.
- `sku_ids::Vector{Snowflake}` — List of SKU IDs subscribed to.
- `entitlement_ids::Vector{Snowflake}` — List of entitlement IDs granted by this subscription.
- `current_period_start::String` — ISO8601 timestamp of when the current subscription period started.
- `current_period_end::String` — ISO8601 timestamp of when the current subscription period ends.
- `status::Int` — Status of the subscription. See `SubscriptionStatusTypes` (0 = active, 1 = ending, 2 = inactive).
- `canceled_at::Optional{String}` — ISO8601 timestamp of when the subscription was canceled, if applicable.
- `country::Optional{String}` — Country code of the payment source used for this subscription.
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
