# Scheduled Event REST endpoints

"""
    list_scheduled_events(rl::RateLimiter, guild_id::Snowflake; token::String, with_user_count::Bool=false) -> Vector{ScheduledEvent}

Get all scheduled events for a guild.

Use this when a bot needs to list guild events, such as for event calendars,
upcoming event notifications, or event management commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_user_count::Bool` — Include subscriber count for each event.

# Permissions
- Requires `VIEW_CHANNEL` to see entity-associated events.
- Some event types may require additional permissions.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild)
"""
function list_scheduled_events(rl::RateLimiter, guild_id::Snowflake; token::String, with_user_count::Bool=false)
    query = with_user_count ? ["with_user_count" => "true"] : nothing
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response_array(ScheduledEvent, resp)
end

"""
    create_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing) -> ScheduledEvent

Create a new scheduled event in a guild.

Use this when a bot needs to create events programmatically, such as for
event management systems, integration with external calendars, or automated
scheduled activities.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Event data (name, description, scheduled_start_time, entity_type, etc.).
- `reason::String` — Audit log reason for the creation (optional).

# Permissions
Requires `MANAGE_EVENTS` or `ADMINISTRATOR`.

# Event Types
- `1` (STAGE_INSTANCE) — Stage channel event
- `2` (VOICE) — Voice channel event
- `3` (EXTERNAL) — External event (URL-based)

# Errors
- HTTP 400 if the event data is invalid.
- HTTP 403 if missing required permissions.
- HTTP 404 if the guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event)
"""
function create_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/guilds/$(guild_id)/scheduled-events"; token, body, reason=reason, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

"""
    get_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, with_user_count::Bool=false) -> ScheduledEvent

Get a specific scheduled event.

Use this when a bot needs to retrieve event details, such as for displaying
event information or checking event status.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `event_id::Snowflake` — The ID of the event.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_user_count::Bool` — Include subscriber count.

# Permissions
- Requires `VIEW_CHANNEL` to see entity-associated events.

# Errors
- HTTP 404 if the event or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event)
"""
function get_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, with_user_count::Bool=false)
    query = with_user_count ? ["with_user_count" => "true"] : nothing
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, query, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

"""
    modify_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, body::Dict, reason=nothing) -> ScheduledEvent

Modify a scheduled event.

Use this when a bot needs to update event details, such as changing the
time, location, description, or status of an event.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `event_id::Snowflake` — The ID of the event to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Updated event fields.
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_EVENTS` or `ADMINISTRATOR`.

# Errors
- HTTP 400 if the event data is invalid.
- HTTP 403 if missing required permissions or not the event creator.
- HTTP 404 if the event or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event)
"""
function modify_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, body, reason, major_params=["guild_id" => string(guild_id)])
    parse_response(ScheduledEvent, resp)
end

"""
    delete_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String)

Delete a scheduled event.

Use this when a bot needs to cancel or remove events, such as for event
management or cleanup systems.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `event_id::Snowflake` — The ID of the event to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_EVENTS` or `ADMINISTRATOR`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the event or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event)
"""
function delete_guild_scheduled_event(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String)
    discord_delete(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)"; token, major_params=["guild_id" => string(guild_id)])
end

"""
    get_guild_scheduled_event_users(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, limit::Int=100, with_member::Bool=false) -> Dict{String, Any}

Get users subscribed to a scheduled event.

Use this when a bot needs to list event attendees, such as for attendance
tracking, reminder systems, or capacity management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `guild_id::Snowflake` — The ID of the guild.
- `event_id::Snowflake` — The ID of the event.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum users to return (1-100, default 100).
- `with_member::Bool` — Include guild member data for each user.

# Permissions
Requires `MANAGE_EVENTS` or `ADMINISTRATOR`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the event or guild does not exist.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users)
"""
function get_guild_scheduled_event_users(rl::RateLimiter, guild_id::Snowflake, event_id::Snowflake; token::String, limit::Int=100, with_member::Bool=false)
    query = ["limit" => string(limit)]
    with_member && push!(query, "with_member" => "true")
    resp = discord_get(rl, "/guilds/$(guild_id)/scheduled-events/$(event_id)/users"; token, query, major_params=["guild_id" => string(guild_id)])
    JSON3.read(resp.body, Dict{String, Any})
end
