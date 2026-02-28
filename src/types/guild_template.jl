"""
    GuildTemplate

Represents a snapshot of a guild that can be used to create new guilds.

# Fields
- `code::String`: The unique template code.
- `name::String`: Name of the template.
- `description::Optional{String}`: Description of the template.
- `usage_count::Int`: Number of times it has been used.
- `creator_id::Snowflake`: ID of the user who created it.
- `source_guild_id::Snowflake`: ID of the guild it was based on.

# See Also
- [Discord API: Guild Template Object](https://discord.com/developers/docs/resources/guild-template#guild-template-object)
"""
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
