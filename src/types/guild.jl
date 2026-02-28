"""
    WelcomeScreenChannel

Metadata for a channel on a guild's welcome screen.

# See Also
- [Discord API: Welcome Screen Channel Object](https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure)
"""
@discord_struct WelcomeScreenChannel begin
    channel_id::Snowflake
    description::String
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

"""
    WelcomeScreen

The welcome screen shown to new members in a guild.

# See Also
- [Discord API: Welcome Screen Object](https://discord.com/developers/docs/resources/guild#welcome-screen-object)
"""
@discord_struct WelcomeScreen begin
    description::Nullable{String}
    welcome_channels::Vector{WelcomeScreenChannel}
end

"""
    UnavailableGuild

Represents a guild that is currently unavailable due to an outage.

# See Also
- [Discord API: Unavailable Guild Object](https://discord.com/developers/docs/resources/guild#unavailable-guild-object)
"""
@discord_struct UnavailableGuild begin
    id::Snowflake
    unavailable::Optional{Bool}
end

"""
    Guild

Represents a Discord guild (server).

A `Guild` contains all the data about a server, including its name, roles, 
emojis, and (in `GUILD_CREATE` events) its channels and members.

# Fields
- `id::Snowflake`: The unique ID of the guild.
- `name::String`: The guild's name.
- `icon::Nullable{String}`: The guild's icon hash.
- `splash::Nullable{String}`: The guild's splash image hash.
- `discovery_splash::Nullable{String}`: Discovery splash hash (for partnered/verified).
- `owner_id::Optional{Snowflake}`: ID of the guild owner.
- `permissions::Optional{String}`: Total permissions for the user in the guild.
- `afk_channel_id::Nullable{Snowflake}`: ID of the AFK voice channel.
- `afk_timeout::Optional{Int}`: AFK timeout in seconds.
- `widget_enabled::Optional{Bool}`: Whether the server widget is enabled.
- `verification_level::Optional{Int}`: Verification level required for the guild.
- `roles::Optional{Vector{Role}}`: Roles assigned to this guild.
- `emojis::Optional{Vector{Emoji}}`: Custom emojis in this guild.
- `features::Optional{Vector{String}}`: List of enabled guild features (e.g., "COMMUNITY").
- `mfa_level::Optional{Int}`: MFA level required for moderators.
- `system_channel_id::Nullable{Snowflake}`: ID of the channel where system messages are sent.
- `vanity_url_code::Nullable{String}`: The vanity URL code (for boosted guilds).
- `description::Nullable{String}`: The guild's description.
- `banner::Nullable{String}`: The guild's banner image hash.
- `premium_tier::Optional{Int}`: The Nitro boost tier of the guild.
- `premium_subscription_count::Optional{Int}`: The number of Nitro boosts.
- `approximate_member_count::Optional{Int}`: Approximate total member count.
- `approximate_presence_count::Optional{Int}`: Approximate online member count.
- `nsfw_level::Optional{Int}`: Guild's NSFW level.
- `stickers::Optional{Vector{Sticker}}`: Custom stickers in this guild.

# Example
```julia
guild = fetch_guild(client, guild_id)
println("Server name: \$(guild.name) (\$(guild.id))")
```

# See Also
- [Discord API: Guild Object](https://discord.com/developers/docs/resources/guild#guild-object)
"""
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
