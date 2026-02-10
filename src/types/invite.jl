@discord_struct InviteMetadata begin
    uses::Int
    max_uses::Int
    max_age::Int
    temporary::Bool
    created_at::String
end

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
