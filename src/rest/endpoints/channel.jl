# Channel REST endpoints

"""
    get_channel(rl::RateLimiter, channel_id::Snowflake; token::String) -> DiscordChannel

Retrieve a channel by its ID.

This is used when a bot needs to fetch channel information, such as when
processing a command that references a channel or caching channel data.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel to retrieve.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the bot lacks permission to view the channel.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#get-channel)
"""
function get_channel(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    modify_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing) -> DiscordChannel

Update a channel's settings.

Use this when a bot needs to change channel properties like name, topic,
position, or permission overwrites. Requires appropriate permissions based
on the changes being made.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel to modify.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Channel fields to update (name, type, position, topic, etc.).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_CHANNELS` for most modifications. Thread modifications
may require different permissions.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#modify-channel)
"""
function modify_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/channels/$(channel_id)"; token, body, reason, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    delete_channel(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing) -> DiscordChannel

Delete a channel or close a private message.

Use this when a bot needs to remove a channel from a guild or close a DM.
Deleting a guild channel cannot be undone. Deleting a category channel
will also delete all child channels.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel to delete.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_CHANNELS` for guild channels.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#deleteclose-channel)
"""
function delete_channel(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing)
    resp = discord_delete(rl, "/channels/$(channel_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    edit_channel_permissions(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, body::Dict, reason=nothing)

Edit the permission overwrites for a channel.

Use this when a bot needs to grant or restrict permissions for a user or role
in a specific channel. This creates or updates permission overwrites.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.
- `overwrite_id::Snowflake` — The user or role ID to set permissions for.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Permission overwrite data (type, allow, deny bits).
- `reason::String` — Audit log reason for the change (optional).

# Permissions
Requires `MANAGE_ROLES` with the bot's top role higher than the target role
(for role overwrites) or `MANAGE_CHANNELS`.

# Errors
- HTTP 403 if missing required permissions or if the bot's role is too low.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#edit-channel-permissions)
"""
function edit_channel_permissions(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, body::Dict, reason=nothing)
    discord_put(rl, "/channels/$(channel_id)/permissions/$(overwrite_id)"; token, body, reason, major_params=["channel_id" => string(channel_id)])
end

"""
    delete_channel_permission(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, reason=nothing)

Delete a permission overwrite from a channel.

Use this when a bot needs to remove custom permissions for a user or role,
reverting them to the channel's default permission settings.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.
- `overwrite_id::Snowflake` — The user or role ID to remove permissions for.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for the deletion (optional).

# Permissions
Requires `MANAGE_ROLES` with the bot's top role higher than the target role
(for role overwrites) or `MANAGE_CHANNELS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel or overwrite does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#delete-channel-permission)
"""
function delete_channel_permission(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/permissions/$(overwrite_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

"""
    get_channel_invites(rl::RateLimiter, channel_id::Snowflake; token::String) -> Vector{Invite}

Get all invites for a channel.

Use this when a bot needs to list active invites in a channel, such as for
moderation purposes or invite management commands.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_CHANNELS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#get-channel-invites)
"""
function get_channel_invites(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/invites"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Invite, resp)
end

"""
    create_channel_invite(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing) -> Invite

Create a new invite for a channel.

Use this when a bot needs to generate an invite link programmatically,
with specific settings like expiration time or maximum uses.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Invite settings (max_age, max_uses, temporary, unique).
- `reason::String` — Audit log reason for creating the invite (optional).

# Permissions
Requires `CREATE_INSTANT_INVITE`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#create-channel-invite)
"""
function create_channel_invite(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/invites"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
    parse_response(Invite, resp)
end

"""
    follow_announcement_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict) -> Dict{String, Any}

Follow an Announcement Channel to send messages to a target channel.

Use this when a bot needs to set up crossposting from an announcement
channel (news channel) to another channel in a different server.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the announcement channel to follow.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Contains `webhook_channel_id` for the target channel.

# Permissions
Requires `MANAGE_WEBHOOKS` in the target channel's guild.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#follow-announcement-channel)
"""
function follow_announcement_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/channels/$(channel_id)/followers"; token, body, major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    trigger_typing_indicator(rl::RateLimiter, channel_id::Snowflake; token::String)

Trigger the typing indicator in a channel.

Use this when a bot is processing a command and wants to indicate to users
that it is working on a response. The typing indicator lasts for 10 seconds
or until a message is sent.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `SEND_MESSAGES` in the channel.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#trigger-typing-indicator)
"""
function trigger_typing_indicator(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_post(rl, "/channels/$(channel_id)/typing"; token, major_params=["channel_id" => string(channel_id)])
end

"""
    get_pinned_messages(rl::RateLimiter, channel_id::Snowflake; token::String) -> Vector{Message}

Get all pinned messages in a channel.

Use this when a bot needs to display or manage pinned messages, such as
in a pin archive command or pin management utility.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `VIEW_CHANNEL` and `READ_MESSAGE_HISTORY`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#get-pinned-messages)
"""
function get_pinned_messages(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/pins"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Message, resp)
end

"""
    pin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)

Pin a message in a channel.

Use this when a bot needs to pin important messages, such as announcement
messages, rules, or key information that should remain visible.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.
- `message_id::Snowflake` — The ID of the message to pin.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for pinning (optional).

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel or message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#pin-message)
"""
function pin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_put(rl, "/channels/$(channel_id)/pins/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

"""
    unpin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)

Unpin a message in a channel.

Use this when a bot needs to remove a pinned message, such as when
unpinning outdated announcements or managing a limited number of pins.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the channel.
- `message_id::Snowflake` — The ID of the message to unpin.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `reason::String` — Audit log reason for unpinning (optional).

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel, message, or pin does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#unpin-message)
"""
function unpin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/pins/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

# Thread endpoints

"""
    start_thread_from_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, reason=nothing) -> DiscordChannel

Create a new thread from an existing message.

Use this when a bot needs to create a discussion thread around a specific
message, such as for off-topic conversations or detailed discussions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the parent channel (must support threads).
- `message_id::Snowflake` — The ID of the message to start the thread from.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Thread settings (name, auto_archive_duration, rate_limit_per_user).
- `reason::String` — Audit log reason for creating the thread (optional).

# Permissions
Requires `CREATE_PUBLIC_THREADS` for public threads.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel or message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#start-thread-from-message)
"""
function start_thread_from_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/messages/$(message_id)/threads"; token, body, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    start_thread_without_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing) -> DiscordChannel

Create a new thread without an existing message.

Use this when a bot needs to create a standalone thread, such as for
announcements, support tickets, or scheduled discussions.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the parent channel (must support threads).

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Thread settings (name, type, auto_archive_duration, etc.).
- `reason::String` — Audit log reason for creating the thread (optional).

# Permissions
Requires `CREATE_PUBLIC_THREADS` for public threads or `CREATE_PRIVATE_THREADS`
for private threads.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#start-thread-without-message)
"""
function start_thread_without_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/threads"; token, body, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    start_thread_in_forum(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, files=nothing, reason=nothing) -> DiscordChannel

Create a new post in a forum channel.

Use this when a bot needs to create a forum post with optional attachments,
such as for automated announcements, support tickets, or content sharing.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the forum channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `body::Dict` — Post settings (name, message, applied_tags).
- `files` — File attachments for the post (optional).
- `reason::String` — Audit log reason for creating the post (optional).

# Permissions
Requires `SEND_MESSAGES` in the forum channel.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#start-thread-in-forum-channel)
"""
function start_thread_in_forum(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, files=nothing, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/threads"; token, body, files, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

"""
    join_thread(rl::RateLimiter, channel_id::Snowflake; token::String)

Add the bot user to a thread.

Use this when a bot needs to join a thread to send messages or receive
events from it, such as when participating in a conversation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread (threads are also channels).

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 403 if the thread is private and the bot wasn't added.
- HTTP 404 if the thread does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#join-thread)
"""
function join_thread(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_put(rl, "/channels/$(channel_id)/thread-members/@me"; token, major_params=["channel_id" => string(channel_id)])
end

"""
    add_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)

Add another user to a thread.

Use this when a bot needs to add a specific user to a thread, such as for
moderation purposes or bringing someone into a conversation.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread.
- `user_id::Snowflake` — The ID of the user to add.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_THREADS` to add members to private threads.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the thread or user does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#add-thread-member)
"""
function add_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)
    discord_put(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, major_params=["channel_id" => string(channel_id)])
end

"""
    leave_thread(rl::RateLimiter, channel_id::Snowflake; token::String)

Remove the bot user from a thread.

Use this when a bot no longer needs to participate in a thread or when
cleaning up thread memberships.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Errors
- HTTP 404 if the thread does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#leave-thread)
"""
function leave_thread(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/thread-members/@me"; token, major_params=["channel_id" => string(channel_id)])
end

"""
    remove_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)

Remove a user from a thread.

Use this when a bot needs to remove someone from a thread, such as for
moderation purposes or managing private thread access.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread.
- `user_id::Snowflake` — The ID of the user to remove.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Permissions
Requires `MANAGE_THREADS` to remove members from private threads.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the thread or user does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#remove-thread-member)
"""
function remove_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, major_params=["channel_id" => string(channel_id)])
end

"""
    get_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String, with_member::Bool=false) -> ThreadMember

Get a thread member object for a user.

Use this when a bot needs to check a user's thread membership status or
retrieve their thread-specific member information.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread.
- `user_id::Snowflake` — The ID of the user.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_member::Bool` — Include guild member data in the response.

# Permissions
Requires `MANAGE_THREADS` for private threads.

# Errors
- HTTP 403 if missing required permissions (for private threads).
- HTTP 404 if the thread or user does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#get-thread-member)
"""
function get_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String, with_member::Bool=false)
    query = with_member ? ["with_member" => "true"] : nothing
    resp = discord_get(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response(ThreadMember, resp)
end

"""
    list_thread_members(rl::RateLimiter, channel_id::Snowflake; token::String, with_member::Bool=false, limit::Int=100) -> Vector{ThreadMember}

Get all members of a thread.

Use this when a bot needs to list participants in a thread, such as for
thread management or notification purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the thread.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `with_member::Bool` — Include guild member data for each member.
- `limit::Int` — Maximum number of members to return (1-100, default 100).

# Permissions
Requires `MANAGE_THREADS` for private threads.

# Errors
- HTTP 403 if missing required permissions (for private threads).
- HTTP 404 if the thread does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#list-thread-members)
"""
function list_thread_members(rl::RateLimiter, channel_id::Snowflake; token::String, with_member::Bool=false, limit::Int=100)
    query = ["limit" => string(limit)]
    with_member && push!(query, "with_member" => "true")
    resp = discord_get(rl, "/channels/$(channel_id)/thread-members"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response_array(ThreadMember, resp)
end

"""
    list_public_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50) -> Dict{String, Any}

Get archived public threads in a channel.

Use this when a bot needs to browse or search through archived public threads,
such as for thread discovery or archival features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the parent channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum threads to return (default 50).

# Errors
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#list-public-archived-threads)
"""
function list_public_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/threads/archived/public"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    list_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50) -> Dict{String, Any}

Get archived private threads in a channel.

Use this when a bot needs to browse private archived threads that the bot
has access to, such as for moderation or content management.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the parent channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum threads to return (default 50).

# Permissions
Requires `MANAGE_THREADS`.

# Errors
- HTTP 403 if missing required permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#list-private-archived-threads)
"""
function list_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/threads/archived/private"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    list_joined_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50) -> Dict{String, Any}

Get archived private threads that the bot has joined in a channel.

Use this when a bot needs to list private threads it has access to through
membership, such as for thread management or notification purposes.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.
- `channel_id::Snowflake` — The ID of the parent channel.

# Keyword Arguments
- `token::String` — Bot authentication token.
- `limit::Int` — Maximum threads to return (default 50).

# Errors
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads)
"""
function list_joined_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/users/@me/threads/archived/private"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end
