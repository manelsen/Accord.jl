# Stage Instance REST endpoints

"""
    create_stage_instance(rl::RateLimiter; token::String, body::Dict, reason=nothing) -> StageInstance

Create a new Stage instance.

Use this when a bot needs to start a Stage event programmatically, such as
for scheduled stage events or automated broadcast systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Stage instance data (channel_id, topic, privacy_level, send_start_notification).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_CHANNELS` and `MOVE_MEMBERS` in the Stage channel.

# Privacy Levels
- `1` (PUBLIC) — Stage visible to everyone
- `2` (GUILD_ONLY) — Stage visible only to guild members

# Errors
- HTTP 400 if the stage data is invalid or channel is not a Stage channel.
- HTTP 403 if missing required permissions.
- HTTP 409 if a stage instance already exists for this channel.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#create-stage-instance)
"""
function create_stage_instance(rl::RateLimiter; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/stage-instances"; token, body, reason=reason)
    parse_response(StageInstance, resp)
end

"""
    get_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String) -> StageInstance

Get the Stage instance for a Stage channel.

Use this when a bot needs to retrieve information about an active Stage,
such as the topic, privacy level, or associated guild scheduled event.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the Stage channel.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if no stage instance exists for this channel.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#get-stage-instance)
"""
function get_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/stage-instances/$(channel_id)"; token)
    parse_response(StageInstance, resp)
end

"""
    modify_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing) -> StageInstance

Modify a Stage instance.

Use this when a bot needs to update the topic, privacy level, or other
properties of an active Stage.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the Stage channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated stage fields (topic, privacy_level).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_CHANNELS` and `MOVE_MEMBERS` in the Stage channel.

# Errors
- HTTP 400 if the stage data is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if no stage instance exists for this channel.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance)
"""
function modify_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/stage-instances/$(channel_id)"; token, body, reason)
    parse_response(StageInstance, resp)
end

"""
    delete_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing)

Delete a Stage instance (close the Stage).

Use this when a bot needs to end a Stage event, such as after a scheduled
event concludes or for moderation purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the Stage channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_CHANNELS` and `MOVE_MEMBERS` in the Stage channel.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if no stage instance exists for this channel.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance)
"""
function delete_stage_instance(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/stage-instances/$(channel_id)"; token, reason)
end
