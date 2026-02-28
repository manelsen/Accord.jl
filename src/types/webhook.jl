"""
    Webhook

Represents a Discord webhook. Webhooks allow bots and external services to 
post messages to a channel without requiring a full bot user or authentication.

# Fields
- `id::Snowflake`: The unique ID of the webhook.
- `type::Int`: The type of webhook (see [`WebhookTypes`](@ref)).
- `guild_id::Optional{Snowflake}`: The ID of the guild the webhook is in.
- `channel_id::Nullable{Snowflake}`: The ID of the channel the webhook posts to.
- `user::Optional{User}`: The user who created the webhook.
- `name::Nullable{String}`: The default name of the webhook.
- `avatar::Nullable{String}`: The default avatar hash.
- `token::Optional{String}`: The secure token (for executing the webhook).
- `url::Optional{String}`: The full execution URL.

# See Also
- [Discord API: Webhook Object](https://discord.com/developers/docs/resources/webhook#webhook-object)
"""
@discord_struct Webhook begin
    id::Snowflake
    type::Int
    guild_id::Optional{Snowflake}
    channel_id::Nullable{Snowflake}
    user::Optional{User}
    name::Nullable{String}
    avatar::Nullable{String}
    token::Optional{String}
    application_id::Nullable{Snowflake}
    source_guild::Optional{Any}
    source_channel::Optional{Any}
    url::Optional{String}
end
