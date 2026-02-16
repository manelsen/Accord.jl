"""
    ApplicationCommandOptionChoice

A choice for a string, integer, or number application command option.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure)

# Fields
- `name::String` — choice name (1-100 characters).
- `name_localizations::Optional{Any}` — dictionary of localized choice names by locale code.
- `value::Any` — value for the choice. Type depends on the option type: String, Int, or Float64.
"""
@discord_struct ApplicationCommandOptionChoice begin
    name::String
    name_localizations::Optional{Any}
    value::Any  # String, Int, or Float64
end

"""
    ApplicationCommandOption

An option for an application command. Options can be nested up to one level deep for subcommands and groups.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)

# Fields
- `type::Int` — type of option. See [`ApplicationCommandOptionTypes`](@ref) module.
- `name::String` — option name (1-32 characters, lowercase).
- `name_localizations::Optional{Any}` — dictionary of localized names by locale code.
- `description::String` — option description (1-100 characters).
- `description_localizations::Optional{Any}` — dictionary of localized descriptions by locale code.
- `required::Optional{Bool}` — whether the option is required. Default is `false`.
- `choices::Optional{Vector{ApplicationCommandOptionChoice}}` — choices for string, integer, or number options. Maximum 25.
- `options::Optional{Vector{ApplicationCommandOption}}` — sub-options for subcommands and groups. Maximum 25.
- `channel_types::Optional{Vector{Int}}` — channel types the option will match if the option is a channel type.
- `min_value::Optional{Any}` — minimum value for number/integer options. Type depends on option type.
- `max_value::Optional{Any}` — maximum value for number/integer options. Type depends on option type.
- `min_length::Optional{Int}` — minimum length for string options (0-6000).
- `max_length::Optional{Int}` — maximum length for string options (1-6000).
- `autocomplete::Optional{Bool}` — whether this option supports autocomplete. If `true`, `choices` must be empty.
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

An application command (slash command, user command, or message command) registered for a bot.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-structure)

# Fields
- `id::Snowflake` — unique ID of the command.
- `type::Optional{Int}` — type of command. Defaults to `1` (CHAT_INPUT). See [`ApplicationCommandTypes`](@ref) module.
- `application_id::Snowflake` — unique ID of the parent application.
- `guild_id::Optional{Snowflake}` — guild ID of the command, if not global.
- `name::String` — name of the command (1-32 characters).
- `name_localizations::Optional{Any}` — dictionary of localized names by locale code.
- `description::String` — description for chat input commands (1-100 characters). Empty string for user/message commands.
- `description_localizations::Optional{Any}` — dictionary of localized descriptions by locale code.
- `options::Optional{Vector{ApplicationCommandOption}}` — parameters for the command. Maximum 25 options.
- `default_member_permissions::Nullable{String}` — permissions required to use the command. Set to `nothing` to disable default restrictions.
- `dm_permission::Optional{Bool}` — whether the command is available in DMs with the app. Only for global commands.
- `nsfw::Optional{Bool}` — whether the command is age-restricted.
- `integration_types::Optional{Vector{Int}}` — installation contexts where the command is available. See `ApplicationIntegrationTypes` (0 = guild install, 1 = user install).
- `contexts::Optional{Vector{Int}}` — interaction contexts where the command can be used. See `InteractionContextTypes` (0 = guild, 1 = bot dm, 2 = private channel).
- `version::Optional{Snowflake}` — auto-incrementing version identifier updated during substantial record changes.
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

Resolved data from interaction options, containing full objects for mentioned users, roles, channels, etc.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-resolved-data-structure)

# Fields
- `users::Optional{Any}` — map of Snowflake to User object for resolved users.
- `members::Optional{Any}` — map of Snowflake to partial Member object for resolved members.
- `roles::Optional{Any}` — map of Snowflake to Role object for resolved roles.
- `channels::Optional{Any}` — map of Snowflake to partial Channel object for resolved channels.
- `messages::Optional{Any}` — map of Snowflake to partial Message object for resolved messages.
- `attachments::Optional{Any}` — map of Snowflake to Attachment object for resolved attachments.
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

An option received from an interaction, containing the name, type, and value (or nested options for subcommands).

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-application-command-interaction-data-option-structure)

# Fields
- `name::String` — name of the parameter.
- `type::Int` — value of application command option type. See `ApplicationCommandOptionTypes` module.
- `value::Optional{Any}` — value of the option resulting from user input. Only present for leaf options.
- `options::Optional{Vector{InteractionDataOption}}` — present if this option is a group or subcommand. Contains nested options.
- `focused::Optional{Bool}` — `true` if this option is the currently focused option for autocomplete. Only present for autocomplete interactions.
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

Data payload for an interaction. Contains different fields depending on the interaction type (application command, message component, modal submit).

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-data-structure)

# Fields
- `id::Optional{Snowflake}` — ID of the invoked command. Present for application command interactions.
- `name::Optional{String}` — name of the invoked command. Present for application command interactions.
- `type::Optional{Int}` — type of the invoked command. Present for application command interactions.
- `resolved::Optional{ResolvedData}` — converted users, roles, channels, and attachments from options.
- `options::Optional{Vector{InteractionDataOption}}` — params and values from the user. Present for application command interactions.
- `guild_id::Optional{Snowflake}` — ID of the guild the command is registered to. Present for application command interactions.
- `custom_id::Optional{String}` — custom ID of the component. Present for message component and modal submit interactions.
- `component_type::Optional{Int}` — type of the component. Present for message component interactions.
- `values::Optional{Vector{String}}` — values selected by the user. Present for select menu interactions.
- `target_id::Optional{Snowflake}` — ID of the user or message targeted. Present for user/message command interactions.
- `components::Optional{Vector{Component}}` — values submitted by the user. Present for modal submit interactions.
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

An interaction is the message that your application receives when a user uses an application command or a message component.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure)

# Fields
- `id::Snowflake` — unique ID of the interaction.
- `application_id::Snowflake` — ID of the application this interaction is for.
- `type::Int` — type of interaction. See `InteractionTypes` module.
- `data::Optional{InteractionData}` — command data payload. Only present for application command, message component, and modal submit types.
- `guild_id::Optional{Snowflake}` — guild that the interaction was sent from. May be missing for some interaction types.
- `channel::Optional{DiscordChannel}` — channel that the interaction was sent from. Only present in certain interaction types.
- `channel_id::Optional{Snowflake}` — channel that the interaction was sent from. May be missing for some interaction types.
- `member::Optional{Member}` — guild member data for the invoking user, including permissions. Only present when invoked in a guild.
- `user::Optional{User}` — user object for the invoking user, if invoked in a DM.
- `token::String` — continuation token for responding to the interaction. Valid for 15 minutes.
- `version::Int` — read-only property, always `1`.
- `message::Optional{Message}` — for components, the message they were attached to. Not present for application command interactions.
- `app_permissions::Optional{String}` — set of permissions the app or bot has within the channel the interaction was sent from.
- `locale::Optional{String}` — selected language of the invoking user. Only present for application command interactions.
- `guild_locale::Optional{String}` — guild's preferred locale, if invoked in a guild.
- `entitlements::Optional{Vector{Any}}` — for monetized apps, entitlements the user has.
- `authorizing_integration_owners::Optional{Any}` — mapping of installation contexts that the interaction was authorized for to related user or guild IDs.
- `context::Optional{Int}` — context where the interaction was triggered from. See `InteractionContextTypes` module.
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
