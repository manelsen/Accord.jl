"""
    ApplicationCommandOptionChoice

A choice for a string, integer, or number application command option.

# Fields
- `name::String`: The choice name (1-100 characters).
- `name_localizations::Optional{Any}`: Localized names.
- `value::Any`: The value of the choice (String, Int, or Float64).

# See Also
- [Discord API: Application Command Option Choice](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure)
"""
@discord_struct ApplicationCommandOptionChoice begin
    name::String
    name_localizations::Optional{Any}
    value::Any  # String, Int, or Float64
end

"""
    ApplicationCommandOption

An option (parameter) for an application command.

# Fields
- `type::Int`: The type of option (see [`ApplicationCommandOptionTypes`](@ref)).
- `name::String`: The parameter name (1-32 characters).
- `description::String`: The parameter description (1-100 characters).
- `required::Optional{Bool}`: Whether the parameter is required.
- `choices::Optional{Vector{ApplicationCommandOptionChoice}}`: Fixed choices for the user.
- `options::Optional{Vector{ApplicationCommandOption}}`: Nested sub-options (for groups/subcommands).
- `autocomplete::Optional{Bool}`: Whether this option supports autocomplete.

# See Also
- [Discord API: Application Command Option](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)
"""
@discord_struct ApplicationCommandOption begin
    type::Int
    name::String
    name_localizations::Optional{Any}
    description::String
    description_localizations::Optional{Any}
    required::Optional{Bool}
    choices::Optional{Vector{ApplicationCommandOptionChoice}}
    options::Optional{Vector{ApplicationCommandOption}}
    channel_types::Optional{Vector{Int}}
    min_value::Optional{Any}
    max_value::Optional{Any}
    min_length::Optional{Int}
    max_length::Optional{Int}
    autocomplete::Optional{Bool}
end

"""
    ApplicationCommand

Represents a registered application command (Slash Command, User Command, or Message Command).

# Fields
- `id::Snowflake`: The unique ID of the command.
- `type::Optional{Int}`: The command type (default 1: CHAT_INPUT).
- `application_id::Snowflake`: The ID of the parent application.
- `guild_id::Optional{Snowflake}`: The guild ID (missing for global commands).
- `name::String`: The command name.
- `description::String`: The command description.
- `options::Optional{Vector{ApplicationCommandOption}}`: The command parameters.
- `default_member_permissions::Nullable{String}`: Default permissions required.
- `nsfw::Optional{Bool}`: Whether the command is age-restricted.

# See Also
- [Discord API: Application Command](https://discord.com/developers/docs/interactions/application-commands#application-command-object)
"""
@discord_struct ApplicationCommand begin
    id::Snowflake
    type::Optional{Int}
    application_id::Snowflake
    guild_id::Optional{Snowflake}
    name::String
    name_localizations::Optional{Any}
    description::String
    description_localizations::Optional{Any}
    options::Optional{Vector{ApplicationCommandOption}}
    default_member_permissions::Nullable{String}
    dm_permission::Optional{Bool}
    nsfw::Optional{Bool}
    integration_types::Optional{Vector{Int}}
    contexts::Optional{Vector{Int}}
    version::Optional{Snowflake}
end

"""
    ResolvedData

Contains the full objects for users, roles, channels, etc., mentioned in an interaction.

# See Also
- [Discord API: Resolved Data](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-resolved-data-structure)
"""
@discord_struct ResolvedData begin
    users::Optional{Any}
    members::Optional{Any}
    roles::Optional{Any}
    channels::Optional{Any}
    messages::Optional{Any}
    attachments::Optional{Any}
end

"""
    InteractionDataOption

An option/value received from a user in an interaction.

# See Also
- [Discord API: Interaction Data Option](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-application-command-interaction-data-option-structure)
"""
@discord_struct InteractionDataOption begin
    name::String
    type::Int
    value::Optional{Any}
    options::Optional{Vector{InteractionDataOption}}
    focused::Optional{Bool}
end

"""
    InteractionData

The actual payload of an interaction. Fields vary depending on the interaction type.

# See Also
- [Discord API: Interaction Data](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-data-structure)
"""
@discord_struct InteractionData begin
    id::Optional{Snowflake}
    name::Optional{String}
    type::Optional{Int}
    resolved::Optional{ResolvedData}
    options::Optional{Vector{InteractionDataOption}}
    guild_id::Optional{Snowflake}
    custom_id::Optional{String}
    component_type::Optional{Int}
    values::Optional{Vector{String}}
    target_id::Optional{Snowflake}
    components::Optional{Vector{Component}}
end

"""
    Interaction

Represents a Discord interaction (Slash Command, Component, Modal, etc.).

An `Interaction` is sent by Discord whenever a user interacts with your bot's 
commands or components.

# Fields
- `id::Snowflake`: The unique ID of the interaction.
- `application_id::Snowflake`: ID of the application.
- `type::Int`: Type of interaction (see [`InteractionTypes`](@ref)).
- `data::Optional{InteractionData}`: The command/component data payload.
- `guild_id::Optional{Snowflake}`: ID of the guild it originated from.
- `channel::Optional{DiscordChannel}`: The channel it originated from.
- `member::Optional{Member}`: Member data for the invoking user (in guilds).
- `user::Optional{User}`: User data for the invoking user (in DMs).
- `token::String`: Continuation token for responding.
- `message::Optional{Message}`: The message the component was attached to.

# Example
```julia
on_interaction(ctx) do int
    if int.type == InteractionTypes.APPLICATION_COMMAND
        println("Command invoked: \$(int.data.name)")
    end
end
```

# See Also
- [Discord API: Interaction Object](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object)
"""
@discord_struct Interaction begin
    id::Snowflake
    application_id::Snowflake
    type::Int
    data::Optional{InteractionData}
    guild_id::Optional{Snowflake}
    channel::Optional{DiscordChannel}
    channel_id::Optional{Snowflake}
    member::Optional{Member}
    user::Optional{User}
    token::String
    version::Int
    message::Optional{Message}
    app_permissions::Optional{String}
    locale::Optional{String}
    guild_locale::Optional{String}
    entitlements::Optional{Vector{Any}}
    authorizing_integration_owners::Optional{Any}
    context::Optional{Int}
end
