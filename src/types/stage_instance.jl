"""
    StageInstance

A Stage instance is a live event in a Stage channel. When a Stage instance is created, all users in the Stage channel are notified.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#stage-instance-object)

# Fields
- `id::Snowflake` — Unique ID of the Stage instance.
- `guild_id::Snowflake` — Guild ID of the associated Stage channel.
- `channel_id::Snowflake` — ID of the associated Stage channel.
- `topic::String` — Topic of the Stage instance (1-120 characters).
- `privacy_level::Int` — Privacy level of the Stage instance. See [`StageInstancePrivacyLevels`](@ref) module.
- `discoverable_disabled::Optional{Bool}` — Whether or not Stage Discovery is disabled.
- `guild_scheduled_event_id::Nullable{Snowflake}` — ID of the scheduled event for this Stage instance. `nothing` if not associated with an event.
"""
@discord_struct StageInstance begin
    id::Snowflake
    guild_id::Snowflake
    channel_id::Snowflake
    topic::String
    privacy_level::Int
    discoverable_disabled::Optional{Bool}
    guild_scheduled_event_id::Nullable{Snowflake}
end
