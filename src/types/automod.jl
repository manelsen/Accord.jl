@discord_struct AutoModActionMetadata begin
    channel_id::Optional{Snowflake}
    duration_seconds::Optional{Int}
    custom_message::Optional{String}
end

@discord_struct AutoModAction begin
    type::Int
    metadata::Optional{AutoModActionMetadata}
end

@discord_struct AutoModTriggerMetadata begin
    keyword_filter::Optional{Vector{String}}
    regex_patterns::Optional{Vector{String}}
    presets::Optional{Vector{Int}}
    allow_list::Optional{Vector{String}}
    mention_total_limit::Optional{Int}
    mention_raid_protection_enabled::Optional{Bool}
end

@discord_struct AutoModRule begin
    id::Snowflake
    guild_id::Snowflake
    name::String
    creator_id::Snowflake
    event_type::Int
    trigger_type::Int
    trigger_metadata::AutoModTriggerMetadata
    actions::Vector{AutoModAction}
    enabled::Bool
    exempt_roles::Vector{Snowflake}
    exempt_channels::Vector{Snowflake}
end
