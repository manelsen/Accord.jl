"""
    VoiceState

Represents a user's voice connection status in a guild.

# Fields
- `guild_id::Optional{Snowflake}`: Guild ID.
- `channel_id::Nullable{Snowflake}`: Connected channel ID (null if disconnected).
- `user_id::Snowflake`: User ID.
- `session_id::String`: Unique session ID.
- `deaf::Bool`: Whether the user is server-deafened.
- `mute::Bool`: Whether the user is server-muted.
- `self_deaf::Bool`: Whether the user is self-deafened.
- `self_mute::Bool`: Whether the user is self-muted.
- `self_stream::Optional{Bool}`: Whether the user is streaming.
- `self_video::Bool`: Whether the user's camera is on.
- `suppress::Bool`: Whether the user is suppressed (for stages).

# See Also
- [Discord API: Voice State Object](https://discord.com/developers/docs/resources/voice#voice-state-object)
"""
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

"""
    VoiceRegion

Represents a Discord voice server region.

# See Also
- [Discord API: Voice Region Object](https://discord.com/developers/docs/resources/voice#voice-region-object)
"""
@discord_struct VoiceRegion begin
    id::String
    name::String
    optimal::Bool
    deprecated::Bool
    custom::Bool
end
