@discord_struct StageInstance begin
    id::Snowflake
    guild_id::Snowflake
    channel_id::Snowflake
    topic::String
    privacy_level::Int
    discoverable_disabled::Optional{Bool}
    guild_scheduled_event_id::Nullable{Snowflake}
end
