# Application REST endpoints

function get_current_application(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/applications/@me"; token)
    JSON3.read(resp.body, Dict{String, Any})
end

function modify_current_application(rl::RateLimiter; token::String, body::Dict)
    resp = discord_patch(rl, "/applications/@me"; token, body)
    JSON3.read(resp.body, Dict{String, Any})
end

# --- Application Role Connection Metadata ---
function get_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String)
    resp = discord_get(rl, "/applications/$(application_id)/role-connections/metadata"; token)
    JSON3.read(resp.body, Vector{Dict{String, Any}})
end

function update_application_role_connection_metadata_records(rl::RateLimiter, application_id::Snowflake; token::String, body::Vector)
    resp = discord_put(rl, "/applications/$(application_id)/role-connections/metadata"; token, body=body)
    JSON3.read(resp.body, Vector{Dict{String, Any}})
end
