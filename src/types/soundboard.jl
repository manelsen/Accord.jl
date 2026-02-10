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
