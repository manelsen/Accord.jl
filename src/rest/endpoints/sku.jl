# SKU, Entitlement, and Subscription REST endpoints

# --- SKUs ---
function list_skus(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/skus"; token)
    parse_response_array(SKU, resp)
end

# --- Entitlements ---
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

function create_test_entitlement(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/entitlements"; token, body)
    parse_response(Entitlement, resp)
end

function delete_test_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)"; token)
end

function consume_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    discord_post(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)/consume"; token)
end

function get_entitlement(rl::RateLimiter, application_id::Snowflake, entitlement_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/entitlements/$(entitlement_id)"; token)
    parse_response(Entitlement, resp)
end

# --- Subscriptions ---
function list_sku_subscriptions(rl::RateLimiter, sku_id::Snowflake; token::String, before=nothing, after=nothing, limit::Int=100, user_id=nothing)
    query = ["limit" => string(limit)]
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    !isnothing(user_id) && push!(query, "user_id" => string(user_id))
    resp = discord_get(rl, "/skus/$(sku_id)/subscriptions"; token, query)
    parse_response_array(Subscription, resp)
end

function get_sku_subscription(rl::RateLimiter, sku_id::Snowflake, subscription_id::Snowflake; token::String)
    resp = discord_get(rl, "/skus/$(sku_id)/subscriptions/$(subscription_id)"; token)
    parse_response(Subscription, resp)
end
