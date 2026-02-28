"""
    User

Use this struct to access information about any Discord user, including bot users and guild members.

Represents a Discord user.

# Fields
- `id`: The user's snowflake ID.
- `username`: The user's username.
- `discriminator`: The user's 4-digit discord-tag (optional).
- `global_name`: The user's display name (optional).
- `avatar`: The user's avatar hash.
- `bot`: Whether the user is a bot.
- `system`: Whether the user is an Official Discord System user.
"""
@discord_struct User begin
    id::Snowflake
    username::String
    discriminator::Maybe{String}
    global_name::Maybe{String}
    avatar::Maybe{String}
    bot::Maybe{Bool}
    system::Maybe{Bool}
    mfa_enabled::Maybe{Bool}
    banner::Maybe{String}
    accent_color::Maybe{Int}
    locale::Maybe{String}
    verified::Maybe{Bool}
    email::Maybe{String}
    flags::Maybe{Int}
    premium_type::Maybe{Int}
    public_flags::Maybe{Int}
    avatar_decoration_data::Maybe{Any}
end
