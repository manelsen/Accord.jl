@discord_struct SKU begin
    id::Snowflake
    type::Int
    application_id::Snowflake
    name::String
    slug::String
    flags::Int
end

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
