"""
    ThreadMetadata

Metadata for a forum or media thread, including auto-archive settings and lock status.

[Discord docs](https://discord.com/developers/docs/resources/channel#thread-metadata-object)

# Fields
- `archived::Bool` — whether the thread is archived.
- `auto_archive_duration::Int` — duration in minutes to automatically archive the thread after recent activity.
- `archive_timestamp::String` — ISO8601 timestamp when the thread's archive status was last changed.
- `locked::Bool` — whether the thread is locked; when locked only users with `MANAGE_THREADS` can unarchive it.
- `invitable::Optional{Bool}` — whether non-moderators can add other non-moderators to a private thread.
- `create_timestamp::Optional{String}` — ISO8601 timestamp when the thread was created. Only present for threads created after 2022-01-09.
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

A member of a thread.

[Discord docs](https://discord.com/developers/docs/resources/channel#thread-member-object)

# Fields
- `id::Optional{Snowflake}` — ID of the thread. Omitted on the `GUILD_THREAD_MEMBERS_UPDATE` gateway event.
- `user_id::Optional{Snowflake}` — ID of the user. Omitted on the `GUILD_THREAD_MEMBERS_UPDATE` gateway event.
- `join_timestamp::String` — ISO8601 timestamp when the user joined the thread.
- `flags::Int` — any user-thread settings, currently only used for notifications.
- `member::Optional{Member}` — additional information about the user. Only present when `with_member` is set to `true` when listing thread members.
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

A tag that can be applied to threads in a `GUILD_FORUM` or `GUILD_MEDIA` channel.

[Discord docs](https://discord.com/developers/docs/resources/channel#forum-tag-object)

# Fields
- `id::Snowflake` — unique ID of the tag.
- `name::String` — name of the tag (0-20 characters).
- `moderated::Bool` — whether this tag can only be added or removed by members with the `MANAGE_THREADS` permission.
- `emoji_id::Nullable{Snowflake}` — ID of a guild's custom emoji. At least one of `emoji_id` or `emoji_name` must be set.
- `emoji_name::Nullable{String}` — Unicode character of the emoji. At least one of `emoji_id` or `emoji_name` must be set.
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

The default emoji to show in the reaction button for a forum post.

[Discord docs](https://discord.com/developers/docs/resources/channel#default-reaction-object)

# Fields
- `emoji_id::Nullable{Snowflake}` — ID of a guild's custom emoji. At least one of `emoji_id` or `emoji_name` must be set.
- `emoji_name::Nullable{String}` — Unicode character of the emoji. At least one of `emoji_id` or `emoji_name` must be set.
"""
@discord_struct DefaultReaction begin
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

"""
    DiscordChannel

Represents a guild or DM channel within Discord. This is a central structure that bots interact with constantly when sending messages, managing permissions, or handling events.

[Discord docs](https://discord.com/developers/docs/resources/channel#channel-object)

# Fields
- `id::Snowflake` — unique ID of the channel.
- `type::Int` — type of channel. See [`ChannelTypes`](@ref) module for values.
- `guild_id::Optional{Snowflake}` — ID of the guild the channel belongs to. May be missing for some channel objects received over gateway guild dispatches.
- `position::Optional{Int}` — sorting position of the channel. Only present for guild channels.
- `permission_overwrites::Optional{Vector{Overwrite}}` — explicit permission overwrites for members and roles. Only present for guild channels.
- `name::Optional{String}` — name of the channel (1-100 characters). Not present for DM channels.
- `topic::Optional{String}` — channel topic (0-1024 characters for `GUILD_FORUM` and `GUILD_MEDIA` channels, 0-4096 for all others). Not present for all channel types.
- `nsfw::Optional{Bool}` — whether the channel is NSFW. Only present for guild channels.
- `last_message_id::Optional{Snowflake}` — ID of the last message sent in this channel. May not point to an existing message. Not present for all channel types.
- `bitrate::Optional{Int}` — bitrate (in bits) of the voice channel. Only for voice channels.
- `user_limit::Optional{Int}` — user limit of the voice channel. Only for voice channels.
- `rate_limit_per_user::Optional{Int}` — amount of seconds a user has to wait before sending another message (0-21600). Not present for all channel types.
- `recipients::Optional{Vector{User}}` — recipients of the DM. Only present for DM and group DM channels.
- `icon::Optional{String}` — icon hash of the group DM. Only present for group DM channels.
- `owner_id::Optional{Snowflake}` — ID of the creator of the group DM or thread. Present for group DMs and threads.
- `application_id::Optional{Snowflake}` — application ID of the group DM creator if bot-created. Present for group DMs.
- `managed::Optional{Bool}` — for group DM channels, whether the channel is managed by an application.
- `parent_id::Optional{Snowflake}` — ID of the parent category or thread. Present for channel categories, threads, and some child channels.
- `last_pin_timestamp::Optional{String}` — ISO8601 timestamp of when the last pinned message was pinned. May be null.
- `rtc_region::Optional{String}` — voice region ID for the voice channel; automatic when set to `nothing`. Only for voice channels.
- `video_quality_mode::Optional{Int}` — camera video quality mode of the voice channel. See `VideoQualityModes` (1 = auto, 2 = full).
- `message_count::Optional{Int}` — approximate count of messages in a thread; stops counting at 50. Only for threads.
- `member_count::Optional{Int}` — approximate count of members in a thread; stops counting at 50. Only for threads.
- `thread_metadata::Optional{ThreadMetadata}` — thread-specific fields. Only for threads.
- `member::Optional{ThreadMember}` — thread member object for the current user if they have joined the thread. Only present for threads.
- `default_auto_archive_duration::Optional{Int}` — default duration for newly created threads. Only for text and forum/media channels.
- `permissions::Optional{String}` — computed permissions for the invoking user in the channel, including overwrites. Only included when part of the `resolved` set received from an interaction.
- `flags::Optional{Int}` — channel flags combined as a bitfield. See [`ChannelFlags`](@ref) module.
- `total_message_sent::Optional{Int}` — number of messages ever sent in a thread. Similar to `message_count` but won't decrease when messages are deleted. Only for threads.
- `available_tags::Optional{Vector{ForumTag}}` — set of tags that can be used in a `GUILD_FORUM` or `GUILD_MEDIA` channel. Only for those channel types.
- `applied_tags::Optional{Vector{Snowflake}}` — IDs of the set of tags applied to a thread in a `GUILD_FORUM` or `GUILD_MEDIA` channel. Max 5. Only for threads in those channel types.
- `default_reaction_emoji::Optional{DefaultReaction}` — emoji to show in the add reaction button on a thread in a `GUILD_FORUM` or `GUILD_MEDIA` channel. Only for those channel types.
- `default_thread_rate_limit_per_user::Optional{Int}` — initial `rate_limit_per_user` to enable on newly created threads. Only for forum and text channels.
- `default_sort_order::Optional{Int}` — default sort order type used to order posts in `GUILD_FORUM` and `GUILD_MEDIA` channels. See [`SortOrderTypes`](@ref) module.
- `default_forum_layout::Optional{Int}` — default forum layout view used to display posts in `GUILD_FORUM` channels. See [`ForumLayoutTypes`](@ref) module.
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
