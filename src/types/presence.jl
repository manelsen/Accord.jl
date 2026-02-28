"""
    ActivityTimestamps

Start and end times for a user's [`Activity`](@ref).

# See Also
- [Discord API: Activity Timestamps](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps-structure)
"""
@discord_struct ActivityTimestamps begin
    start::Optional{Int}
    end_::Optional{Int}
end

"""
    ActivityEmoji

The emoji displayed in a user's status.

# See Also
- [Discord API: Activity Emoji](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-emoji-structure)
"""
@discord_struct ActivityEmoji begin
    name::String
    id::Optional{Snowflake}
    animated::Optional{Bool}
end

"""
    ActivityParty

Information about the party/group a user is currently in.

# See Also
- [Discord API: Activity Party](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-party-structure)
"""
@discord_struct ActivityParty begin
    id::Optional{String}
    size::Optional{Vector{Int}}
end

"""
    ActivityAssets

Images and hover text for a user's Rich Presence.

# See Also
- [Discord API: Activity Assets](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-assets-structure)
"""
@discord_struct ActivityAssets begin
    large_image::Optional{String}
    large_text::Optional{String}
    small_image::Optional{String}
    small_text::Optional{String}
end

"""
    ActivitySecrets

Secrets for joining or spectating a user's game.

# See Also
- [Discord API: Activity Secrets](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-secrets-structure)
"""
@discord_struct ActivitySecrets begin
    join::Optional{String}
    spectate::Optional{String}
    match::Optional{String}
end

"""
    ActivityButton

A custom button displayed in a user's Rich Presence.

# See Also
- [Discord API: Activity Buttons](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-buttons-structure)
"""
@discord_struct ActivityButton begin
    label::String
    url::String
end

"""
    Activity

Represents what a user is currently doing (playing a game, streaming, etc.).

# Fields
- `name::String`: The activity's name.
- `type::Int`: Activity type (see [`ActivityTypes`](@ref)).
- `url::Optional{String}`: Stream URL (if streaming).
- `details::Optional{String}`: What the player is doing.
- `state::Optional{String}`: The user's current party status.
- `emoji::Optional{ActivityEmoji}`: Status emoji.
- `party::Optional{ActivityParty}`: Party information.
- `assets::Optional{ActivityAssets}`: Images and hover text.
- `buttons::Optional{Vector{ActivityButton}}`: Custom Rich Presence buttons.

# See Also
- [Discord API: Activity Object](https://discord.com/developers/docs/topics/gateway-events#activity-object)
"""
@discord_struct Activity begin
    name::String
    type::Int
    url::Optional{String}
    created_at::Optional{Int}
    timestamps::Optional{ActivityTimestamps}
    application_id::Optional{Snowflake}
    details::Optional{String}
    state::Optional{String}
    emoji::Optional{ActivityEmoji}
    party::Optional{ActivityParty}
    assets::Optional{ActivityAssets}
    secrets::Optional{ActivitySecrets}
    instance::Optional{Bool}
    flags::Optional{Int}
    buttons::Optional{Vector{ActivityButton}}
end

"""
    ClientStatus

Active session statuses for each platform (desktop, mobile, web).

# See Also
- [Discord API: Client Status Object](https://discord.com/developers/docs/topics/gateway-events#client-status-object)
"""
@discord_struct ClientStatus begin
    desktop::Optional{String}
    mobile::Optional{String}
    web::Optional{String}
end

"""
    Presence

Represents a user's current status and activities.

# Fields
- `user::Any`: The user being updated (partial).
- `guild_id::Optional{Snowflake}`: Guild ID.
- `status::String`: The user's status (`online`, `dnd`, `idle`, `invisible`, `offline`).
- `activities::Vector{Activity}`: Current activities.
- `client_status::Optional{ClientStatus}`: Status per platform.

# See Also
- [Discord API: Presence Update Event](https://discord.com/developers/docs/topics/gateway-events#presence-update)
"""
@discord_struct Presence begin
    user::Any  # partial User object
    guild_id::Optional{Snowflake}
    status::String
    activities::Vector{Activity}
    client_status::Optional{ClientStatus}
end
