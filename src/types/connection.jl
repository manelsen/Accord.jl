@discord_struct Connection begin
    id::String
    name::String
    type::String
    revoked::Optional{Bool}
    integrations::Optional{Vector{Integration}}
    verified::Bool
    friend_sync::Bool
    show_activity::Bool
    two_way_link::Bool
    visibility::Int
end
