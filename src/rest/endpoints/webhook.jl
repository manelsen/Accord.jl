# Webhook REST endpoints

function create_webhook(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/webhooks"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
    parse_response(Webhook, resp)
end

function get_channel_webhooks(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/webhooks"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Webhook, resp)
end

function get_guild_webhooks(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/webhooks"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Webhook, resp)
end

function get_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)"; token, major_params=["webhook_id" => string(webhook_id)])
    parse_response(Webhook, resp)
end

function get_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Webhook, resp)
end

function modify_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/webhooks/$(webhook_id)"; token, body, reason, major_params=["webhook_id" => string(webhook_id)])
    parse_response(Webhook, resp)
end

function delete_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/webhooks/$(webhook_id)"; token, reason, major_params=["webhook_id" => string(webhook_id)])
end

function execute_webhook(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String, body::Dict, files=nothing, wait::Bool=false, thread_id=nothing)
    query = []
    wait && push!(query, "wait" => "true")
    !isnothing(thread_id) && push!(query, "thread_id" => string(thread_id))
    resp = discord_post(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; token, body, files,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    wait ? parse_response(Message, resp) : resp
end

function get_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Message, resp)
end

function edit_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token, body, files,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Message, resp)
end

function delete_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String)
    discord_delete(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
end
