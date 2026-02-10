@discord_struct ApplicationCommandOptionChoice begin
    name::String
    name_localizations::Optional{Any}
    value::Any  # String, Int, or Float64
end

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

@discord_struct ResolvedData begin
    users::Optional{Any}
    members::Optional{Any}
    roles::Optional{Any}
    channels::Optional{Any}
    messages::Optional{Any}
    attachments::Optional{Any}
end

@discord_struct InteractionDataOption begin
    name::String
    type::Int
    value::Optional{Any}
    options::Optional{Vector{InteractionDataOption}}
    focused::Optional{Bool}
end

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
