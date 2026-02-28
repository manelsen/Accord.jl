"""
    AuditLogChange

Represents a change to a guild resource recorded in the audit log.

# Fields
- `new_value::Optional{Any}`: The value after the change.
- `old_value::Optional{Any}`: The value before the change.
- `key::String`: The name of the property that was changed (e.g., "name", "permissions").

# See Also
- [Discord API: Audit Log Change Object](https://discord.com/developers/docs/resources/audit-log#audit-log-change-object)
"""
@discord_struct AuditLogChange begin
    new_value::Optional{Any}
    old_value::Optional{Any}
    key::String
end

"""
    AuditLogEntryInfo

Extra information for specific audit log events (e.g., prune details, 
overwrite types).

# See Also
- [Discord API: Audit Log Entry Info](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-optional-audit-entry-info)
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

An individual entry in the guild audit log.

# Fields
- `target_id::Nullable{String}`: ID of the affected entity (User, Role, etc.).
- `changes::Optional{Vector{AuditLogChange}}`: List of changes made.
- `user_id::Nullable{Snowflake}`: ID of the user who performed the action.
- `id::Snowflake`: Unique ID of the entry.
- `action_type::Int`: Type of action (see [`AuditLogEvent`](@ref)).
- `options::Optional{AuditLogEntryInfo}`: Additional context for the action.
- `reason::Optional{String}`: Reason provided by the user (max 512 characters).

# See Also
- [Discord API: Audit Log Entry Object](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object)
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

Represents the audit log for a guild. Contains a list of entries and 
referenced objects (users, webhooks, etc.).

# Fields
- `audit_log_entries::Vector{AuditLogEntry}`: The actual log entries.
- `users::Vector{User}`: Users referenced in the log.
- `webhooks::Vector{Webhook}`: Webhooks referenced in the log.
- `application_commands::Vector{ApplicationCommand}`: Commands referenced.

# See Also
- [Discord API: Audit Log Object](https://discord.com/developers/docs/resources/audit-log#audit-log-object)
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
