"""
    StageInstance

Represents a live event in a Discord Stage channel.

# Fields
- `id::Snowflake`: Unique ID of the instance.
- `guild_id::Snowflake`: Guild ID of the associated Stage channel.
- `channel_id::Snowflake`: ID of the Stage channel.
- `topic::String`: Topic of the stage (1-120 characters).
- `privacy_level::Int`: Privacy level (see [`StageInstancePrivacyLevels`](@ref)).
- `guild_scheduled_event_id::Nullable{Snowflake}`: ID of the associated scheduled event.

# See Also
- [Discord API: Stage Instance Object](https://discord.com/developers/docs/resources/stage-instance#stage-instance-object)
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
