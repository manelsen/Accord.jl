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

[Discord docs](https://docs.discord.com/developers/resources/message#get-channel-messages)
"""
function get_channel_messages(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50, around=nothing, before=nothing, after=nothing)
    query = ["limit" => string(limit)]
    !isnothing(around) && push!(query, "around" => string(around))
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/channels/$(channel_id)/messages"; token, query)
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

[Discord docs](https://docs.discord.com/developers/resources/message#get-channel-message)
"""
function get_channel_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)"; token)
    parse_response(Message, resp)
end

# Query parameters of Search Guild Messages (besides `limit`)
const _SEARCH_FILTERS = (
    :content, :offset, :max_id, :min_id, :slop, :channel_id, :author_type, :author_id,
    :mentions, :mentions_role_id, :mention_everyone, :replied_to_user_id,
    :replied_to_message_id, :pinned, :has, :embed_type, :embed_provider, :link_hostname,
    :attachment_filename, :attachment_extension, :sort_by, :sort_order, :include_nsfw,
)

"""
    search_guild_messages(rl::RateLimiter, guild_id::Snowflake; token::String, limit::Int=25, retries::Int=3, filters...) -> MessageSearchResults

Search a guild's messages, as the search bar in Discord's client does.

Filters are keyword arguments named after Discord's query parameters. Those that
take several values accept a vector, and `has` and `author_type` values can be
negated with a leading `-`:

- `content` (text, up to 1024 characters), `slop` (word distance, default 2)
- `author_id`, `author_type` (`"user"`, `"bot"`, `"webhook"`), `channel_id`
- `mentions`, `mentions_role_id`, `mention_everyone`, `replied_to_user_id`,
  `replied_to_message_id`, `pinned`
- `has` (`"image"`, `"sound"`, `"video"`, `"file"`, `"sticker"`, `"embed"`,
  `"link"`, `"poll"`, `"snapshot"`), `embed_type`, `embed_provider`,
  `link_hostname`, `attachment_filename`, `attachment_extension`
- `min_id`, `max_id` (message ids to search after or before)
- `sort_by` (`"timestamp"` or `"relevance"`), `sort_order` (`"desc"` or `"asc"`),
  `include_nsfw`
- `offset` (up to 9975) and `limit` (1–25) for paging

When Discord has not finished indexing the guild it answers 202 without results;
the search is retried up to `retries` times, waiting as long as Discord asks.
If it is still not ready, the results are empty and `retry_after` is set.

# Permissions
Requires `READ_MESSAGE_HISTORY`, and the Message Content intent to search message text.

# Example
```julia
results = Accord.search_guild_messages(client, guild_id; content="release notes",
                                       author_type="-bot", has=["link"])
for msg in Accord.found_messages(results)
    println(msg.channel_id, ": ", msg.content)
end
```

[Discord docs](https://docs.discord.com/developers/resources/message#search-guild-messages)
"""
function search_guild_messages(rl::RateLimiter, guild_id::Snowflake; token::String,
                               limit::Int=25, retries::Int=3, filters...)
    query = Pair{String, String}["limit" => string(limit)]
    for (k, v) in pairs(filters)
        k in _SEARCH_FILTERS || throw(ArgumentError(
            "Unknown search filter `$k`. Expected one of: $(join(_SEARCH_FILTERS, ", "))."))
        isnothing(v) && continue
        # A filter with several values repeats the parameter
        for x in (v isa AbstractVector ? v : (v,))
            push!(query, string(k) => string(x))
        end
    end
    for attempt in 0:retries
        resp = discord_get(rl, "/guilds/$(guild_id)/messages/search"; token, query)
        results = parse_response(MessageSearchResults, resp)
        resp.status == 202 || return results
        wait_s = coalesce(results.retry_after, 0.0)
        if attempt == retries
            results.retry_after = wait_s
            return results
        end
        sleep(wait_s > 0 ? wait_s : 1.0)
    end
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

[Discord docs](https://docs.discord.com/developers/resources/message#create-message)
"""
function create_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), files=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/messages"; token, body, files)
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

[Discord docs](https://docs.discord.com/developers/resources/message#crosspost-message)
"""
function crosspost_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/messages/$(message_id)/crosspost"; token)
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

[Discord docs](https://docs.discord.com/developers/resources/message#edit-message)
"""
function edit_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, body, files)
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

[Discord docs](https://docs.discord.com/developers/resources/message#delete-message)
"""
function delete_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, reason)
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

[Discord docs](https://docs.discord.com/developers/resources/message#bulk-delete-messages)
"""
function bulk_delete_messages(rl::RateLimiter, channel_id::Snowflake; token::String, message_ids::Vector{Snowflake}, reason=nothing)
    body = Dict("messages" => [string(id) for id in message_ids])
    discord_post(rl, "/channels/$(channel_id)/messages/bulk-delete"; token, body, reason=reason)
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

[Discord docs](https://docs.discord.com/developers/resources/message#create-reaction)
"""
function create_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_put(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token)
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

[Discord docs](https://docs.discord.com/developers/resources/message#delete-own-reaction)
"""
function delete_own_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token)
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

[Discord docs](https://docs.discord.com/developers/resources/message#delete-user-reaction)
"""
function delete_user_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String, user_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/$(user_id)"; token)
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

[Discord docs](https://docs.discord.com/developers/resources/message#get-reactions)
"""
function get_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String, limit::Int=25, type::Int=0)
    query = ["limit" => string(limit)]
    type > 0 && push!(query, "type" => string(type))
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token, query)
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

[Discord docs](https://docs.discord.com/developers/resources/message#delete-all-reactions)
"""
function delete_all_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions"; token)
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

[Discord docs](https://docs.discord.com/developers/resources/message#delete-all-reactions-for-emoji)
"""
function delete_all_reactions_for_emoji(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token)
end

# Polls

"""
    create_poll(rl::RateLimiter, channel_id::Snowflake; token::String, question::String, answers::Vector{String}, duration_hours::Int=24, allow_multiselect::Bool=false) -> Message

Create a poll in a channel.

Use this to post a poll message that users can vote on. The poll is embedded in
a regular message and managed by Discord's native poll system.

# Arguments
- `rl::RateLimiter`: The rate limiter instance.
- `channel_id::Snowflake`: The ID of the channel.

# Keyword Arguments
- `token::String`: Bot authentication token.
- `question::String`: The poll question text (max 300 characters).
- `answers::Vector{String}`: Answer options (1–10 items, each max 55 characters).
- `duration_hours::Int`: How long the poll runs in hours (1–168, default 24).
- `allow_multiselect::Bool`: Whether users may vote for multiple answers (default false).

# Errors
- Throws `ArgumentError` if `answers` is empty or `duration_hours` is out of range.
- HTTP 403 if the bot lacks `SEND_MESSAGES` permission.
- HTTP 404 if the channel does not exist.

[Discord docs](https://docs.discord.com/developers/resources/poll#poll-object)
"""
function create_poll(rl::RateLimiter, channel_id::Snowflake;
    token::String,
    question::String,
    answers::Vector{String},
    duration_hours::Int = 24,
    allow_multiselect::Bool = false,
)
    isempty(answers) && throw(ArgumentError("answers cannot be empty"))
    (duration_hours < 1 || duration_hours > 168) &&
        throw(ArgumentError("duration_hours must be between 1 and 168, got $duration_hours"))

    poll_body = Dict{String, Any}(
        "question"         => Dict("text" => question),
        "answers"          => [Dict("poll_media" => Dict("text" => a)) for a in answers],
        "duration"         => duration_hours,
        "allow_multiselect" => allow_multiselect,
        "layout_type"      => 1,
    )
    body = Dict{String, Any}("poll" => poll_body)
    resp = discord_post(rl, "/channels/$(channel_id)/messages";
        token, body)
    parse_response(Message, resp)
end

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

[Discord docs](https://docs.discord.com/developers/resources/poll#get-answer-voters)
"""
function get_answer_voters(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, answer_id::Int; token::String, limit::Int=25)
    resp = discord_get(rl, "/channels/$(channel_id)/polls/$(message_id)/answers/$(answer_id)"; token,
        query=["limit" => string(limit)])
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

[Discord docs](https://docs.discord.com/developers/resources/poll#end-poll)
"""
function end_poll(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/polls/$(message_id)/expire"; token)
    parse_response(Message, resp)
end
