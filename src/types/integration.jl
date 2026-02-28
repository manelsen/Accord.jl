"""
    IntegrationAccount

Third-party account info for an [`Integration`](@ref).

# See Also
- [Discord API: Integration Account](https://discord.com/developers/docs/resources/guild#integration-account-object)
"""
@discord_struct IntegrationAccount begin
    id::String
    name::String
end

"""
    IntegrationApplication

Application info for a Discord [`Integration`](@ref).

# See Also
- [Discord API: Integration Application](https://discord.com/developers/docs/resources/guild#integration-application-object)
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

Represents a guild integration (Twitch, YouTube, Discord App, etc.).

# Fields
- `id::Snowflake`: Integration ID.
- `name::String`: Integration name.
- `type::String`: Integration type ("twitch", "youtube", "discord").
- `enabled::Optional{Bool}`: Whether it is enabled.
- `user::Optional{User}`: User for this integration.
- `account::Optional{IntegrationAccount}`: Connected account info.
- `application::Optional{IntegrationApplication}`: For Discord App integrations.

# See Also
- [Discord API: Integration Object](https://discord.com/developers/docs/resources/guild#integration-object)
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
