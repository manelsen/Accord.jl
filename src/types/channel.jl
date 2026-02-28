"""
    ThreadMetadata

Contains metadata about a Discord thread, such as its archive status and lock state.

# Fields
- `archived::Bool`: Whether the thread is archived.
- `auto_archive_duration::Int`: Duration in minutes to automatically archive the thread after recent activity (60, 1440, 4320, 10080).
- `archive_timestamp::String`: ISO8601 timestamp when the thread's archive status was last changed.
- `locked::Bool`: Whether the thread is locked.
- `invitable::Optional{Bool}`: Whether non-moderators can add other non-moderators to a private thread.
- `create_timestamp::Optional{String}`: ISO8601 timestamp when the thread was created.

# See Also
- [Discord API: Thread Metadata Object](https://discord.com/developers/docs/resources/channel#thread-metadata-object)
"""
@discord_struct ThreadMetadata begin
    archived::Bool
    auto_archive_duration::Int
    archive_timestamp::String
    locked::Bool
    invitable::Optional{Bool}
    create_timestamp::Optional{String}
end

"""
    ThreadMember

Represents a member of a thread.

# Fields
- `id::Optional{Snowflake}`: ID of the thread.
- `user_id::Optional{Snowflake}`: ID of the user.
- `join_timestamp::String`: ISO8601 timestamp when the user joined the thread.
- `flags::Int`: User-thread settings (notifications, etc.).
- `member::Optional{Member}`: Additional member information (if requested).

# See Also
- [Discord API: Thread Member Object](https://discord.com/developers/docs/resources/channel#thread-member-object)
"""
@discord_struct ThreadMember begin
    id::Optional{Snowflake}
    user_id::Optional{Snowflake}
    join_timestamp::String
    flags::Int
    member::Optional{Member}
end

"""
    ForumTag

Represents a tag that can be applied to threads in a forum or media channel.

# Fields
- `id::Snowflake`: Unique ID of the tag.
- `name::String`: The name of the tag (0-20 characters).
- `moderated::Bool`: Whether this tag can only be added/removed by moderators.
- `emoji_id::Nullable{Snowflake}`: ID of a custom guild emoji.
- `emoji_name::Nullable{String}`: Unicode character of the emoji.

# See Also
- [Discord API: Forum Tag Object](https://discord.com/developers/docs/resources/channel#forum-tag-object)
"""
@discord_struct ForumTag begin
    id::Snowflake
    name::String
    moderated::Bool
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

"""
    DefaultReaction

The default emoji shown in the reaction button for a forum post.

# Fields
- `emoji_id::Nullable{Snowflake}`: ID of a custom guild emoji.
- `emoji_name::Nullable{String}`: Unicode character of the emoji.
"""
@discord_struct DefaultReaction begin
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

"""
    DiscordChannel

Represents a Discord channel. This can be a text channel, voice channel, category, 
thread, or DM.

Channels are the primary containers for messages and other Discord resources.

# Fields
- `id::Snowflake`: The unique ID of the channel.
- `type::Int`: The type of channel (see [`ChannelTypes`](@ref)).
- `guild_id::Optional{Snowflake}`: The ID of the guild (missing for DMs).
- `position::Optional{Int}`: Sorting position in the guild.
- `permission_overwrites::Optional{Vector{Overwrite}}`: Explicit permission overwrites.
- `name::Optional{String}`: The name of the channel.
- `topic::Optional{String}`: The channel topic.
- `nsfw::Optional{Bool}`: Whether the channel is marked as age-restricted.
- `last_message_id::Optional{Snowflake}`: ID of the most recent message.
- `bitrate::Optional{Int}`: Bitrate (in bits) for voice channels.
- `user_limit::Optional{Int}`: Maximum users allowed in a voice channel.
- `rate_limit_per_user::Optional{Int}`: Slowmode duration in seconds.
- `recipients::Optional{Vector{User}}`: The recipients of a DM.
- `icon::Optional{String}`: Icon hash for group DMs.
- `owner_id::Optional{Snowflake}`: ID of the creator of a thread or group DM.
- `application_id::Optional{Snowflake}`: Application ID of a bot-created group DM.
- `managed::Optional{Bool}`: Whether a group DM is managed by an app.
- `parent_id::Optional{Snowflake}`: ID of the category or parent channel.
- `last_pin_timestamp::Optional{String}`: ISO8601 timestamp of the last pinned message.
- `rtc_region::Optional{String}`: Voice region ID (automatic if null).
- `video_quality_mode::Optional{Int}`: Video quality (1=auto, 2=full).
- `message_count::Optional{Int}`: Approximate message count in threads.
- `member_count::Optional{Int}`: Approximate member count in threads.
- `thread_metadata::Optional{ThreadMetadata}`: Thread-specific metadata.
- `member::Optional{ThreadMember}`: Thread member object for the current user.
- `default_auto_archive_duration::Optional{Int}`: Default duration for new threads.
- `permissions::Optional{String}`: Computed permissions for the user (in interactions).
- `flags::Optional{Int}`: Channel flags (see [`ChannelFlags`](@ref)).
- `total_message_sent::Optional{Int}`: Total messages ever sent in a thread.
- `available_tags::Optional{Vector{ForumTag}}`: Tags available in forum channels.
- `applied_tags::Optional{Vector{Snowflake}}`: Tags applied to a thread.
- `default_reaction_emoji::Optional{DefaultReaction}`: Default forum reaction emoji.
- `default_thread_rate_limit_per_user::Optional{Int}`: Initial slowmode for new threads.
- `default_sort_order::Optional{Int}`: Default sort order for forum posts.
- `default_forum_layout::Optional{Int}`: Default view layout for forum posts.

# Example
```julia
channel = fetch_channel(client, id)
println("Channel name: \$(channel.name)")
```

# See Also
- [Discord API: Channel Object](https://discord.com/developers/docs/resources/channel#channel-object)
"""
@discord_struct DiscordChannel begin
    id::Snowflake
    type::Int
    guild_id::Optional{Snowflake}
    position::Optional{Int}
    permission_overwrites::Optional{Vector{Overwrite}}
    name::Optional{String}
    topic::Optional{String}
    nsfw::Optional{Bool}
    last_message_id::Optional{Snowflake}
    bitrate::Optional{Int}
    user_limit::Optional{Int}
    rate_limit_per_user::Optional{Int}
    recipients::Optional{Vector{User}}
    icon::Optional{String}
    owner_id::Optional{Snowflake}
    application_id::Optional{Snowflake}
    managed::Optional{Bool}
    parent_id::Optional{Snowflake}
    last_pin_timestamp::Optional{String}
    rtc_region::Optional{String}
    video_quality_mode::Optional{Int}
    message_count::Optional{Int}
    member_count::Optional{Int}
    thread_metadata::Optional{ThreadMetadata}
    member::Optional{ThreadMember}
    default_auto_archive_duration::Optional{Int}
    permissions::Optional{String}
    flags::Optional{Int}
    total_message_sent::Optional{Int}
    available_tags::Optional{Vector{ForumTag}}
    applied_tags::Optional{Vector{Snowflake}}
    default_reaction_emoji::Optional{DefaultReaction}
    default_thread_rate_limit_per_user::Optional{Int}
    default_sort_order::Optional{Int}
    default_forum_layout::Optional{Int}
end
