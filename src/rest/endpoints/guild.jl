# Guild REST endpoints

function get_guild(rl::RateLimiter, guild_id::Snowflake; token::String, with_counts::Bool=false)
    resp = discord_get(rl, "/guilds/$(guild_id)"; token, query=with_counts ? ["with_counts" => "true"] : nothing,
        major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

function get_guild_preview(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/preview"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

function modify_guild(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Guild, resp)
end

function delete_guild(rl::RateLimiter, guild_id::Snowflake; token::String)
    discord_delete(rl, "/guilds/$(guild_id)"; token, major_params=["guild_id" => string(guild_id)])
end

function get_guild_channels(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/channels"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(DiscordChannel, resp)
end

function create_guild_channel(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/channels"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(DiscordChannel, resp)
end

function modify_guild_channel_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector)
    discord_patch(rl, "/guilds/$(guild_id)/channels"; token, body=body, major_params=["guild_id" => string(guild_id)])
end

function list_active_guild_threads(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/threads/active"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

function list_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1, after::Optional{Snowflake}=missing)
    query = ["limit" => string(limit)]
    !ismissing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/guilds/$(guild_id)/members"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Member, resp)
end

function search_guild_members(rl::RateLimiter, guild_id::Snowflake; token::String, query_str::String, limit::Int=1)
    resp = discord_get(rl, "/guilds/$(guild_id)/members/search"; token,
        query=["query" => query_str, "limit" => string(limit)],
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(Member, resp)
end

function modify_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

function modify_current_member(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/members/@me"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end

function add_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_put(rl, "/guilds/$(guild_id)/members/$(user_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function remove_guild_member_role(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/members/$(user_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function remove_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function get_guild_bans(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=1000)
    resp = discord_get(rl, "/guilds/$(guild_id)/bans"; token, query=["limit" => string(limit)],
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(Ban, resp)
end

function get_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Ban, resp)
end

function create_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    discord_put(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
end

function remove_guild_ban(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/bans/$(user_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function bulk_guild_ban(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/bulk-ban"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_roles(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/roles"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Role, resp)
end

function create_guild_role(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/roles"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

function modify_guild_role_positions(rl::RateLimiter, guild_id::Snowflake; token::String, body::Vector, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/roles"; token, body=body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Role, resp)
end

function modify_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

function delete_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function get_guild_prune_count(rl::RateLimiter, guild_id::Snowflake; token::String, days::Int=7, include_roles::String="")
    query = ["days" => string(days)]
    !isempty(include_roles) && push!(query, "include_roles" => include_roles)
    resp = discord_get(rl, "/guilds/$(guild_id)/prune"; token, query, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function begin_guild_prune(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/prune"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_voice_regions(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/regions"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(VoiceRegion, resp)
end

function get_guild_invites(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/invites"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Invite, resp)
end

function get_guild_integrations(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/integrations"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(Integration, resp)
end

function delete_guild_integration(rl::RateLimiter, guild_id::Snowflake, integration_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/guilds/$(guild_id)/integrations/$(integration_id)"; token, reason, major_params=["guild_id" => string(guild_id)])
end

function get_guild_widget_settings(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/widget"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function modify_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/widget"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_widget(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/widget.json"; token, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function get_guild_vanity_url(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/vanity-url"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Invite, resp)
end

function get_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/welcome-screen"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(WelcomeScreen, resp)
end

function modify_guild_welcome_screen(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/welcome-screen"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(WelcomeScreen, resp)
end

function get_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/onboarding"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Onboarding, resp)
end

function modify_guild_onboarding(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_put(rl, "/guilds/$(guild_id)/onboarding"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(Onboarding, resp)
end

function get_guild_role(rl::RateLimiter, guild_id::Snowflake, role_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/roles/$(role_id)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(Role, resp)
end

function add_guild_member(rl::RateLimiter, guild_id::Snowflake, user_id::Snowflake; token::String, body::Dict)
    resp = discord_put(rl, "/guilds/$(guild_id)/members/$(user_id)"; token, body, major_params=["guild_id" => string(guild_id)])
    parse_response(Member, resp)
end
