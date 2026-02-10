@discord_struct WelcomeScreenChannel begin
    channel_id::Snowflake
    description::String
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

@discord_struct WelcomeScreen begin
    description::Nullable{String}
    welcome_channels::Vector{WelcomeScreenChannel}
end

@discord_struct UnavailableGuild begin
    id::Snowflake
    unavailable::Optional{Bool}
end

@discord_struct Guild begin
    id::Snowflake
    name::String
    icon::Nullable{String}
    icon_hash::Optional{String}
    splash::Nullable{String}
    discovery_splash::Nullable{String}
    owner::Optional{Bool}
    owner_id::Optional{Snowflake}
    permissions::Optional{String}
    afk_channel_id::Nullable{Snowflake}
    afk_timeout::Optional{Int}
    widget_enabled::Optional{Bool}
    widget_channel_id::Optional{Snowflake}
    verification_level::Optional{Int}
    default_message_notifications::Optional{Int}
    explicit_content_filter::Optional{Int}
    roles::Optional{Vector{Role}}
    emojis::Optional{Vector{Emoji}}
    features::Optional{Vector{String}}
    mfa_level::Optional{Int}
    application_id::Nullable{Snowflake}
    system_channel_id::Nullable{Snowflake}
    system_channel_flags::Optional{Int}
    rules_channel_id::Nullable{Snowflake}
    max_presences::Optional{Int}
    max_members::Optional{Int}
    vanity_url_code::Nullable{String}
    description::Nullable{String}
    banner::Nullable{String}
    premium_tier::Optional{Int}
    premium_subscription_count::Optional{Int}
    preferred_locale::Optional{String}
    public_updates_channel_id::Nullable{Snowflake}
    max_video_channel_users::Optional{Int}
    max_stage_video_channel_users::Optional{Int}
    approximate_member_count::Optional{Int}
    approximate_presence_count::Optional{Int}
    welcome_screen::Optional{WelcomeScreen}
    nsfw_level::Optional{Int}
    stickers::Optional{Vector{Sticker}}
    premium_progress_bar_enabled::Optional{Bool}
    safety_alerts_channel_id::Nullable{Snowflake}
    # GUILD_CREATE extras
    joined_at::Optional{String}
    large::Optional{Bool}
    unavailable::Optional{Bool}
    member_count::Optional{Int}
    voice_states::Optional{Vector{Any}}
    members::Optional{Vector{Member}}
    channels::Optional{Vector{DiscordChannel}}
    threads::Optional{Vector{DiscordChannel}}
    presences::Optional{Vector{Any}}
    stage_instances::Optional{Vector{Any}}
    guild_scheduled_events::Optional{Vector{Any}}
    soundboard_sounds::Optional{Vector{Any}}
end
