"""
    Ban

Represents a ban record in a guild.

# Fields
- `reason::Nullable{String}`: The reason for the ban, if provided.
- `user::Optional{User}`: The user who was banned.

# See Also
- [Discord API: Ban Object](https://docs.discord.com/developers/resources/guild#ban-object)
"""
@discord_struct Ban begin
    reason::Nullable{String}
    user::Optional{User}
end
