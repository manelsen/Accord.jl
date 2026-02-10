@discord_struct AuditLogChange begin
    new_value::Optional{Any}
    old_value::Optional{Any}
    key::String
end

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

@discord_struct AuditLogEntry begin
    target_id::Nullable{String}
    changes::Optional{Vector{AuditLogChange}}
    user_id::Nullable{Snowflake}
    id::Snowflake
    action_type::Int
    options::Optional{AuditLogEntryInfo}
    reason::Optional{String}
end

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
