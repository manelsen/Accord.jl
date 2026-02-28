"""
    SoundboardSound

Represents a sound that can be played in a Discord voice channel's soundboard.

# Fields
- `name::String`: Name of the sound.
- `sound_id::Snowflake`: Unique ID of the sound.
- `volume::Float64`: Default playback volume (0.0 to 1.0).
- `emoji_id::Nullable{Snowflake}`: ID of the associated custom emoji.
- `emoji_name::Nullable{String}`: Unicode name of the associated emoji.
- `guild_id::Optional{Snowflake}`: Guild where the sound is hosted.
- `available::Bool`: Whether the sound can be played.
- `user::Optional{User}`: User who uploaded the sound.

# See Also
- [Discord API: Soundboard Sound Object](https://discord.com/developers/docs/resources/soundboard#soundboard-sound-object)
"""
@discord_struct SoundboardSound begin
    name::String
    sound_id::Snowflake
    volume::Float64
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
    guild_id::Optional{Snowflake}
    available::Bool
    user::Optional{User}
end
