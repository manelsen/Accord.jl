# Application REST endpoints

"""
    get_current_application(rl::RateLimiter; token::String) -> Dict{String, Any}

Get the bot's own application information.

Use this when a bot needs to retrieve its application details, such as name,
description, icon, public flags, and interaction endpoint URL. This is useful
for verifying configuration or displaying application information.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/application#get-current-application)
"""
function get_current_application(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/applications/@me"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    modify_current_application(rl::RateLimiter; token::String, body::Dict) -> Dict{String, Any}

Modify the bot's own application settings.

Use this when a bot needs to update its application configuration, such as
description, interaction endpoint URL, flags, or tags. Changes affect how
the application appears to users.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Application fields to update (description, icon, flags, etc.).

# Updatable Fields
- `custom_install_url` — Custom authorization URL
- `description` — Application description
- `icon` — Base64-encoded icon
- `cover_image` — Base64-encoded cover image
- `interactions_endpoint_url` — URL for receiving interactions
- `flags` — Public flags (GATEWAY_PRESENCE_LIMITED, etc.)
- `tags` — Array of tags describing the app

# Errors
- HTTP 400 if any field is invalid.
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/application#edit-current-application)
"""
function modify_current_application(rl::RateLimiter; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/@me"; token, body)
    JSON3.read(resp.body, Dict{String, Any})
end

# --- Application Role Connection Metadata ---

"""
    get_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String) -> Vector{Dict{String, Any}}

Get the role connection metadata records for an application.

Use this when a bot needs to retrieve the configuration for Linked Roles,
which allow users to obtain roles based on external platform data.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Metadata Types
- `INTEGER_LESS_THAN_OR_EQUAL` — Integer ≤ comparison
- `INTEGER_GREATER_THAN_OR_EQUAL` — Integer ≥ comparison
- `INTEGER_EQUAL` — Integer = comparison
- `INTEGER_NOT_EQUAL` — Integer ≠ comparison
- `DATETIME_LESS_THAN_OR_EQUAL` — Unix timestamp ≤ comparison
- `DATETIME_GREATER_THAN_OR_EQUAL` — Unix timestamp ≥ comparison
- `BOOLEAN_EQUAL` — Boolean = comparison
- `BOOLEAN_NOT_EQUAL` — Boolean ≠ comparison

# Errors
- HTTP 401 if the token is invalid.
- HTTP 404 if the application does not exist.

[Discord docs](https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records)
"""
function get_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/role-connections/metadata"; token)
    JSON3.read(resp.body, Vector{Dict{String, Any}})
end

"""
    update_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector) -> Vector{Dict{String, Any}}

Update the role connection metadata records for an application.

Use this when a bot needs to configure Linked Role requirements, defining
what external data can be used to grant roles to users.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `application_id::Snowflake` — The ID of the application.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Vector` — Array of metadata record definitions.

# Record Fields
- `type` — The type of metadata value (INTEGER, BOOLEAN, DATETIME)
- `key` — Unique key for this metadata field
- `name` — Display name for the metadata field
- `name_localizations` — Localized names (optional)
- `description` — Description of the field
- `description_localizations` — Localized descriptions (optional)

# Errors
- HTTP 400 if the metadata configuration is invalid.
- HTTP 401 if the token is invalid.
- HTTP 404 if the application does not exist.

[Discord docs](https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records)
"""
function update_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/role-connections/metadata"; token, body=body)
    JSON3.read(resp.body, Vector{Dict{String, Any}})
end
