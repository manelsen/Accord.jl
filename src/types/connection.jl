"""
    Connection

Represents a third-party account (Steam, Twitch, etc.) connected to a Discord user.

# Fields
- `id::String`: ID of the connected account.
- `name::String`: Username of the connected account.
- `type::String`: Service name (e.g., "twitch").
- `revoked::Optional{Bool}`: Whether the connection is revoked.
- `verified::Bool`: Whether the connection is verified.
- `friend_sync::Bool`: Whether friends are synced.
- `show_activity::Bool`: Whether to show in presence updates.
- `visibility::Int`: Visibility (0=hidden, 1=everyone).

# See Also
- [Discord API: Connection Object](https://discord.com/developers/docs/resources/user#connection-object)
"""
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
