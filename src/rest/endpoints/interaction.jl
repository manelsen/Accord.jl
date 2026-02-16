# Interaction & Application Command REST endpoints

# --- Application Commands ---

"""
    get_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, with_localizations::Bool=false) -> Vector{ApplicationCommand}

Get all global application commands for the bot.

Use this when a bot needs to list or sync its global slash commands. Global
commands are available in all guilds and take up to an hour to propagate.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_localizations::Bool` — Include name and description localizations.

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the application does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands)
"""
function get_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, with_localizations::Bool=false)
    query = with_localizations ? ["with_localizations" => "true"] : nothing
    resp = discord_get(rl, "/applications/$(application_id)/commands"; token, query)
    parse_response_array(ApplicationCommand, resp)
end

"""
    create_global_application_command(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict) -> ApplicationCommand

Create a new global application command.

Use this when a bot needs to register a new global slash command, context
menu command, or autocomplete command.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Command definition (name, description, type, options, etc.).

# Errors
- HTTP 400 if the command data is invalid or name/description requirements not met.
- HTTP 401 if the token is invalid.
- HTTP 429 if too many commands created (limit is 100 global commands).

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#create-global-application-command)
"""
function create_global_application_command(rl::RateLimiter, application_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/commands"; token, body)
    parse_response(ApplicationCommand, resp)
end

"""
    get_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String) -> ApplicationCommand

Get a specific global application command.

Use this when a bot needs to retrieve details of a specific global command,
such as for editing or inspection.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `command_id::Snowflake` — The ID of the command.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-global-application-command)
"""
function get_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/commands/$(command_id)"; token)
    parse_response(ApplicationCommand, resp)
end

"""
    edit_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String, body::Dict) -> ApplicationCommand

Edit a global application command.

Use this when a bot needs to update an existing global command's name,
description, options, or other properties.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `command_id::Snowflake` — The ID of the command to edit.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated command fields.

# Errors
- HTTP 400 if the updated data is invalid.
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command)
"""
function edit_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/commands/$(command_id)"; token, body)
    parse_response(ApplicationCommand, resp)
end

"""
    delete_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String)

Delete a global application command.

Use this when a bot needs to remove a global command. Deletion is
irreversible and will immediately remove the command from all guilds.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `command_id::Snowflake` — The ID of the command to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command)
"""
function delete_global_application_command(rl::RateLimiter, application_id::Snowflake, command_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/commands/$(command_id)"; token)
end

"""
    bulk_overwrite_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector) -> Vector{ApplicationCommand}

Replace all global application commands with a new set.

Use this when a bot needs to perform a complete command sync, such as during
startup or when updating all commands at once. This is more efficient than
creating commands individually.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Vector` — Array of command definitions to set.

# Errors
- HTTP 400 if any command data is invalid.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands)
"""
function bulk_overwrite_global_application_commands(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/commands"; token, body=body)
    parse_response_array(ApplicationCommand, resp)
end

# Guild commands

"""
    get_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, with_localizations::Bool=false) -> Vector{ApplicationCommand}

Get all application commands for a specific guild.

Use this when a bot needs to list guild-specific commands, which take
precedence over global commands in that guild.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_localizations::Bool` — Include name and description localizations.

# Permissions
Requires `VIEW_CHANNEL` in the guild.

# Errors
- HTTP 403 if the bot is not in the guild.
- HTTP 404 if the guild or application does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands)
"""
function get_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, with_localizations::Bool=false)
    query = with_localizations ? ["with_localizations" => "true"] : nothing
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, query,
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(ApplicationCommand, resp)
end

"""
    create_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Dict) -> ApplicationCommand

Create a guild-specific application command.

Use this when a bot needs to register a command that is only available in
a specific guild. Guild commands are available immediately (no propagation delay).

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Command definition.

# Permissions
Requires `VIEW_CHANNEL` in the guild.

# Errors
- HTTP 400 if the command data is invalid.
- HTTP 403 if the bot is not in the guild.
- HTTP 429 if too many commands created (limit is 100 guild commands).

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command)
"""
function create_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, body,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

"""
    get_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String) -> ApplicationCommand

Get a specific guild application command.

Use this when a bot needs to retrieve details of a guild-specific command.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.
- `command_id::Snowflake` — The ID of the command.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command)
"""
function get_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

"""
    edit_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String, body::Dict) -> ApplicationCommand

Edit a guild-specific application command.

Use this when a bot needs to update a guild command's properties.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.
- `command_id::Snowflake` — The ID of the command to edit.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated command fields.

# Errors
- HTTP 400 if the updated data is invalid.
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command)
"""
function edit_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token, body,
        major_params=["guild_id" => string(guild_id)])
    parse_response(ApplicationCommand, resp)
end

"""
    delete_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)

Delete a guild-specific application command.

Use this when a bot needs to remove a guild command. Changes are immediate.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.
- `command_id::Snowflake` — The ID of the command to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the command does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command)
"""
function delete_guild_application_command(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)
    discord_delete(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)"; token,
        major_params=["guild_id" => string(guild_id)])
end

"""
    bulk_overwrite_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Vector) -> Vector{ApplicationCommand}

Replace all guild application commands with a new set.

Use this when a bot needs to perform a complete guild command sync. This is
more efficient than updating commands individually and takes effect immediately.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Vector` — Array of command definitions to set.

# Errors
- HTTP 400 if any command data is invalid.
- HTTP 403 if the bot is not in the guild.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands)
"""
function bulk_overwrite_guild_application_commands(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands"; token, body=body,
        major_params=["guild_id" => string(guild_id)])
    parse_response_array(ApplicationCommand, resp)
end

# --- Interaction Responses ---

"""
    create_interaction_response(rl::RateLimiter, interaction_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)

Send a response to an interaction.

Use this when a bot needs to respond to a slash command, button press, select
menu choice, or modal submission. Must be sent within 3 seconds of receiving
the interaction.

!!! warning
    This endpoint bypasses the rate limiter to meet the 3-second Discord timeout.

# Arguments
- `rl::RateLimiter` — The rate limiter instance (not used for throttling).
- `interaction_id::Snowflake` — The ID of the interaction.
- `interaction_token::String` — The interaction token from the gateway event.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Response data (type, content, embeds, components, etc.).
- `files` — File attachments (optional).

# Response Types
- `1` — Pong (for ping)
- `4` — Channel message with source
- `5` — Deferred channel message with source
- `6` — Deferred update message (for components)
- `7` — Update message (for components)
- `9` — Application command autocomplete result
- `10` — Modal

# Errors
- HTTP 400 if the response data is invalid.
- HTTP 401 if the interaction token is invalid.
- HTTP 429 if responding too frequently to the same interaction.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response)
"""
function create_interaction_response(rl::RateLimiter, interaction_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    url = "$(API_BASE)/interactions/$(interaction_id)/$(interaction_token)/callback"
    headers = [
        "Authorization" => token,
        "Content-Type" => "application/json",
        "User-Agent" => USER_AGENT,
    ]
    HTTP.post(url, headers, JSON3.write(body); status_exception=false, retry=false)
end

"""
    get_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String) -> Message

Get the original response message for an interaction.

Use this when a bot needs to fetch the message that was sent as the initial
interaction response, such as for editing or reference.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if no response message exists.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response)
"""
function get_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String)
    resp = discord_get(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token)
    parse_response(Message, resp)
end

"""
    edit_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing) -> Message

Edit the original response message for an interaction.

Use this when a bot needs to update the message that was sent as the initial
response, such as to show updated information or results.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated message content.
- `files` — New file attachments (optional).

# Errors
- HTTP 400 if the message data is invalid.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response)
"""
function edit_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token, body, files)
    parse_response(Message, resp)
end

"""
    delete_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String)

Delete the original response message for an interaction.

Use this when a bot needs to remove the message that was sent as the
initial response.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response)
"""
function delete_original_interaction_response(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String)
    discord_delete(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/@original"; token)
end

"""
    create_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing) -> Message

Create a followup message for an interaction.

Use this when a bot needs to send additional messages after the initial
response, such as for multi-step interactions or additional notifications.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Message content.
- `files` — File attachments (optional).

# Errors
- HTTP 400 if the message data is invalid.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message)
"""
function create_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String; token::String, body::Dict, files=nothing)
    resp = discord_post(rl, "/webhooks/$(application_id)/$(interaction_token)"; token, body, files)
    parse_response(Message, resp)
end

"""
    get_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String) -> Message

Get a specific followup message for an interaction.

Use this when a bot needs to retrieve a previously sent followup message.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.
- `message_id::Snowflake` — The ID of the followup message.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message)
"""
function get_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token)
    parse_response(Message, resp)
end

"""
    edit_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing) -> Message

Edit a followup message for an interaction.

Use this when a bot needs to update a previously sent followup message,
such as to correct information or show updated status.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.
- `message_id::Snowflake` — The ID of the followup message to edit.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated message content.
- `files` — New file attachments (optional).

# Errors
- HTTP 400 if the message data is invalid.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message)
"""
function edit_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token, body, files)
    parse_response(Message, resp)
end

"""
    delete_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String)

Delete a followup message for an interaction.

Use this when a bot needs to remove a previously sent followup message.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `interaction_token::String` — The interaction token.
- `message_id::Snowflake` — The ID of the followup message to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message)
"""
function delete_followup_message(rl::RateLimiter, application_id::Snowflake, interaction_token::String, message_id::Snowflake; token::String)
    discord_delete(rl, "/webhooks/$(application_id)/$(interaction_token)/messages/$(message_id)"; token)
end

# --- Application Command Permissions ---

"""
    get_guild_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String) -> Vector{Dict{String, Any}}

Get permissions for all commands in a guild.

Use this when a bot needs to list command permission overwrites for a guild,
showing which roles and users can use specific commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `ADMINISTRATOR` or application ownership.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild or application does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions)
"""
function get_guild_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/permissions"; token,
        major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Vector{Dict{String, Any}})
end

"""
    get_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String) -> Dict{String, Any}

Get permissions for a specific command in a guild.

Use this when a bot needs to check the permission overwrites for a specific
guild command.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.
- `command_id::Snowflake` — The ID of the command.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `ADMINISTRATOR` or application ownership.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the command or guild does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions)
"""
function get_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)/permissions"; token,
        major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    edit_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String, body::Dict) -> Dict{String, Any}

Edit permissions for a specific command in a guild.

Use this when a bot needs to restrict or grant command access to specific
roles or users in a guild.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.
- `guild_id::Snowflake` — The ID of the guild.
- `command_id::Snowflake` — The ID of the command.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Permission overwrites array.

# Permissions
Requires `ADMINISTRATOR`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the command or guild does not exist.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions)
"""
function edit_application_command_permissions(rl::RateLimiter, application_id::Snowflake, guild_id::Snowflake, command_id::Snowflake; token::String, body::Dict)
    resp = discord_put(rl, "/applications/$(application_id)/guilds/$(guild_id)/commands/$(command_id)/permissions"; token, body,
        major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end
