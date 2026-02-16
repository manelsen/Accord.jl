"""
    VoiceState

Represents a user's voice connection status in a guild. Received via the Gateway in voice state update events.

[Discord docs](https://discord.com/developers/docs/resources/voice#voice-state-object)

# Fields
- `guild_id::Optional{Snowflake}` — guild ID this voice state is for. May be missing for private channels.
- `channel_id::Nullable{Snowflake}` — channel ID this user is connected to. `nothing` means the user disconnected.
- `user_id::Snowflake` — user ID this voice state is for.
- `member::Optional{Member}` — guild member object for this user. Only sent in `GUILD_CREATE` and some `VOICE_STATE_UPDATE` events.
- `session_id::String` — session ID for this voice state.
- `deaf::Bool` — whether this user is deafened by the server.
- `mute::Bool` — whether this user is muted by the server.
- `self_deaf::Bool` — whether this user is locally deafened.
- `self_mute::Bool` — whether this user is locally muted.
- `self_stream::Optional{Bool}` — whether this user is streaming using "Go Live".
- `self_video::Bool` — whether this user's camera is enabled.
- `suppress::Bool` — whether this user's permission to speak is denied.
- `request_to_speak_timestamp::Nullable{String}` — time at which the user requested to speak. `nothing` if not requesting to speak.
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

A voice region for Discord voice servers. Used when connecting to voice channels.

[Discord docs](https://discord.com/developers/docs/resources/voice#voice-region-object)

# Fields
- `id::String` — unique ID for the region.
- `name::String` — name of the region.
- `optimal::Bool` — whether this region is optimal for the bot's server.
- `deprecated::Bool` — whether this is a deprecated voice region.
- `custom::Bool` — whether this is a custom voice region (used for events).
"""
@discord_struct VoiceRegion begin
    id::String
    name::String
    optimal::Bool
    deprecated::Bool
    custom::Bool
end
