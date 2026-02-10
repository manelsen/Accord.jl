# Auto Moderation REST endpoints

function list_auto_moderation_rules(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/auto-moderation/rules"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(AutoModRule, resp)
end

function get_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

function create_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/auto-moderation/rules"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

function modify_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(AutoModRule, resp)
end

function delete_auto_moderation_rule(rl::RateLimiter, guild_id::Snowflake, rule_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/auto-moderation/rules/$(rule_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end
