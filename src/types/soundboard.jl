"""
    SoundboardSound

Represents a sound that can be played in a voice channel's soundboard.

[Discord docs](https://discord.com/developers/docs/resources/soundboard#soundboard-sound-object)

# Fields
- `name::String` — Name of the sound (2-32 characters).
- `sound_id::Snowflake` — Unique ID of the sound.
- `volume::Float64` — Volume of the sound, from 0.0 to 1.0.
- `emoji_id::Nullable{Snowflake}` — ID of the associated custom emoji. At least one of `emoji_id` or `emoji_name` will be set.
- `emoji_name::Nullable{String}` — Unicode character of the associated emoji. At least one of `emoji_id` or `emoji_name` will be set.
- `guild_id::Optional{Snowflake}` — Guild ID this sound belongs to. `nothing` for default sounds.
- `available::Bool` — Whether this sound can be used.
- `user::Optional{User}` — User who created this sound. `nothing` for default sounds.
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
