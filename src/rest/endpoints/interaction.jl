# Interaction & Application Command REST endpoints

# --- Application Commands ---
function get_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, with_localizations::Bool=false)
    query = with_localizations ? ["with_localizations" => "true"] : nothing
    resp = discord_get(rl, "/applications/$(application_id)/commands"; token, query)
    parse_response_array(ApplicationCommand, resp)
end

function create_global_application_command(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/commands"; token, body)
    parse_response(ApplicationCommand, resp)
end

function get_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/commands/$(command_id)"; token)
    parse_response(ApplicationCommand, resp)
end

function edit_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/commands/$(command_id)"; token, body)
    parse_response(ApplicationCommand, resp)
end

function delete_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/commands/$(command_id)"; token)
end

function bulk_overwrite_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/commands"; token, body=body)
    parse_response_array(ApplicationCommand, resp)
end

# Guild commands
function get_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, with_localizations::Bool=false)
    query = with_localizations ? ["with_localizations" => "true"] : nothing
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, query,
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(ApplicationCommand, resp)
end

function create_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, body,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

function get_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

function edit_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token, body,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

function delete_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token,
        major_params=["guild_id" => string(guild_id)])
end

function bulk_overwrite_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, body=body,
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(ApplicationCommand, resp)
end

# --- Interaction Responses ---
function create_interaction_response(rl::RateLimiter, interaction_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    discord_post(rl, "/interactions/$(interaction_id)/$(interaction_token)/callback"; token, body, files)
end

function get_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String)
    resp = discord_get(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token)
    parse_response(Message, resp)
end

function edit_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token, body, files)
    parse_response(Message, resp)
end

function delete_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String)
    discord_delete(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token)
end

function create_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    resp = discord_post(rl, "/webhooks/$(application_id)/$(interaction_token)"; token, body, files)
    parse_response(Message, resp)
end

function get_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token)
    parse_response(Message, resp)
end

function edit_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token, body, files)
    parse_response(Message, resp)
end

function delete_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String)
    discord_delete(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token)
end
