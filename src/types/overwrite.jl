"""
    Overwrite

Represents a permission overwrite for a role or member in a specific channel.

Overwrites allow you to customize permissions on a per-channel basis, 
overriding the default guild permissions for specific entities.

# Fields
- `id::Snowflake`: The ID of the role or member.
- `type::Int`: The type of entity (`0` for role, `1` for member).
- `allow::String`: Bitset of allowed permissions (string).
- `deny::String`: Bitset of denied permissions (string).

# See Also
- [Discord API: Overwrite Object](https://discord.com/developers/docs/resources/channel#overwrite-object)
"""
@discord_struct Overwrite begin
    id::Snowflake
    type::Int
    allow::String
    deny::String
end
