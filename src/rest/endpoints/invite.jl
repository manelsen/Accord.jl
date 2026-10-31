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

[Discord docs](https://docs.discord.com/developers/resources/invite#get-invite)
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

[Discord docs](https://docs.discord.com/developers/resources/invite#delete-invite)
"""
function delete_invite(rl::RateLimiter, invite_code::String; token::String, reason=nothing)
    resp = discord_delete(rl, "/invites/$(invite_code)"; token, reason)
    parse_response(Invite, resp)
end

# --- Invite target users ---
#
# An invite can be limited to a list of users ("target users"). Small lists go
# in JSON (`target_user_ids` on creation, the bulk endpoints); any size can be
# sent as a CSV file with one user id per line.

# The `(filename, data, content_type, field)` upload of a list of user ids.
function _target_users_csv(user_ids)
    csv = join((string(Snowflake(id)) for id in user_ids), "\n")
    return ("target_users.csv", Vector{UInt8}(csv), "text/csv", "target_users_file")
end

function _check_bulk_target_users(user_ids)
    length(user_ids) <= 1000 || throw(ArgumentError(
        "At most 1000 user ids per request, got $(length(user_ids)); use update_invite_target_users for more."))
    return Dict("user_ids" => [string(Snowflake(id)) for id in user_ids])
end

"""
    get_invite_target_users(rl::RateLimiter, invite_code::String; token::String) -> Vector{Snowflake}

The users an invite is limited to (Discord sends them as a CSV file).

# Permissions
The invite's creator, `MANAGE_GUILD` or `VIEW_AUDIT_LOG`.

[Discord docs](https://docs.discord.com/developers/resources/invite#get-target-users)
"""
function get_invite_target_users(rl::RateLimiter, invite_code::String; token::String)
    resp = discord_get(rl, "/invites/$(invite_code)/target-users"; token)
    resp.status >= 400 && error("Discord API error ($(resp.status)): $(String(resp.body))")
    lines = filter(!isempty, strip.(split(String(resp.body), '\n')))
    return [Snowflake(String(l)) for l in lines if l != "user_id"]
end

"""
    update_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)

Replace the users an invite is limited to with `user_ids`, of any length.
Discord processes the list in the background; follow it with
[`get_invite_target_users_job_status`](@ref).

# Permissions
The invite's creator or `MANAGE_GUILD`.

[Discord docs](https://docs.discord.com/developers/resources/invite#update-target-users)
"""
function update_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)
    discord_put(rl, "/invites/$(invite_code)/target-users"; token, files=[_target_users_csv(user_ids)])
end

"""
    add_invite_target_user(rl::RateLimiter, invite_code::String, user_id::Snowflake; token::String)

Let one more user accept an invite.

# Permissions
The invite's creator or `MANAGE_GUILD`.

[Discord docs](https://docs.discord.com/developers/resources/invite#add-target-user)
"""
function add_invite_target_user(rl::RateLimiter, invite_code::String, user_id::Snowflake; token::String)
    discord_put(rl, "/invites/$(invite_code)/target-users/$(user_id)"; token)
end

"""
    remove_invite_target_user(rl::RateLimiter, invite_code::String, user_id::Snowflake; token::String)

Take a user off an invite's target users.

# Permissions
The invite's creator or `MANAGE_GUILD`.

[Discord docs](https://docs.discord.com/developers/resources/invite#remove-target-user)
"""
function remove_invite_target_user(rl::RateLimiter, invite_code::String, user_id::Snowflake; token::String)
    discord_delete(rl, "/invites/$(invite_code)/target-users/$(user_id)"; token)
end

"""
    bulk_add_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)

Add up to 1000 users to an invite's target users.

# Permissions
The invite's creator or `MANAGE_GUILD`.

[Discord docs](https://docs.discord.com/developers/resources/invite#bulk-add-target-users)
"""
function bulk_add_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)
    body = _check_bulk_target_users(user_ids)
    discord_post(rl, "/invites/$(invite_code)/target-users/bulk-add"; token, body)
end

"""
    bulk_delete_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)

Remove up to 1000 users from an invite's target users.

# Permissions
The invite's creator or `MANAGE_GUILD`.

[Discord docs](https://docs.discord.com/developers/resources/invite#bulk-delete-target-users)
"""
function bulk_delete_invite_target_users(rl::RateLimiter, invite_code::String, user_ids; token::String)
    body = _check_bulk_target_users(user_ids)
    discord_post(rl, "/invites/$(invite_code)/target-users/bulk-delete"; token, body)
end

"""
    get_invite_target_users_job_status(rl::RateLimiter, invite_code::String; token::String) -> InviteTargetUsersJob

Progress of the background job started by a CSV upload of target users
([`update_invite_target_users`](@ref), or `target_users_file` on
[`create_channel_invite`](@ref)).

# Permissions
The invite's creator, `MANAGE_GUILD` or `VIEW_AUDIT_LOG`.

[Discord docs](https://docs.discord.com/developers/resources/invite#get-target-users-job-status)
"""
function get_invite_target_users_job_status(rl::RateLimiter, invite_code::String; token::String)
    resp = discord_get(rl, "/invites/$(invite_code)/target-users/job-status"; token)
    parse_response(InviteTargetUsersJob, resp)
end
