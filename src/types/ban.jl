"""
    Ban

A ban in a guild. Represents a user who has been banned and optionally the reason.

[Discord docs](https://discord.com/developers/docs/resources/guild#ban-object)

# Fields
- `reason::Nullable{String}` — reason for the ban. `nothing` if no reason was provided.
- `user::Optional{User}` — banned user information.
"""
@discord_struct Ban begin
    reason::Nullable{String}
    user::Optional{User}
end
