"""
    InviteMetadata

Extra usage statistics and metadata for a Discord [`Invite`](@ref).

# See Also
- [Discord API: Invite Metadata](https://docs.discord.com/developers/resources/invite#invite-metadata-object)
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

Represents a Discord invite code.

Invites are used to add users to guilds or group DMs.

# Fields
- `code::String`: The unique invite code (e.g., "discord-jl").
- `guild::Optional{Guild}`: The guild this invite is for.
- `channel::Nullable{DiscordChannel}`: The channel this invite is for.
- `inviter::Optional{User}`: The user who created the invite.
- `target_type::Optional{Int}`: The target type (see [`InviteTargetTypes`](@ref)).
- `approximate_presence_count::Optional{Int}`: Online members count.
- `approximate_member_count::Optional{Int}`: Total members count.
- `expires_at::Optional{String}`: ISO8601 expiration timestamp.
- `roles::Optional{Vector{Role}}`: Roles given to whoever accepts the invite
  (partial: id, name, position, colours, icon).
- `flags::Optional{Int}`: Invite flags; `1 << 0` marks a guest invite.

# See Also
- [Discord API: Invite Object](https://docs.discord.com/developers/resources/invite#invite-object)
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
    roles::Optional{Vector{Role}}
    flags::Optional{Int}
    # metadata fields (when fetched with counts)
    uses::Optional{Int}
    max_uses::Optional{Int}
    max_age::Optional{Int}
    temporary::Optional{Bool}
    created_at::Optional{String}
end

"""
    InviteTargetUsersJob

Progress of the background job that processes a CSV of invite target users,
from [`get_invite_target_users_job_status`](@ref). `status` is one of
[`InviteTargetUsersJobStatuses`](@ref).
"""
@discord_struct InviteTargetUsersJob begin
    status::Int
    total_users::Int
    processed_users::Int
    created_at::String
    completed_at::Nullable{String}
    error_message::Maybe{String}
end

"""
    InviteTargetUsersJobStatuses

Values of `InviteTargetUsersJob.status`.

[Discord docs](https://docs.discord.com/developers/resources/invite#get-target-users-job-status)
"""
module InviteTargetUsersJobStatuses
    const UNSPECIFIED = 0
    const PROCESSING  = 1
    const COMPLETED   = 2
    const FAILED      = 3
end
