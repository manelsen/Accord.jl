"""
    Overwrite

Permission overwrites for a role or member in a channel. These explicitly allow or deny specific permissions.

[Discord docs](https://discord.com/developers/docs/resources/channel#overwrite-object)

# Fields
- `id::Snowflake` — role or user ID.
- `type::Int` — type of overwrite. `0` for role, `1` for member.
- `allow::String` — permission bit set string for allowed permissions.
- `deny::String` — permission bit set string for denied permissions.
"""
@discord_struct Overwrite begin
    id::Snowflake
    type::Int
    allow::String
    deny::String
end
