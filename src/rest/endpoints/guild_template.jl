# Guild Template REST endpoints

"""Use this to retrieve all guild templates available for a specific server.

Get all templates for a guild."""
function get_guild_templates(rl::RateLimiter, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/guilds/$(guild_id)/templates"; token, major_params=["guild_id" => string(guild_id)])
    parse_response_array(GuildTemplate, resp)
end

"""Use this to create a new template from the current state of a guild.

Create a guild template."""
function create_guild_template(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/guilds/$(guild_id)/templates"; token, body, major_params=["guild_id" => string(guild_id)])
    parse_response(GuildTemplate, resp)
end

"""Use this to update a template to match the current state of the guild.

Sync the template to the guild's current state."""
function sync_guild_template(rl::RateLimiter, guild_id::Snowflake, template_code::String; token::String)
    resp = discord_put(rl, "/guilds/$(guild_id)/templates/$(template_code)"; token, major_params=["guild_id" => string(guild_id)])
    parse_response(GuildTemplate, resp)
end

"""Use this to change the name or description of an existing guild template.

Modify a guild template's metadata."""
function modify_guild_template(rl::RateLimiter, guild_id::Snowflake, template_code::String; token::String, body::Dict)
    resp = discord_patch(rl, "/guilds/$(guild_id)/templates/$(template_code)"; token, body, major_params=["guild_id" => string(guild_id)])
    parse_response(GuildTemplate, resp)
end

"""Use this to remove a guild template permanently.

Delete a guild template."""
function delete_guild_template(rl::RateLimiter, guild_id::Snowflake, template_code::String; token::String)
    discord_delete(rl, "/guilds/$(guild_id)/templates/$(template_code)"; token, major_params=["guild_id" => string(guild_id)])
end

"""Use this to create a new server using an existing template as a starting point.

Create a new guild from a template."""
function create_guild_from_template(rl::RateLimiter, template_code::String; token::String, body::Dict)
    resp = discord_post(rl, "/guilds/templates/$(template_code)"; token, body)
    parse_response(Guild, resp)
end
