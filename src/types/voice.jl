@discord_struct VoiceState begin
    guild_id::Optional{Snowflake}
    channel_id::Nullable{Snowflake}
    user_id::Snowflake
    member::Optional{Member}
    session_id::String
    deaf::Bool
    mute::Bool
    self_deaf::Bool
    self_mute::Bool
    self_stream::Optional{Bool}
    self_video::Bool
    suppress::Bool
    request_to_speak_timestamp::Nullable{String}
end

@discord_struct VoiceRegion begin
    id::String
    name::String
    optimal::Bool
    deprecated::Bool
    custom::Bool
end
