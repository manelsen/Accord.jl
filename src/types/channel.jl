@discord_struct ThreadMetadata begin
    archived::Bool
    auto_archive_duration::Int
    archive_timestamp::String
    locked::Bool
    invitable::Optional{Bool}
    create_timestamp::Optional{String}
end

@discord_struct ThreadMember begin
    id::Optional{Snowflake}
    user_id::Optional{Snowflake}
    join_timestamp::String
    flags::Int
    member::Optional{Member}
end

@discord_struct ForumTag begin
    id::Snowflake
    name::String
    moderated::Bool
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

@discord_struct DefaultReaction begin
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

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
