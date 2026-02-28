"""
    Member

Represents a Discord guild member. A `Member` differs from a [`User`](@ref) in that
it contains metadata specific to a particular guild (like nicknames and roles).

# Fields
- `user::Maybe{User}`: The underlying user object.
- `nick::Maybe{String}`: The guild-specific nickname.
- `avatar::Maybe{String}`: The guild-specific avatar hash.
- `roles::Vector{Snowflake}`: Array of role IDs assigned to this member.
- `joined_at::String`: ISO8601 timestamp of when the member joined the guild.
- `premium_since::Maybe{String}`: ISO8601 timestamp of when the member started boosting the guild.
- `deaf::Maybe{Bool}`: Whether the member is deafened in voice channels.
- `mute::Maybe{Bool}`: Whether the member is muted in voice channels.
- `flags::Int`: Guild member flags (see [`GuildMemberFlags`](@ref)).
- `pending::Maybe{Bool}`: Whether the member has not yet passed the guild's Membership Screening.
- `permissions::Maybe{String}`: Total permissions of the member in a channel (sent in interactions).
- `communication_disabled_until::Maybe{String}`: ISO8601 timestamp of when the member's timeout expires.
- `avatar_decoration_data::Maybe{Any}`: Metadata about the member's guild avatar decoration.

# Example
```julia
member = msg.member
if !ismissing(member.nick)
    println("Member nickname: \$(member.nick)")
end
```

# See Also
- [Discord API: Guild Member Object](https://discord.com/developers/docs/resources/guild#guild-member-object)
"""
@discord_struct Member begin
    user::Maybe{User}
    nick::Maybe{String}
    avatar::Maybe{String}
    roles::Vector{Snowflake}
    joined_at::String
    premium_since::Maybe{String}
    deaf::Maybe{Bool}
    mute::Maybe{Bool}
    flags::Int
    pending::Maybe{Bool}
    permissions::Maybe{String}
    communication_disabled_until::Maybe{String}
    avatar_decoration_data::Maybe{Any}
end
