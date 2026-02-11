# Guild Template — a snapshot of a guild's settings that can be used to create new guilds

@discord_struct GuildTemplate begin
    code::String
    name::String
    description::Optional{String}
    usage_count::Int
    creator_id::Snowflake
    creator::Optional{User}
    created_at::String
    updated_at::String
    source_guild_id::Snowflake
    serialized_source_guild::Optional{Guild}
    is_dirty::Optional{Bool}
end
