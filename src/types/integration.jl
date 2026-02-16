"""
    IntegrationAccount

Account information for an integration.

[Discord docs](https://discord.com/developers/docs/resources/guild#integration-account-object)

# Fields
- `id::String` — ID of the account.
- `name::String` — Name of the account.
"""
@discord_struct IntegrationAccount begin
    id::String
    name::String
end

"""
    IntegrationApplication

Application information for an integration. Used for bot integrations.

[Discord docs](https://discord.com/developers/docs/resources/guild#integration-application-object)

# Fields
- `id::Snowflake` — ID of the app.
- `name::String` — Name of the app.
- `icon::Nullable{String}` — Icon hash of the app. May be `nothing`.
- `description::String` — Description of the app.
- `bot::Optional{User}` — Bot user associated with this application. May be `nothing` if the bot user is not added to the guild.
"""
@discord_struct IntegrationApplication begin
    id::Snowflake
    name::String
    icon::Nullable{String}
    description::String
    bot::Optional{User}
end

"""
    Integration

A guild integration. Represents a connection between a guild and a third-party service (Twitch, YouTube, Discord, etc.).

[Discord docs](https://discord.com/developers/docs/resources/guild#integration-object)

# Fields
- `id::Snowflake` — Integration ID.
- `name::String` — Integration name.
- `type::String` — Integration type (twitch, youtube, discord, or guild_subscription).
- `enabled::Optional{Bool}` — Whether this integration is enabled.
- `syncing::Optional{Bool}` — Whether this integration is syncing. Only for Twitch/YouTube integrations.
- `role_id::Optional{Snowflake}` — ID that this integration uses for subscribers. Only for Twitch/YouTube integrations.
- `enable_emoticons::Optional{Bool}` — Whether emoticons should be synced for this integration. Only for Twitch integrations.
- `expire_behavior::Optional{Int}` — Behavior of expiring subscribers. See `IntegrationExpireBehaviors` (0 = remove role, 1 = kick). Only for Twitch/YouTube integrations.
- `expire_grace_period::Optional{Int}` — Grace period before expiring subscribers in days. Only for Twitch/YouTube integrations.
- `user::Optional{User}` — User for this integration. Only for Discord integrations.
- `account::Optional{IntegrationAccount}` — Integration account information.
- `synced_at::Optional{String}` — ISO8601 timestamp when this integration was last synced. Only for Twitch/YouTube integrations.
- `subscriber_count::Optional{Int}` — How many subscribers this integration has. Only for Twitch/YouTube integrations.
- `revoked::Optional{Bool}` — Whether this integration has been revoked.
- `application::Optional{IntegrationApplication}` — The bot/OAuth2 application for Discord integrations.
- `scopes::Optional{Vector{String}}` — Scopes the application has been authorized for. Only for Discord integrations.
"""
@discord_struct Integration begin
    id::Snowflake
    name::String
    type::String
    enabled::Optional{Bool}
    syncing::Optional{Bool}
    role_id::Optional{Snowflake}
    enable_emoticons::Optional{Bool}
    expire_behavior::Optional{Int}
    expire_grace_period::Optional{Int}
    user::Optional{User}
    account::Optional{IntegrationAccount}
    synced_at::Optional{String}
    subscriber_count::Optional{Int}
    revoked::Optional{Bool}
    application::Optional{IntegrationApplication}
    scopes::Optional{Vector{String}}
end
