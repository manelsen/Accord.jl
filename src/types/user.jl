"""
    PrimaryGuild

The server tag a user displays next to their name (`User.primary_guild`).

# Fields
- `identity_guild_id::Maybe{Snowflake}`: The guild whose tag is shown.
- `identity_enabled::Maybe{Bool}`: Whether the tag is shown; empty when Discord cleared it.
- `tag::Maybe{String}`: The tag text (up to 4 characters).
- `badge::Maybe{String}`: The badge image hash.
"""
@discord_struct PrimaryGuild begin
    identity_guild_id::Maybe{Snowflake}
    identity_enabled::Maybe{Bool}
    tag::Maybe{String}
    badge::Maybe{String}
end

"""
    User

Represents a Discord user. Users are global and not tied to any specific guild,
although they can have guild-specific metadata (see [`Member`](@ref)).

# Fields
- `id::Snowflake`: The unique ID of the user.
- `username::String`: The user's Discord username.
- `discriminator::Maybe{String}`: The user's 4-digit tag (legacy, e.g., "1234").
- `global_name::Maybe{String}`: The user's display name as seen by everyone.
- `avatar::Maybe{String}`: The hash of the user's avatar.
- `bot::Maybe{Bool}`: Whether the user is an official bot.
- `system::Maybe{Bool}`: Whether the user is an official Discord system user.
- `mfa_enabled::Maybe{Bool}`: Whether the user has two-factor authentication enabled.
- `banner::Maybe{String}`: The hash of the user's banner image.
- `accent_color::Maybe{Int}`: The user's banner color encoded as an integer.
- `locale::Maybe{String}`: The user's chosen language (e.g., "en-US").
- `verified::Maybe{Bool}`: Whether the email on this account has been verified.
- `email::Maybe{String}`: The user's email address (requires scopes).
- `flags::Maybe{Int}`: The public flags on a user's account.
- `premium_type::Maybe{Int}`: The type of Nitro subscription on a user's account.
- `public_flags::Maybe{Int}`: The public flags on a user's account.
- `avatar_decoration_data::Maybe{Any}`: Metadata about the user's avatar decoration.
- `collectibles::Maybe{Any}`: Collectibles the user has (nameplates, …).
- `primary_guild::Maybe{PrimaryGuild}`: The server tag the user displays.

# Example
```julia
user = msg.author
println("Hello, \$(user.username)!")
```

# See Also
- [Discord API: User Object](https://discord.com/developers/docs/resources/user#user-object)
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
    collectibles::Maybe{Any}
    primary_guild::Maybe{PrimaryGuild}
end
