# Auto Moderation REST endpoints

"""
    list_auto_moderation_rules(rl::RateLimiter, guild_id::Snowflake; token::String) -> Vector{AutoModRule}

Get all AutoMod rules for a guild.

Use this when a bot needs to list configured AutoMod rules, such as for
moderation dashboards or rule management commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild)
"""
function list_auto_moderation_rules(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/auto-moderation/rules"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(AutoModRule, resp)
end

"""
    get_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String) -> AutoModRule

Get a specific AutoMod rule.

Use this when a bot needs to retrieve details of a single AutoMod rule,
such as for editing or displaying rule information.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `rule_id::Snowflake` — The ID of the rule.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the rule or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule)
"""
function get_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

"""
    create_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> AutoModRule

Create a new AutoMod rule.

Use this when a bot needs to set up automatic moderation rules, such as
for content filtering, keyword detection, or spam prevention.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Rule configuration (name, event_type, trigger_type, actions, etc.).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Rule Limits
- Maximum 5 rules per guild for most trigger types.
- Maximum 6 `MENTION_SPAM` rules per guild.

# Errors
- HTTP 400 if the rule configuration is invalid.
- HTTP 403 if missing required permissions.
- HTTP 429 if too many rules created.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule)
"""
function create_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/auto-moderation/rules"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

"""
    modify_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, body::Dict, reason=nothing) -> AutoModRule

Modify an existing AutoMod rule.

Use this when a bot needs to update rule configuration, such as changing
trigger conditions, actions, or exempt roles/channels.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `rule_id::Snowflake` — The ID of the rule to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated rule fields.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 400 if the rule configuration is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the rule does not exist.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule)
"""
function modify_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

"""
    delete_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, reason=nothing)

Delete an AutoMod rule.

Use this when a bot needs to remove moderation rules, such as for rule
management systems or temporary rule disabling.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `rule_id::Snowflake` — The ID of the rule to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_GUILD`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the rule or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule)
"""
function delete_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end
