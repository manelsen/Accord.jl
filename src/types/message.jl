@discord_struct MessageActivity begin
    type::Int
    party_id::Optional{String}
end

@discord_struct MessageReference begin
    message_id::Optional{Snowflake}
    channel_id::Optional{Snowflake}
    guild_id::Optional{Snowflake}
    fail_if_not_exists::Optional{Bool}
end

@discord_struct MessageInteractionMetadata begin
    id::Snowflake
    type::Int
    user::Optional{User}
    authorizing_integration_owners::Optional{Any}
    original_response_message_id::Optional{Snowflake}
    target_user::Optional{User}
    target_message_id::Optional{Snowflake}
end

@discord_struct ChannelMention begin
    id::Snowflake
    guild_id::Snowflake
    type::Int
    name::String
end

@discord_struct AllowedMentions begin
    parse::Vector{String}
    roles::Optional{Vector{Snowflake}}
    users::Optional{Vector{Snowflake}}
    replied_user::Optional{Bool}
end

"""
    Message

Represents a message sent in a Discord channel.

A `Message` is the primary way users communicate on Discord. It contains text,
attachments, embeds, and more.

# Fields
- `id::Snowflake`: The unique ID of the message.
- `channel_id::Snowflake`: The ID of the channel the message was sent in.
- `author::Optional{User}`: The user who sent the message (may be missing for some webhooks).
- `content::Optional{String}`: The text content of the message.
- `timestamp::Optional{String}`: ISO8601 timestamp of when the message was sent.
- `edited_timestamp::Optional{String}`: ISO8601 timestamp of when the message was last edited.
- `tts::Optional{Bool}`: Whether the message was a text-to-speech message.
- `mention_everyone::Optional{Bool}`: Whether the message mentions `@everyone`.
- `mentions::Optional{Vector{User}}`: Users specifically mentioned in the message.
- `mention_roles::Optional{Vector{Snowflake}}`: Roles specifically mentioned in the message.
- `mention_channels::Optional{Vector{ChannelMention}}`: Channels mentioned in the message.
- `attachments::Optional{Vector{Attachment}}`: Files attached to the message.
- `embeds::Optional{Vector{Embed}}`: Rich embeds contained in the message.
- `reactions::Optional{Vector{Reaction}}`: Reactions added to the message.
- `nonce::Optional{Any}`: A value used for optimistic message sending.
- `pinned::Optional{Bool}`: Whether the message is pinned.
- `webhook_id::Optional{Snowflake}`: If sent by a webhook, the webhook's ID.
- `type::Optional{Int}`: The message type (see [`MessageType`](@ref)).
- `activity::Optional{MessageActivity}`: Associated activity (e.g., Spotify).
- `application_id::Optional{Snowflake}`: The ID of the application if sent by an app.
- `message_reference::Optional{MessageReference}`: Metadata about a replied-to message.
- `flags::Optional{Int}`: Message flags (see [`MessageFlags`](@ref)).
- `referenced_message::Optional{Message}`: The message being replied to.
- `interaction_metadata::Optional{MessageInteractionMetadata}`: Metadata about the interaction this message responded to.
- `thread::Optional{DiscordChannel}`: The thread that was started from this message.
- `components::Optional{Vector{Component}}`: Buttons, select menus, and other UI components.
- `sticker_items::Optional{Vector{StickerItem}}`: Stickers sent with the message.
- `position::Optional{Int}`: A generally increasing integer for message ordering in threads.
- `poll::Optional{Poll}`: An associated poll.
- `guild_id::Optional{Snowflake}`: The ID of the guild the message was sent in.
- `member::Optional{Member}`: Member properties for the author (only in some contexts).

# Example
```julia
on_message(ctx) do msg
    println("Received message from \$(msg.author.username): \$(msg.content)")
end
```

# See Also
- [Discord API: Message Object](https://discord.com/developers/docs/resources/channel#message-object)
"""
@discord_struct Message begin
    id::Snowflake
    channel_id::Snowflake
    author::Optional{User}
    content::Optional{String}
    timestamp::Optional{String}
    edited_timestamp::Optional{String}
    tts::Optional{Bool}
    mention_everyone::Optional{Bool}
    mentions::Optional{Vector{User}}
    mention_roles::Optional{Vector{Snowflake}}
    mention_channels::Optional{Vector{ChannelMention}}
    attachments::Optional{Vector{Attachment}}
    embeds::Optional{Vector{Embed}}
    reactions::Optional{Vector{Reaction}}
    nonce::Optional{Any}
    pinned::Optional{Bool}
    webhook_id::Optional{Snowflake}
    type::Optional{Int}
    activity::Optional{MessageActivity}
    application_id::Optional{Snowflake}
    message_reference::Optional{MessageReference}
    flags::Optional{Int}
    referenced_message::Optional{Message}
    interaction_metadata::Optional{MessageInteractionMetadata}
    thread::Optional{DiscordChannel}
    components::Optional{Vector{Component}}
    sticker_items::Optional{Vector{StickerItem}}
    position::Optional{Int}
    poll::Optional{Poll}
    guild_id::Optional{Snowflake}
    member::Optional{Member}
end
