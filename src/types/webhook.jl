"""
    Webhook

A webhook is a low-effort way to post messages to channels in Discord. They do not require a bot user or authentication to use.

[Discord docs](https://discord.com/developers/docs/resources/webhook#webhook-object)

# Fields
- `id::Snowflake` — webhook ID.
- `type::Int` — type of webhook. See [`WebhookTypes`](@ref) module.
- `guild_id::Optional{Snowflake}` — guild ID this webhook is for. May not be present if the webhook was created by an OAuth2 app.
- `channel_id::Nullable{Snowflake}` — channel ID this webhook is for. `nothing` if the webhook was created by an OAuth2 app.
- `user::Optional{User}` — user that created this webhook. Not returned when receiving a message via webhook execution.
- `name::Nullable{String}` — default name of the webhook. `nothing` if not set.
- `avatar::Nullable{String}` — default avatar hash of the webhook. `nothing` if not set.
- `token::Optional{String}` — secure token of the webhook. Returned for incoming webhooks.
- `application_id::Nullable{Snowflake}` — OAuth2 application that created this webhook. `nothing` if not created by an OAuth2 app.
- `source_guild::Optional{Any}` — guild of the channel that this webhook is following. Present for channel follower webhooks.
- `source_channel::Optional{Any}` — channel that this webhook is following. Present for channel follower webhooks.
- `url::Optional{String}` — URL used for executing the webhook. Returned for incoming webhooks.
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
