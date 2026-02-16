# SKU, Entitlement, and Subscription REST endpoints

# --- SKUs ---

"""
    list_skus(rl::RateLimiter, application_id::Snowflake; token::String) -> Vector{SKU}

Get all SKUs (Stock Keeping Units) for an application.

Use this when a bot needs to list available premium products or subscription
plans offered by the application, such as for store displays or upgrade flows.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.

# SKU Types
- `2` (DURABLE) — One-time purchase
- `3` (CONSUMABLE) — Consumable purchase
- `5` (SUBSCRIPTION) — Subscription
- `6` (SUBSCRIPTION_GROUP) — Subscription group

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the application does not exist.

[Discord docs](https://discord.com/developers/docs/resources/sku#list-skus)
"""
function list_skus(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/skus"; token)
    parse_response_array(SKU, resp)
end

# --- Entitlements ---

"""
    list_entitlements(rl::RateLimiter, application_id::Snowflake; token::String,
        user_id=nothing, sku_ids=nothing, before=nothing, after=nothing, limit::Int=100,
        guild_id=nothing, exclude_ended::Bool=false, exclude_deleted::Bool=true) -> Vector{Entitlement}

Get all entitlements for an application.

Use this when a bot needs to list user purchases and subscriptions, such as
for checking premium status, managing subscriptions, or customer support.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `user_id::Snowflake` — Filter by user ID.
- `sku_ids::Vector{Snowflake}` — Filter by specific SKU IDs.
- `before::Snowflake` — Get entitlements before this ID.
- `after::Snowflake` — Get entitlements after this ID.
- `limit::Int` — Maximum entitlements to return (1-100, default 100).
- `guild_id::Snowflake` — Filter by guild ID.
- `exclude_ended::Bool` — Exclude ended entitlements.
- `exclude_deleted::Bool` — Exclude deleted entitlements.

# Entitlement Types
- `1` — Application subscription
- `2` — Application entitlement
- `3` — Application gift

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#list-entitlements)
"""
function list_entitlements(rl::RateLimiter, application_id::Snowflake; token::String,
        user_id=nothing, sku_ids=nothing, before=nothing, after=nothing, limit::Int=100,
        guild_id=nothing, exclude_ended::Bool=false, exclude_deleted::Bool=true)
    query = ["limit" => string(limit)]
    !isnothing(user_id) && push!(query, "user_id" => string(user_id))
    !isnothing(sku_ids) && push!(query, "sku_ids" => join(string.(sku_ids), ","))
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    !isnothing(guild_id) && push!(query, "guild_id" => string(guild_id))
    exclude_ended && push!(query, "exclude_ended" => "true")
    !exclude_deleted && push!(query, "exclude_deleted" => "false")
    resp = discord_get(rl, "/applications/$(application_id)/entitlements"; token, query)
    parse_response_array(Entitlement, resp)
end

"""
    create_test_entitlement(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict) -> Entitlement

Create a test entitlement for development purposes.

Use this when developing premium features and testing entitlement checking
without making actual purchases. Only works in development mode.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Test entitlement data (sku_id, user_id, guild_id, etc.).

# Note
Test entitlements are only available in development mode and do not appear
in production or billing systems.

# Errors
- HTTP 400 if the request data is invalid.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#create-test-entitlement)
"""
function create_test_entitlement(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/entitlements"; token, body)
    parse_response(Entitlement, resp)
end

"""
    delete_test_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)

Delete a test entitlement.

Use this when cleaning up test data or resetting test scenarios during
development.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `entitlement_id::Snowflake` — The ID of the test entitlement.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the entitlement does not exist.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#delete-test-entitlement)
"""
function delete_test_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)"; token)
end

"""
    consume_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)

Consume an entitlement.

Use this when a bot needs to mark an entitlement as consumed, such as for
consumable purchases or one-time use premium features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `entitlement_id::Snowflake` — The ID of the entitlement to consume.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the entitlement does not exist.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#consume-entitlement)
"""
function consume_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    discord_post(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)/consume"; token)
end

"""
    get_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String) -> Entitlement

Get a specific entitlement.

Use this when a bot needs to retrieve details about a single entitlement,
such as for verification or customer support purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `entitlement_id::Snowflake` — The ID of the entitlement.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the entitlement does not exist.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#get-entitlement)
"""
function get_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)"; token)
    parse_response(Entitlement, resp)
end

# --- Subscriptions ---

"""
    list_sku_subscriptions(rl::RateLimiter, sku_id::Snowflake; token::String, before=nothing, after=nothing, limit::Int=100, user_id=nothing) -> Vector{Subscription}

Get all subscriptions for a specific SKU.

Use this when a bot needs to list active subscriptions for a product, such
as for billing management, subscriber analytics, or customer support.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `sku_id::Snowflake` — The ID of the SKU.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `before::Snowflake` — Get subscriptions before this ID.
- `after::Snowflake` — Get subscriptions after this ID.
- `limit::Int` — Maximum subscriptions to return (1-100, default 100).
- `user_id::Snowflake` — Filter by user ID.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the SKU does not exist.

[Discord docs](https://discord.com/developers/docs/resources/subscription#list-sku-subscriptions)
"""
function list_sku_subscriptions(rl::RateLimiter, sku_id::Snowflake; token::String, before=nothing, after=nothing, limit::Int=100, user_id=nothing)
    query = ["limit" => string(limit)]
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    !isnothing(user_id) && push!(query, "user_id" => string(user_id))
    resp = discord_get(rl, "/skus/$(sku_id)/subscriptions"; token, query)
    parse_response_array(Subscription, resp)
end

"""
    get_sku_subscription(rl::RateLimiter, sku_id::Snowflake, subscription_id::Snowflake; token::String) -> Subscription

Get a specific subscription.

Use this when a bot needs to retrieve details about a single subscription,
such as for billing verification or subscription status checks.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `sku_id::Snowflake` — The ID of the SKU.
- `subscription_id::Snowflake` — The ID of the subscription.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the subscription or SKU does not exist.

[Discord docs](https://discord.com/developers/docs/resources/subscription#get-sku-subscription)
"""
function get_sku_subscription(rl::RateLimiter, sku_id::Snowflake, subscription_id::Snowflake; token::String)
    resp = discord_get(rl, "/skus/$(sku_id)/subscriptions/$(subscription_id)"; token)
    parse_response(Subscription, resp)
end
