"""
    AutoModActionMetadata

Metadata associated with an [`AutoModAction`](@ref).

# Fields
- `channel_id::Optional{Snowflake}`: Channel to log alerts to (for `SEND_ALERT_MESSAGE`).
- `duration_seconds::Optional{Int}`: Timeout duration (for `TIMEOUT`).
- `custom_message::Optional{String}`: Message shown to the user (for `BLOCK_MESSAGE`).

# See Also
- [Discord API: Auto Moderation Action Metadata](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object-action-metadata)
"""
@discord_struct AutoModActionMetadata begin
    channel_id::Optional{Snowflake}
    duration_seconds::Optional{Int}
    custom_message::Optional{String}
end

"""
    AutoModAction

An action to take when an [`AutoModRule`](@ref) is triggered.

# Fields
- `type::Int`: Action type (see [`AutoModActionTypes`](@ref)).
- `metadata::Optional{AutoModActionMetadata}`: Additional data for the action.

# See Also
- [Discord API: Auto Moderation Action Object](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object)
"""
@discord_struct AutoModAction begin
    type::Int
    metadata::Optional{AutoModActionMetadata}
end

"""
    AutoModTriggerMetadata

Configuration for what triggers an [`AutoModRule`](@ref).

# Fields
- `keyword_filter::Optional{Vector{String}}`: Substrings to search for.
- `regex_patterns::Optional{Vector{String}}`: Regex patterns to match.
- `presets::Optional{Vector{Int}}`: Predefined wordsets (see [`AutoModKeywordPresetTypes`](@ref)).
- `allow_list::Optional{Vector{String}}`: Substrings that are exempt from the rule.
- `mention_total_limit::Optional{Int}`: Max unique mentions allowed.

# See Also
- [Discord API: Auto Moderation Trigger Metadata](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-trigger-metadata)
"""
@discord_struct AutoModTriggerMetadata begin
    keyword_filter::Optional{Vector{String}}
    regex_patterns::Optional{Vector{String}}
    presets::Optional{Vector{Int}}
    allow_list::Optional{Vector{String}}
    mention_total_limit::Optional{Int}
    mention_raid_protection_enabled::Optional{Bool}
end

"""
    AutoModRule

Represents a rule for the Discord Auto Moderation system.

Rules define what content is filtered and what actions are taken automatically.

# Fields
- `id::Snowflake`: Unique ID of the rule.
- `guild_id::Snowflake`: ID of the guild the rule belongs to.
- `name::String`: Name of the rule.
- `creator_id::Snowflake`: ID of the user who created the rule.
- `event_type::Int`: Event context (see [`AutoModEventTypes`](@ref)).
- `trigger_type::Int`: What triggers the rule (see [`AutoModTriggerTypes`](@ref)).
- `trigger_metadata::Optional{AutoModTriggerMetadata}`: Details about the trigger.
- `actions::Vector{AutoModAction}`: Actions to perform on trigger.
- `enabled::Bool`: Whether the rule is active.
- `exempt_roles::Vector{Snowflake}`: Roles exempt from this rule.
- `exempt_channels::Vector{Snowflake}`: Channels exempt from this rule.

# See Also
- [Discord API: Auto Moderation Rule Object](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object)
"""
@discord_struct AutoModRule begin
    id::Snowflake
    guild_id::Snowflake
    name::String
    creator_id::Snowflake
    event_type::Int
    trigger_type::Int
    trigger_metadata::Optional{AutoModTriggerMetadata}
    actions::Vector{AutoModAction}
    enabled::Bool
    exempt_roles::Vector{Snowflake}
    exempt_channels::Vector{Snowflake}
end
