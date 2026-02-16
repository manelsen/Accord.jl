"""
    Connection

A connection that a user has attached to their account (e.g., Steam, Twitch, YouTube).

[Discord docs](https://discord.com/developers/docs/resources/user#connection-object)

# Fields
- `id::String` — ID of the connection account.
- `name::String` — Username of the connection account.
- `type::String` — Service of this connection (e.g., "youtube", "twitch").
- `revoked::Optional{Bool}` — Whether the connection is revoked.
- `integrations::Optional{Vector{Integration}}` — Array of partial server integrations. Only present for connections that are also webhooks.
- `verified::Bool` — Whether the connection is verified.
- `friend_sync::Bool` — Whether friend sync is enabled for this connection.
- `show_activity::Bool` — Whether activities related to this connection will be shown in presence updates.
- `two_way_link::Bool` — Whether this connection has a corresponding third party OAuth2 token.
- `visibility::Int` — Visibility of this connection. `0` for none (invisible), `1` for everyone.
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
