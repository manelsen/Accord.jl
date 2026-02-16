"""
    ActivityTimestamps

Unix timestamps for start and/or end of an activity.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps-structure)

# Fields
- `start::Optional{Int}` — Unix time in milliseconds of when the activity started.
- `end_::Optional{Int}` — Unix time in milliseconds of when the activity ends. Named `end_` to avoid conflict with Julia keyword.
"""
@discord_struct ActivityTimestamps begin
    start::Optional{Int}
    end_::Optional{Int}
end

"""
    ActivityEmoji

Emoji data for a custom status activity.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-emoji-structure)

# Fields
- `name::String` — name of the emoji.
- `id::Optional{Snowflake}` — ID of the emoji (for custom emojis).
- `animated::Optional{Bool}` — whether this emoji is animated.
"""
@discord_struct ActivityEmoji begin
    name::String
    id::Optional{Snowflake}
    animated::Optional{Bool}
end

"""
    ActivityParty

Information about the party (group) the user is in for this activity.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-party-structure)

# Fields
- `id::Optional{String}` — unique ID for the party.
- `size::Optional{Vector{Int}}` — array of two integers: current party size and maximum party size.
"""
@discord_struct ActivityParty begin
    id::Optional{String}
    size::Optional{Vector{Int}}
end

"""
    ActivityAssets

Images for the presence and their hover text.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-assets-structure)

# Fields
- `large_image::Optional{String}` — ID for a large asset of the activity, usually a splash art.
- `large_text::Optional{String}` — text displayed when hovering over the large image.
- `small_image::Optional{String}` — ID for a small asset of the activity, usually the app icon or user avatar.
- `small_text::Optional{String}` — text displayed when hovering over the small image.
"""
@discord_struct ActivityAssets begin
    large_image::Optional{String}
    large_text::Optional{String}
    small_image::Optional{String}
    small_text::Optional{String}
end

"""
    ActivitySecrets

Secrets for Rich Presence joining and spectating.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-secrets-structure)

# Fields
- `join::Optional{String}` — secret for joining a party.
- `spectate::Optional{String}` — secret for spectating a game.
- `match::Optional{String}` — secret for a specific instanced match.
"""
@discord_struct ActivitySecrets begin
    join::Optional{String}
    spectate::Optional{String}
    match::Optional{String}
end

"""
    ActivityButton

A button displayed in the activity.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-buttons-structure)

# Fields
- `label::String` — text shown on the button (1-32 characters).
- `url::String` — URL opened when clicking the button.
"""
@discord_struct ActivityButton begin
    label::String
    url::String
end

"""
    Activity

An activity is a representation of what a user is currently doing. Received in presence update events.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object)

# Fields
- `name::String` — activity's name.
- `type::Int` — activity type. See [`ActivityTypes`](@ref) module.
- `url::Optional{String}` — stream URL, validated when type is streaming.
- `created_at::Optional{Int}` — Unix timestamp of when the activity was added to the user's session.
- `timestamps::Optional{ActivityTimestamps}` — start and/or end of the game.
- `application_id::Optional{Snowflake}` — application ID for the game.
- `details::Optional{String}` — what the player is currently doing.
- `state::Optional{String}` — user's current party status or text used for custom status.
- `emoji::Optional{ActivityEmoji}` — emoji used for custom status.
- `party::Optional{ActivityParty}` — information for the current party.
- `assets::Optional{ActivityAssets}` — images for the presence and their hover texts.
- `secrets::Optional{ActivitySecrets}` — secrets for Rich Presence joining and spectating.
- `instance::Optional{Bool}` — whether the activity is an instanced game session.
- `flags::Optional{Int}` — activity flags bitwise ORed together. See `ActivityFlags` (bitwise flags for activity details).
- `buttons::Optional{Vector{ActivityButton}}` — custom buttons shown in the Rich Presence. Maximum 2 buttons.
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

Active session statuses for each platform (desktop, mobile, web) that the user is active on.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#client-status-object)

# Fields
- `desktop::Optional{String}` — user's status set for an active desktop application session.
- `mobile::Optional{String}` — user's status set for an active mobile application session.
- `web::Optional{String}` — user's status set for an active web application session.
"""
@discord_struct ClientStatus begin
    desktop::Optional{String}
    mobile::Optional{String}
    web::Optional{String}
end

"""
    Presence

A user's presence is their current status and activity. Received via `PRESENCE_UPDATE` gateway events.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#presence-update)

# Fields
- `user::Any` — user whose presence is being updated. May be a partial User object.
- `guild_id::Optional{Snowflake}` — ID of the guild this presence is for.
- `status::String` — user's current status. One of: `online`, `dnd`, `idle`, `invisible`, `offline`.
- `activities::Vector{Activity}` — user's current activities.
- `client_status::Optional{ClientStatus}` — user's platform-specific status (desktop, mobile, web).
"""
@discord_struct Presence begin
    user::Any  # partial User object
    guild_id::Optional{Snowflake}
    status::String
    activities::Vector{Activity}
    client_status::Optional{ClientStatus}
end
