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
    user::User
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
