"""
    User

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
    discriminator::Optional{String}
    global_name::Optional{String}
    avatar::Nullable{String}
    bot::Optional{Bool}
    system::Optional{Bool}
    mfa_enabled::Optional{Bool}
    banner::Optional{String}
    accent_color::Optional{Int}
    locale::Optional{String}
    verified::Optional{Bool}
    email::Optional{String}
    flags::Optional{Int}
    premium_type::Optional{Int}
    public_flags::Optional{Int}
    avatar_decoration_data::Optional{Any}
end
