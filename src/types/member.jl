"""
    Member

A guild member. This struct is received whenever information about a guild member is available, such as in message events, voice state updates, or when fetching guild members.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-member-object)

# Fields
- `user::Optional{User}` — user object for the guild member. Only present if the member was fetched or is the bot itself.
- `nick::Optional{String}` — guild-specific nickname for the member, if set.
- `avatar::Optional{String}` — member's guild-specific avatar hash, if set.
- `roles::Vector{Snowflake}` — array of role IDs that the member has.
- `joined_at::String` — ISO8601 timestamp when the user joined the guild.
- `premium_since::Optional{String}` — ISO8601 timestamp when the user started boosting the guild, if applicable.
- `deaf::Optional{Bool}` — whether the user is deafened in voice channels.
- `mute::Optional{Bool}` — whether the user is muted in voice channels.
- `flags::Int` — guild member flags represented as a bit set. See [`GuildMemberFlags`](@ref) module.
- `pending::Optional{Bool}` — whether the user has not yet passed the guild's Membership Screening requirements.
- `permissions::Optional{String}` — total permissions of the member in the channel, including overwrites. Returned when in the interaction object.
- `communication_disabled_until::Optional{String}` — ISO8601 timestamp until the user's timeout expires, if applicable. When present, the user cannot interact with the guild.
- `avatar_decoration_data::Optional{Any}` — data for the member's guild avatar decoration.
"""
@discord_struct Member begin
    user::Optional{User}
    nick::Optional{String}
    avatar::Optional{String}
    roles::Vector{Snowflake}
    joined_at::String
    premium_since::Optional{String}
    deaf::Optional{Bool}
    mute::Optional{Bool}
    flags::Int
    pending::Optional{Bool}
    permissions::Optional{String}
    communication_disabled_until::Optional{String}
    avatar_decoration_data::Optional{Any}
end
