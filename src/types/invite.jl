"""
    InviteMetadata

Extra information about an invite, including usage statistics and expiration settings.

[Discord docs](https://discord.com/developers/docs/resources/invite#invite-object)

# Fields
- `uses::Int` — number of times this invite has been used.
- `max_uses::Int` — max number of times this invite can be used (0 for unlimited).
- `max_age::Int` — duration in seconds after which the invite expires (0 for never).
- `temporary::Bool` — whether this invite only grants temporary membership.
- `created_at::String` — ISO8601 timestamp when this invite was created.
"""
@discord_struct InviteMetadata begin
    uses::Int
    max_uses::Int
    max_age::Int
    temporary::Bool
    created_at::String
end

"""
    Invite

Represents a code that when used, adds a user to a guild or group DM channel. Received when fetching invite information or in invite-related events.

[Discord docs](https://discord.com/developers/docs/resources/invite#invite-object)

# Fields
- `type::Int` — type of invite. See `InviteTypes` (0 = guild, 1 = group dm, 2 = friend).
- `code::String` — unique invite code.
- `guild::Optional{Guild}` — guild this invite is for. Only present when fetched via `GET /invites/{code}` with `with_counts=true`.
- `channel::Nullable{DiscordChannel}` — channel this invite is for. Can be `nothing` for group DM invites.
- `inviter::Optional{User}` — user who created the invite.
- `target_type::Optional{Int}` — type of target for this voice channel invite. See [`InviteTargetTypes`](@ref) module.
- `target_user::Optional{User}` — user whose stream is displayed for this voice channel invite.
- `target_application::Optional{Any}` — embedded application to open for this voice channel embedded application invite.
- `approximate_presence_count::Optional{Int}` — approximate count of online members. Only present when fetched with `with_counts=true`.
- `approximate_member_count::Optional{Int}` — approximate count of total members. Only present when fetched with `with_counts=true`.
- `expires_at::Optional{String}` — expiration date. `nothing` for never-expiring invites.
- `stage_instance::Optional{Any}` — stage instance data if there is a public Stage instance in the Stage channel this invite is for.
- `guild_scheduled_event::Optional{Any}` — guild scheduled event data, only included if `guild_scheduled_event_id` contains a valid guild scheduled event ID.
- `uses::Optional{Int}` — number of times this invite has been used. Only present with invite metadata.
- `max_uses::Optional{Int}` — max number of times this invite can be used. Only present with invite metadata.
- `max_age::Optional{Int}` — duration in seconds after which the invite expires. Only present with invite metadata.
- `temporary::Optional{Bool}` — whether this invite only grants temporary membership. Only present with invite metadata.
- `created_at::Optional{String}` — ISO8601 timestamp when this invite was created. Only present with invite metadata.
"""
@discord_struct Invite begin
    type::Int
    code::String
    guild::Optional{Guild}
    channel::Nullable{DiscordChannel}
    inviter::Optional{User}
    target_type::Optional{Int}
    target_user::Optional{User}
    target_application::Optional{Any}
    approximate_presence_count::Optional{Int}
    approximate_member_count::Optional{Int}
    expires_at::Optional{String}
    stage_instance::Optional{Any}
    guild_scheduled_event::Optional{Any}
    # metadata fields (when fetched with counts)
    uses::Optional{Int}
    max_uses::Optional{Int}
    max_age::Optional{Int}
    temporary::Optional{Bool}
    created_at::Optional{String}
end
