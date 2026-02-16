# Webhook REST endpoints

"""
    create_webhook(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing) -> Webhook

Create a new webhook in a channel.

Use this when a bot needs to create webhooks for external message posting,
such as for GitHub notifications, RSS feeds, or third-party integrations.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel where the webhook will be created.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Webhook settings (name, avatar).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_WEBHOOKS`.

# Errors
- HTTP 400 if the webhook name is invalid or too long (max 80 characters).
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#create-webhook)
"""
function create_webhook(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/webhooks"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
    parse_response(Webhook, resp)
end

"""
    get_channel_webhooks(rl::RateLimiter, channel_id::Snowflake; token::String) -> Vector{Webhook}

Get all webhooks in a channel.

Use this when a bot needs to list webhooks for management, such as for
webhook configuration commands or cleanup utilities.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_WEBHOOKS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#get-channel-webhooks)
"""
function get_channel_webhooks(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/webhooks"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Webhook, resp)
end

"""
    get_guild_webhooks(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{Webhook}

Get all webhooks in a guild.

Use this when a bot needs to list all webhooks across a guild, such as for
audit or bulk webhook management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_WEBHOOKS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#get-guild-webhooks)
"""
function get_guild_webhooks(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/webhooks"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Webhook, resp)
end

"""
    get_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String) -> Webhook

Get a webhook by ID.

Use this when a bot needs to retrieve webhook details, such as for
configuration checking or validation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_WEBHOOKS` in the webhook's channel.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#get-webhook)
"""
function get_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)"; token, major_params=["webhook_id" => string(webhook_id)])
    parse_response(Webhook, resp)
end

"""
    get_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String) -> Webhook

Get a webhook using its token.

Use this when external services need to fetch webhook information using only
the webhook URL components (ID and token), without needing bot authentication.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.

# Keyword Arguments
- `token::String` — Bot authentication token (for additional validation).

# Errors
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#get-webhook-with-token)
"""
function get_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Webhook, resp)
end

"""
    modify_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, body::Dict, reason=nothing) -> Webhook

Modify a webhook.

Use this when a bot needs to update webhook settings such as name, avatar,
or channel location.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated webhook fields (name, avatar, channel_id).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_WEBHOOKS` in the webhook's channel.

# Errors
- HTTP 400 if the webhook name is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#modify-webhook)
"""
function modify_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/webhooks/$(webhook_id)"; token, body, reason, major_params=["webhook_id" => string(webhook_id)])
    parse_response(Webhook, resp)
end

"""
    delete_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, reason=nothing)

Delete a webhook permanently.

Use this when a bot needs to remove webhooks, such as for cleanup of
unused webhooks or webhook management commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_WEBHOOKS` in the webhook's channel.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#delete-webhook)
"""
function delete_webhook(rl::RateLimiter, webhook_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/webhooks/$(webhook_id)"; token, reason, major_params=["webhook_id" => string(webhook_id)])
end

"""
    execute_webhook(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String, body::Dict, files=nothing, wait::Bool=false, thread_id=nothing) -> Union{Message, Response}

Execute a webhook to send a message.

Use this when a bot or external service needs to post messages via webhook,
such as for cross-platform notifications or automated announcements.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Message content (content, embeds, components, etc.).
- `files` — File attachments (optional).
- `wait::Bool` — Wait for server confirmation and return the created message.
- `thread_id` — Send to a specific forum thread or channel thread.

# Errors
- HTTP 400 if the message data is invalid.
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the webhook does not exist.
- HTTP 429 if rate limited (webhooks have their own rate limits).

[Discord docs](https://discord.com/developers/docs/resources/webhook#execute-webhook)
"""
function execute_webhook(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; token::String, body::Dict, files=nothing, wait::Bool=false, thread_id=nothing)
    query = []
    wait && push!(query, "wait" => "true")
    !isnothing(thread_id) && push!(query, "thread_id" => string(thread_id))
    resp = discord_post(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; token, body, files,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    wait ? parse_response(Message, resp) : resp
end

"""
    get_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String) -> Message

Get a message sent by a webhook.

Use this when a bot needs to retrieve a message that was previously sent
via webhook, such as for editing or reference.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.
- `message_id::Snowflake` — The ID of the message.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the message or webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#get-webhook-message)
"""
function get_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Message, resp)
end

"""
    edit_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing) -> Message

Edit a message sent by a webhook.

Use this when a bot or external service needs to update a previously sent
webhook message, such as to correct information or show progress.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.
- `message_id::Snowflake` — The ID of the message to edit.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated message content.
- `files` — New file attachments (optional).

# Errors
- HTTP 400 if the message data is invalid.
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the message or webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#edit-webhook-message)
"""
function edit_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token, body, files,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Message, resp)
end

"""
    delete_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String)

Delete a message sent by a webhook.

Use this when a bot needs to remove a previously sent webhook message.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.
- `message_id::Snowflake` — The ID of the message to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the message or webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#delete-webhook-message)
"""
function delete_webhook_message(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String, message_id::Snowflake; token::String)
    discord_delete(rl, "/webhooks/$(webhook_id)/$(webhook_token)/messages/$(message_id)"; token,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
end

"""
    modify_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; body::Dict, reason=nothing) -> Webhook

Modify a webhook using its token.

Use this when external services need to update webhook settings without
requiring bot authentication, using only the webhook credentials.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.

# Keyword Arguments
- `body::Dict` — Updated webhook fields.
- `reason::String` — Audit log reason (optional, requires bot auth).

# Errors
- HTTP 400 if the webhook name is invalid.
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token)
"""
function modify_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; body::Dict, reason=nothing)
    resp = discord_patch(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; body, reason,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
    parse_response(Webhook, resp)
end

"""
    delete_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; reason=nothing)

Delete a webhook using its token.

Use this when external services need to delete webhooks without requiring
bot authentication, using only the webhook credentials.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `webhook_id::Snowflake` — The ID of the webhook.
- `webhook_token::String` — The webhook token.

# Keyword Arguments
- `reason::String` — Audit log reason (optional, requires bot auth).

# Errors
- HTTP 401 if the webhook token is invalid.
- HTTP 404 if the webhook does not exist.

[Discord docs](https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token)
"""
function delete_webhook_with_token(rl::RateLimiter, webhook_id::Snowflake, webhook_token::String; reason=nothing)
    discord_delete(rl, "/webhooks/$(webhook_id)/$(webhook_token)"; reason,
        major_params=["webhook_id" => string(webhook_id), "webhook_token" => webhook_token])
end
