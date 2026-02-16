"""
    AuditLogChange

A change made to an object, logged in the audit log.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#audit-log-change-object)

# Fields
- `new_value::Optional{Any}` — new value of the key.
- `old_value::Optional{Any}` — old value of the key.
- `key::String` — name of the changed property.
"""
@discord_struct AuditLogChange begin
    new_value::Optional{Any}
    old_value::Optional{Any}
    key::String
end

"""
    AuditLogEntryInfo


Additional info for certain audit log events.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-optional-audit-entry-info)

# Fields
- `application_id::Optional{Snowflake}` — ID of the app whose permissions were targeted. Present for `APPLICATION_COMMAND_PERMISSION_UPDATE`.
- `auto_moderation_rule_name::Optional{String}` — Name of the Auto Moderation rule that was triggered. Present for `AUTO_MODERATION_BLOCK_MESSAGE` and similar.
- `auto_moderation_rule_trigger_type::Optional{String}` — Trigger type of the Auto Moderation rule. Present for `AUTO_MODERATION_BLOCK_MESSAGE` and similar.
- `channel_id::Optional{Snowflake}` — Channel in which the entities were targeted. Present for relevant events.
- `count::Optional{String}` — Number of entities that were targeted. Present for relevant events.
- `delete_member_days::Optional{String}` — Number of days after which inactive members were kicked. Present for `MEMBER_PRUNE`.
- `id::Optional{Snowflake}` — ID of the overwritten entity. Present for channel overwrite events.
- `members_removed::Optional{String}` — Number of members removed by prune. Present for `MEMBER_PRUNE`.
- `message_id::Optional{Snowflake}` — ID of the message that was targeted. Present for message events.
- `role_name::Optional{String}` — Name of the role if type is "0" (role) or type is "1" (member) and the role was deleted.
- `type::Optional{String}` — Type of overwritten entity - role ("0") or member ("1"). Present for channel overwrite events.
- `integration_type::Optional{String}` — The type of integration which performed the action. Present for relevant events.
"""
@discord_struct AuditLogEntryInfo begin
    application_id::Optional{Snowflake}
    auto_moderation_rule_name::Optional{String}
    auto_moderation_rule_trigger_type::Optional{String}
    channel_id::Optional{Snowflake}
    count::Optional{String}
    delete_member_days::Optional{String}
    id::Optional{Snowflake}
    members_removed::Optional{String}
    message_id::Optional{Snowflake}
    role_name::Optional{String}
    type::Optional{String}
    integration_type::Optional{String}
end

"""
    AuditLogEntry

An entry in the audit log representing an action taken in the guild.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object)

# Fields
- `target_id::Nullable{String}` — ID of the affected entity (webhook, user, role, etc.). May be `nothing` for some actions.
- `changes::Optional{Vector{AuditLogChange}}` — Changes made to the target_id. Only present for certain action types.
- `user_id::Nullable{Snowflake}` — User or app that made the changes. May be `nothing` for automated actions.
- `id::Snowflake` — ID of the entry.
- `action_type::Int` — Type of action that occurred. See `AuditLogEvent` enum.
- `options::Optional{AuditLogEntryInfo}` — Additional info for certain action types.
- `reason::Optional{String}` — Reason for the change (1-512 characters).
"""
@discord_struct AuditLogEntry begin
    target_id::Nullable{String}
    changes::Optional{Vector{AuditLogChange}}
    user_id::Nullable{Snowflake}
    id::Snowflake
    action_type::Int
    options::Optional{AuditLogEntryInfo}
    reason::Optional{String}
end

"""
    AuditLog

The audit log for a guild, containing all logged actions.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#audit-log-object)

# Fields
- `application_commands::Vector{ApplicationCommand}` — List of application commands referenced in the audit log.
- `audit_log_entries::Vector{AuditLogEntry}` — List of audit log entries, sorted from most to least recent.
- `auto_moderation_rules::Vector{Any}` — List of auto moderation rules referenced in the audit log.
- `guild_scheduled_events::Vector{Any}` — List of guild scheduled events referenced in the audit log.
- `integrations::Vector{Any}` — List of partial integration objects.
- `threads::Vector{DiscordChannel}` — List of threads referenced in the audit log.
- `users::Vector{User}` — List of users found in the audit log.
- `webhooks::Vector{Webhook}` — List of webhooks referenced in the audit log.
"""
@discord_struct AuditLog begin
    application_commands::Vector{ApplicationCommand}
    audit_log_entries::Vector{AuditLogEntry}
    auto_moderation_rules::Vector{Any}
    guild_scheduled_events::Vector{Any}
    integrations::Vector{Any}
    threads::Vector{DiscordChannel}
    users::Vector{User}
    webhooks::Vector{Webhook}
end
