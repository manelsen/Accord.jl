"""
    AutoModActionMetadata

Additional data used when an action is executed.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object-action-metadata)

# Fields
- `channel_id::Optional{Snowflake}` — ID of channel to which user content should be logged. Only for `SEND_ALERT_MESSAGE` action type.
- `duration_seconds::Optional{Int}` — Timeout duration in seconds. Maximum 2419200 seconds (4 weeks). Only for `TIMEOUT` action type.
- `custom_message::Optional{String}` — Additional explanation that will be shown to members whenever their message is blocked. Maximum 150 characters. Only for `BLOCK_MESSAGE` action type.
"""
@discord_struct AutoModActionMetadata begin
    channel_id::Optional{Snowflake}
    duration_seconds::Optional{Int}
    custom_message::Optional{String}
end

"""
    AutoModAction

An action which will execute whenever a rule is triggered.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object)

# Fields
- `type::Int` — Type of action. See [`AutoModActionTypes`](@ref) module.
- `metadata::Optional{AutoModActionMetadata}` — Additional metadata needed during execution for this specific action type.
"""
@discord_struct AutoModAction begin
    type::Int
    metadata::Optional{AutoModActionMetadata}
end

"""
    AutoModTriggerMetadata

Additional data used to determine whether a rule should be triggered.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-trigger-metadata)

# Fields
- `keyword_filter::Optional{Vector{String}}` — Substrings which will be searched for in content. Maximum 1000. Only for `KEYWORD` trigger type.
- `regex_patterns::Optional{Vector{String}}` — Regular expression patterns which will be matched against content. Maximum 10. Only for `KEYWORD` trigger type.
- `presets::Optional{Vector{Int}}` — The internally pre-defined wordsets which will be searched for in content. See [`AutoModKeywordPresetTypes`](@ref) module. Only for `KEYWORD_PRESET` trigger type.
- `allow_list::Optional{Vector{String}}` — Substrings which should not trigger the rule. Maximum 100 or 1000 depending on trigger type. For `KEYWORD` and `KEYWORD_PRESET` trigger types.
- `mention_total_limit::Optional{Int}` — Total number of unique role and user mentions allowed per message. Maximum 50. Only for `MENTION_SPAM` trigger type.
- `mention_raid_protection_enabled::Optional{Bool}` — Whether to automatically detect mention raids. Only for `MENTION_SPAM` trigger type.
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

A rule which defines the trigger and actions for auto moderation.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object)

# Fields
- `id::Snowflake` — Unique ID of the rule.
- `guild_id::Snowflake` — ID of the guild which this rule belongs to.
- `name::String` — Rule name (1-255 characters).
- `creator_id::Snowflake` — User which first created this rule.
- `event_type::Int` — Event type indicating in what event context a rule should be checked. See [`AutoModEventTypes`](@ref) module.
- `trigger_type::Int` — Trigger type indicating what type of information to check for. See [`AutoModTriggerTypes`](@ref) module.
- `trigger_metadata::Optional{AutoModTriggerMetadata}` — Additional data used to determine whether a rule should be triggered.
- `actions::Vector{AutoModAction}` — Actions which will execute when the rule is triggered.
- `enabled::Bool` — Whether the rule is enabled.
- `exempt_roles::Vector{Snowflake}` — Role IDs that should not be affected by the rule (Maximum 20).
- `exempt_channels::Vector{Snowflake}` — Channel IDs that should not be affected by the rule (Maximum 50).
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
