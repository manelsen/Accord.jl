# Invite REST endpoints

"""
    get_invite(rl::RateLimiter, invite_code::String; token::String, with_counts::Bool=false, with_expiration::Bool=false, guild_scheduled_event_id=nothing) -> Invite

Get an invite by its code.

Use this when a bot needs to retrieve invite information, such as for
validating invite links, checking expiration, or getting guild/channel info.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `invite_code::String` — The invite code (e.g., "abc123").

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_counts::Bool` — Include approximate member and presence counts.
- `with_expiration::Bool` — Include expiration timestamp.
- `guild_scheduled_event_id` — Include guild scheduled event information.

# Errors
- HTTP 404 if the invite does not exist or has expired.

[Discord docs](https://discord.com/developers/docs/resources/invite#get-invite)
"""
function get_invite(rl::RateLimiter, invite_code::String; token::String, with_counts::Bool=false, with_expiration::Bool=false, guild_scheduled_event_id=nothing)
    query = Pair{String,String}[]
    with_counts && push!(query, "with_counts" => "true")
    with_expiration && push!(query, "with_expiration" => "true")
    !isnothing(guild_scheduled_event_id) && push!(query, "guild_scheduled_event_id" => string(guild_scheduled_event_id))
    resp = discord_get(rl, "/invites/$(invite_code)"; token, query=isempty(query) ? nothing : query)
    parse_response(Invite, resp)
end

"""
    delete_invite(rl::RateLimiter, invite_code::String; token::String, reason=nothing) -> Invite

Delete/revoke an invite.

Use this when a bot needs to revoke invite links, such as for moderation
purposes, invite rotation systems, or security measures.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `invite_code::String` — The invite code to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_CHANNELS` in the invite's channel or `MANAGE_GUILD` for
any invite in the guild.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the invite does not exist.

[Discord docs](https://discord.com/developers/docs/resources/invite#delete-invite)
"""
function delete_invite(rl::RateLimiter, invite_code::String; token::String, reason=nothing)
    resp = discord_delete(rl, "/invites/$(invite_code)"; token, reason)
    parse_response(Invite, resp)
end
