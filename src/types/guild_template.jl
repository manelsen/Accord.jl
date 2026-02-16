"""
    GuildTemplate

Represents a code that when used, creates a guild based on a snapshot of an existing guild.

[Discord docs](https://discord.com/developers/docs/resources/guild-template#guild-template-object)

# Fields
- `code::String` — Template code (unique ID).
- `name::String` — Name of the template (1-100 characters).
- `description::Optional{String}` — Description of the template (max 120 characters).
- `usage_count::Int` — Number of times this template has been used.
- `creator_id::Snowflake` — ID of the user who created the template.
- `creator::Optional{User}` — User who created the template.
- `created_at::String` — ISO8601 timestamp when the template was created.
- `updated_at::String` — ISO8601 timestamp when the template was last synced to the source guild.
- `source_guild_id::Snowflake` — ID of the guild this template is based on.
- `serialized_source_guild::Optional{Guild}` — Partial guild object with guild data.
- `is_dirty::Optional{Bool}` — Whether the template has unsynced changes.
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
