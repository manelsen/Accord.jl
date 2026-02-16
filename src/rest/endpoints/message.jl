# Message REST endpoints

"""
    get_channel_messages(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50, around=nothing, before=nothing, after=nothing) -> Vector{Message}

Retrieve a list of messages from a channel.

Use this to fetch message history for logs, analysis, or context.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `limit::Int`: Max number of messages to return (1-100, default 50).
- `around::Snowflake`: Get messages around this message ID.
- `before::Snowflake`: Get messages before this message ID.
- `after::Snowflake`: Get messages after this message ID.

# Permissions
Requires `VIEW_CHANNEL` and `READ_MESSAGE_HISTORY`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the channel does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#get-channel-messages)
"""
function get_channel_messages(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50, around=nothing, before=nothing, after=nothing)
    query = ["limit" => string(limit)]
    !isnothing(around) && push!(query, "around" => string(around))
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/channels/$(channel_id)/messages"; token, query, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Message, resp)
end

"""
    get_channel_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String) -> Message

Retrieve a specific message.

Use this to get the current state of a message, including updated edits or reactions.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `READ_MESSAGE_HISTORY`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the channel or message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#get-channel-message)
"""
function get_channel_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

"""
    create_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), files=nothing) -> Message

Send a message to a channel.

Use this to post content, embeds, or files to a text channel or DM.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `body::Dict`: JSON body containing `content`, `embeds`, `components`, etc.
- `files`: Vector of `File` objects or pairs for attachments.

# Permissions
Requires `SEND_MESSAGES`.
Requires `SEND_TTS_MESSAGES` if `tts` is true.

# Errors
- HTTP 403 if missing permissions (e.g. strict channel overwrites).
- HTTP 404 if the channel does not exist.
- HTTP 400 if the message is empty or invalid.

[Discord docs](https://discord.com/developers/docs/resources/message#create-message)
"""
function create_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), files=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/messages"; token, body, files, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

"""
    crosspost_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String) -> Message

Publish a message from an Announcement Channel.

Use this to push a message to all guilds that follow the announcement channel.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the announcement channel.
- `message_id::Snowflake`: The ID of the message to publish.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `SEND_MESSAGES` and `MANAGE_MESSAGES` (or `SEND_MESSAGES` if it's your own message).
Actually, for crossposting, it requires `SEND_MESSAGES` in the channel.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#crosspost-message)
"""
function crosspost_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/messages/$(message_id)/crosspost"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

"""
    edit_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, files=nothing) -> Message

Edit a previously sent message.

Use this to update the content, embeds, or components of a message.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `body::Dict`: Fields to update. Set fields to `nothing` (null) to remove them.
- `files`: New attachments to append or replace.

# Permissions
Requires `MANAGE_MESSAGES` if editing another user's message (which is generally not possible for content, only flags/suppression).
You can always edit your own messages.

# Errors
- HTTP 403 if you try to edit someone else's message.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#edit-message)
"""
function edit_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, body, files, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

"""
    delete_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)

Delete a message.

Use this to remove a message permanently.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `reason::String`: Audit log reason.

# Permissions
Requires `MANAGE_MESSAGES` to delete other users' messages.
You can always delete your own messages.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#delete-message)
"""
function delete_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

"""
    bulk_delete_messages(rl::RateLimiter, channel_id::Snowflake; token::String, message_ids::Vector{Snowflake}, reason=nothing)

Delete multiple messages in a single request.

Use this for moderation to quickly clear chat history. Can only delete messages
that are less than 14 weeks old.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `message_ids::Vector{Snowflake}`: List of message IDs to delete (2-100).
- `reason::String`: Audit log reason.

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 400 if deleting < 2 or > 100 messages, or if messages are too old.

[Discord docs](https://discord.com/developers/docs/resources/message#bulk-delete-messages)
"""
function bulk_delete_messages(rl::RateLimiter, channel_id::Snowflake; token::String, message_ids::Vector{Snowflake}, reason=nothing)
    body = Dict("messages" => [string(id) for id in message_ids])
    discord_post(rl, "/channels/$(channel_id)/messages/bulk-delete"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
end

# Reactions

"""
    create_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)

Add a reaction to a message.

Use this to react with a unicode emoji (e.g., "👍") or a custom guild emoji.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `emoji::String`: The emoji to react with. For custom emojis, use `name:id`.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `READ_MESSAGE_HISTORY` and `ADD_REACTIONS`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#create-reaction)
"""
function create_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_put(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token,
        major_params=["channel_id" => string(channel_id)])
end

"""
    delete_own_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)

Remove the bot's own reaction.

Use this to undo a reaction added by the bot.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `emoji::String`: The emoji to remove.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Errors
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#delete-own-reaction)
"""
function delete_own_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token,
        major_params=["channel_id" => string(channel_id)])
end

"""
    delete_user_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String, user_id::Snowflake; token::String)

Remove a user's reaction.

Use this for moderation to remove inappropriate reactions.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `emoji::String`: The emoji to remove.
- `user_id::Snowflake`: The ID of the user whose reaction to remove.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message or user does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#delete-user-reaction)
"""
function delete_user_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String, user_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/$(user_id)"; token,
        major_params=["channel_id" => string(channel_id)])
end

"""
    get_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String, limit::Int=25, type::Int=0) -> Vector{User}

Get a list of users that reacted with an emoji.

Use this to see who voted or reacted.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `emoji::String`: The emoji to check.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `limit::Int`: Max number of users to return (1-100, default 25).
- `type::Int`: 0 = normal, 1 = burst.

# Errors
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#get-reactions)
"""
function get_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String, limit::Int=25, type::Int=0)
    query = ["limit" => string(limit)]
    type > 0 && push!(query, "type" => string(type))
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response_array(User, resp)
end

"""
    delete_all_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)

Remove all reactions from a message.

Use this to clear a message of all emoji reactions.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#delete-all-reactions)
"""
function delete_all_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions"; token,
        major_params=["channel_id" => string(channel_id)])
end

"""
    delete_all_reactions_for_emoji(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)

Remove all reactions for a specific emoji.

Use this to clear all votes for a single option or remove a specific emoji entirely.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `emoji::String`: The emoji to remove.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `MANAGE_MESSAGES`.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji)
"""
function delete_all_reactions_for_emoji(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token,
        major_params=["channel_id" => string(channel_id)])
end

# Polls

"""
    get_answer_voters(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, answer_id::Int; token::String, limit::Int=25) -> Dict

Get users who voted for a specific poll answer.

Use this to retrieve poll results.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.
- `answer_id::Int`: The ID of the answer choice (1-based index usually, but check Poll object).

# Keyword Arguments
- `token::String`: Bot authentication token.
- `limit::Int`: Max number of users to return.

# Errors
- HTTP 404 if the message or answer does not exist.

[Discord docs](https://discord.com/developers/docs/resources/poll#get-answer-voters)
"""
function get_answer_voters(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, answer_id::Int; token::String, limit::Int=25)
    resp = discord_get(rl, "/channels/$(channel_id)/polls/$(message_id)/answers/$(answer_id)"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

"""
    end_poll(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String) -> Message

Immediately end a poll.

Use this to close voting on a poll before its scheduled duration.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.
- `message_id::Snowflake`: The ID of the message.

# Keyword Arguments
- `token::String`: Bot authentication token.

# Permissions
Requires `MANAGE_MESSAGES` (if not the author).
Always allowed if you are the author.

# Errors
- HTTP 403 if missing permissions.
- HTTP 404 if the message does not exist.

[Discord docs](https://discord.com/developers/docs/resources/poll#end-poll)
"""
function end_poll(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/polls/$(message_id)/expire"; token,
        major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end
