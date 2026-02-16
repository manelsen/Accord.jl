# Accord.jl — API Reference

> Discord API v10 library for Julia.
> Version: 0.1.0 | API Base: `https://discord.com/api/v10`

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Client](#2-client)
3. [Events](#3-events)
4. [State & Caching](#4-state--caching)
5. [REST — Messages](#5-rest--messages)
6. [REST — Channels](#6-rest--channels)
7. [REST — Guilds](#7-rest--guilds)
8. [REST — Members & Roles](#8-rest--members--roles)
9. [REST — Reactions](#9-rest--reactions)
10. [REST — Threads](#10-rest--threads)
11. [REST — Emoji & Stickers](#11-rest--emoji--stickers)
12. [REST — Webhooks](#12-rest--webhooks)
13. [REST — Invites](#13-rest--invites)
14. [REST — Audit Log](#14-rest--audit-log)
15. [REST — Auto-Moderation](#15-rest--auto-moderation)
16. [REST — Scheduled Events](#16-rest--scheduled-events)
17. [REST — Stage Instances](#17-rest--stage-instances)
18. [REST — Soundboard](#18-rest--soundboard)
19. [REST — Voice Regions](#19-rest--voice-regions)
20. [REST — SKUs, Entitlements & Subscriptions](#20-rest--skus-entitlements--subscriptions)
21. [Interactions — Slash Commands](#21-interactions--slash-commands)
22. [Interactions — Context & Responses](#22-interactions--context--responses)
23. [Interactions — Component Builders](#23-interactions--component-builders)
24. [Interactions — Decorator Macros](#24-interactions--decorator-macros)
25. [Interactions — Low-Level REST](#25-interactions--low-level-rest)
26. [Voice — Connection](#26-voice--connection)
27. [Voice — Audio Sources & Playback](#27-voice--audio-sources--playback)
28. [Voice — Opus Codec](#28-voice--opus-codec)
29. [Voice — UDP & RTP](#29-voice--udp--rtp)
30. [Voice — Encryption](#30-voice--encryption)
31. [Types — Core](#31-types--core)
32. [Types — Guild & Channel](#32-types--guild--channel)
33. [Types — Message & Embed](#33-types--message--embed)
34. [Types — Interaction](#34-types--interaction)
35. [Types — Presence & Voice](#35-types--presence--voice)
36. [Types — Miscellaneous](#36-types--miscellaneous)
37. [Enums](#37-enums)
38. [Flags & Intents](#38-flags--intents)
39. [Permissions](#39-permissions)
40. [Gateway Internals](#40-gateway-internals)

---

## 1. Quick Start

```julia
using Accord

client = Client(ENV["DISCORD_TOKEN"];
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)

on(client, ReadyEvent) do c, event
    @info "Online!" user=event.user.username
end

on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.content) && return
    if msg.content == "!ping"
        create_message(c, msg.channel_id; content="Pong!")
    end
end

start(client)
```

!!! note "Optional vs Nullable"
    Accord.jl uses two distinct type aliases for Discord's optional fields:
    
    - **`Optional{T}`** (`Union{T, Missing}`): Field may be absent from the JSON entirely. Check with `ismissing()`. Default value is `missing`.
    - **`Nullable{T}`** (`Union{T, Nothing}`): Field is present but may be JSON `null`. Check with `isnothing()`. Default value is `nothing`.
    
    This distinction mirrors Discord's API: some fields are omitted when not applicable, others are explicitly set to `null`.

### Type Aliases

```julia
const Optional{T} = Union{T, Missing}   # Field may be absent in JSON (default: missing)
const Nullable{T} = Union{T, Nothing}   # Field may be JSON null  (default: nothing)
```

### Snowflake

```julia
Snowflake(value::UInt64)
Snowflake(s::AbstractString)      # parse from string
Snowflake(n::Integer)

timestamp(s::Snowflake) -> DateTime   # creation time
string(s::Snowflake) -> String        # "123456789"
```

Snowflakes support `==`, `<`, `hash`, and are serialised as strings in JSON.

---

## 2. Client

### Constructor

```julia
Client(token::String;
    intents::Union{Intents, UInt32, Integer} = IntentAllNonPrivileged,
    num_shards::Int = 1,
    state::Any = nothing,
    guild_strategy::CacheStrategy   = CacheForever(),
    channel_strategy::CacheStrategy = CacheForever(),
    user_strategy::CacheStrategy    = CacheLRU(10_000),
    member_strategy::CacheStrategy  = CacheLRU(10_000),
    presence_strategy::CacheStrategy = CacheNever(),
)
```

The `"Bot "` prefix is added automatically if missing.

The `state` parameter accepts any user-defined value (struct, NamedTuple, Dict, etc.) that is
automatically available in command handlers via `ctx.state`.

### Lifecycle

```julia
start(client; blocking::Bool=true)    # Connect & run event loop
stop(client)                           # Disconnect gracefully
wait_until_ready(client)               # Block until READY received
```

### `wait_for` — Conversational State Machine

```julia
wait_for(check::Function, client, EventType; timeout::Real=30.0) -> Union{AbstractEvent, Nothing}
```

Wait for a specific gateway event that matches a predicate. Uses Julia's `Channel` and
`Timer` internally — only the current `Task` suspends, never the bot. Returns the matching
event, or `nothing` on timeout.

```julia
# Example: quiz flow
@slash_command client "quiz" "Start a quiz" function(ctx)
    respond(ctx; content="What color is the sky?")

    event = wait_for(client, MessageCreate; timeout=30) do evt
        evt.message.author.id == ctx.user.id &&
        evt.message.channel_id == ctx.channel_id
    end

    if isnothing(event)
        followup(ctx; content="⏰ Time's up!")
    elseif event.message.content == "blue"
        followup(ctx; content="✅ Correct!")
    else
        followup(ctx; content="❌ Wrong!")
    end
end
```

### Event Registration

```julia
on(handler::Function, client, EventType)
on_error(handler::Function, client)     # (client, event, error) -> nothing
```

Handlers receive `(client, event)`. Multiple handlers per event type are supported; all run independently.

!!! warning "Permissions Required"
    REST endpoints require specific Discord permissions:
    - `create_message` requires `SEND_MESSAGES` in the channel
    - `delete_message` requires `MANAGE_MESSAGES` (or be the message author)
    - `create_reaction` requires `ADD_REACTIONS` (but this is usually granted by default)
    - Most moderation actions require `KICK_MEMBERS`, `BAN_MEMBERS`, or `MANAGE_GUILD`

### Convenience REST (on Client)

```julia
create_message(client, channel_id; content="", embeds=Dict[], components=Dict[], files=nothing, tts=false, message_reference=nothing) -> Message
edit_message(client, channel_id, message_id; kwargs...) -> Message
delete_message(client, channel_id, message_id; reason=nothing)
create_reaction(client, channel_id, message_id, emoji::String)
get_channel(client, channel_id) -> DiscordChannel    # checks cache first
get_guild(client, guild_id) -> Guild                  # checks cache first
get_user(client, user_id) -> User                     # checks cache first
```

### Gateway Commands

```julia
update_voice_state(client, guild_id; channel_id=nothing, self_mute=false, self_deaf=false)
update_presence(client; status="online", activities=Dict[], afk=false, since=nothing)
request_guild_members(client, guild_id; query="", limit=0, presences=false, user_ids=nothing, nonce=nothing)
```

### Key Fields

| Field              | Type                  | Description                     |
|--------------------|-----------------------|---------------------------------|
| `client.token`     | `String`              | Bot token (with "Bot " prefix)  |
| `client.application_id` | `Nullable{Snowflake}` | Set after READY             |
| `client.intents`   | `UInt32`              | Gateway intents bitmask         |
| `client.state`     | `State`               | Cached Discord state            |
| `client.state_data` | `Any`               | User-injected state (`ctx.state`) |
| `client.command_tree` | `CommandTree`      | Registered slash commands        |
| `client.ratelimiter` | `RateLimiter`       | REST rate limiter               |
| `client.shards`    | `Vector{ShardInfo}`   | Gateway shards                  |
| `client.running`   | `Bool`                | Whether the client is running   |

---

!!! note "Intents Required for Events"
    To receive gateway events, you must:
    1. Declare the intent when creating the `Client` (e.g., `IntentGuildMessages`)
    2. Enable privileged intents in the Discord Developer Portal (for `IntentMessageContent`, `IntentGuildMembers`, `IntentGuildPresences`)
    
    Without the proper intent, events will not be sent to your bot even if you register handlers for them.

## 3. Events

All events inherit from `AbstractEvent`. Register handlers with `on(client, EventType)`.

### Connection

| Event           | Fields                                                                     |
|-----------------|----------------------------------------------------------------------------|
| `ReadyEvent`    | `v::Int`, `user::User`, `guilds::Vector{UnavailableGuild}`, `session_id::String`, `resume_gateway_url::String`, `shard::Optional{Vector{Int}}`, `application::Any` |
| `ResumedEvent`  | *(none)*                                                                   |

### Guilds

| Event                | Fields                                                    |
|----------------------|-----------------------------------------------------------|
| `GuildCreate`        | `guild::Guild`                                            |
| `GuildUpdate`        | `guild::Guild`                                            |
| `GuildDelete`        | `guild::UnavailableGuild`                                 |
| `GuildAuditLogEntryCreate` | `entry::AuditLogEntry`, `guild_id::Snowflake`      |
| `GuildBanAdd`        | `guild_id::Snowflake`, `user::User`                       |
| `GuildBanRemove`     | `guild_id::Snowflake`, `user::User`                       |
| `GuildEmojisUpdate`  | `guild_id::Snowflake`, `emojis::Vector{Emoji}`            |
| `GuildStickersUpdate`| `guild_id::Snowflake`, `stickers::Vector{Sticker}`        |
| `GuildIntegrationsUpdate` | `guild_id::Snowflake`                                |

### Members

| Event                | Fields                                                                     |
|----------------------|----------------------------------------------------------------------------|
| `GuildMemberAdd`     | `member::Member`, `guild_id::Snowflake`                                    |
| `GuildMemberRemove`  | `guild_id::Snowflake`, `user::User`                                        |
| `GuildMemberUpdate`  | `guild_id`, `roles::Vector{Snowflake}`, `user::User`, `nick`, `avatar`, `joined_at`, `premium_since`, `deaf`, `mute`, `pending`, `communication_disabled_until`, `flags` |
| `GuildMembersChunk`  | `guild_id`, `members::Vector{Member}`, `chunk_index`, `chunk_count`, `not_found`, `presences`, `nonce` |

### Roles

| Event            | Fields                                     |
|------------------|--------------------------------------------|
| `GuildRoleCreate`| `guild_id::Snowflake`, `role::Role`        |
| `GuildRoleUpdate`| `guild_id::Snowflake`, `role::Role`        |
| `GuildRoleDelete`| `guild_id::Snowflake`, `role_id::Snowflake`|

### Channels

| Event              | Fields                                                         |
|--------------------|----------------------------------------------------------------|
| `ChannelCreate`    | `channel::DiscordChannel`                                      |
| `ChannelUpdate`    | `channel::DiscordChannel`                                      |
| `ChannelDelete`    | `channel::DiscordChannel`                                      |
| `ChannelPinsUpdate`| `guild_id::Optional{Snowflake}`, `channel_id`, `last_pin_timestamp` |

### Threads

| Event                | Fields                                                            |
|----------------------|-------------------------------------------------------------------|
| `ThreadCreate`       | `channel::DiscordChannel`                                         |
| `ThreadUpdate`       | `channel::DiscordChannel`                                         |
| `ThreadDelete`       | `id`, `guild_id`, `parent_id`, `type` (all `Snowflake`/`Int`)    |
| `ThreadListSync`     | `guild_id`, `channel_ids`, `threads::Vector{DiscordChannel}`, `members::Vector{ThreadMember}` |
| `ThreadMemberUpdate` | `member::ThreadMember`, `guild_id`                                |
| `ThreadMembersUpdate`| `id`, `guild_id`, `member_count`, `added_members`, `removed_member_ids` |

### Messages

| Event               | Fields                                                          |
|---------------------|-----------------------------------------------------------------|
| `MessageCreate`     | `message::Message`                                              |
| `MessageUpdate`     | `message::Message`                                              |
| `MessageDelete`     | `id::Snowflake`, `channel_id`, `guild_id`                       |
| `MessageDeleteBulk` | `ids::Vector{Snowflake}`, `channel_id`, `guild_id`              |

### Reactions

| Event                        | Fields                                                            |
|------------------------------|-------------------------------------------------------------------|
| `MessageReactionAdd`         | `user_id`, `channel_id`, `message_id`, `guild_id`, `member`, `emoji::Emoji`, `message_author_id`, `burst::Bool`, `burst_colors`, `type::Int` |
| `MessageReactionRemove`      | `user_id`, `channel_id`, `message_id`, `guild_id`, `emoji`, `burst`, `type` |
| `MessageReactionRemoveAll`   | `channel_id`, `message_id`, `guild_id`                            |
| `MessageReactionRemoveEmoji` | `channel_id`, `guild_id`, `message_id`, `emoji`                   |

### Polls

| Event                  | Fields                                                        |
|------------------------|---------------------------------------------------------------|
| `MessagePollVoteAdd`   | `user_id`, `channel_id`, `message_id`, `guild_id`, `answer_id` |
| `MessagePollVoteRemove`| `user_id`, `channel_id`, `message_id`, `guild_id`, `answer_id` |

### Voice

| Event                    | Fields                                                         |
|--------------------------|----------------------------------------------------------------|
| `VoiceStateUpdateEvent`  | `state::VoiceState`                                            |
| `VoiceServerUpdate`      | `token::String`, `guild_id::Snowflake`, `endpoint::Nullable{String}` |
| `VoiceChannelEffectSend` | `channel_id`, `guild_id`, `user_id`, `emoji`, `animation_type`, `animation_id`, `sound_id`, `sound_volume` |

### Interactions, Presence, Typing, Users

| Event               | Fields                                                           |
|---------------------|------------------------------------------------------------------|
| `InteractionCreate` | `interaction::Interaction`                                       |
| `PresenceUpdate`    | `presence::Presence`                                             |
| `TypingStart`       | `channel_id`, `guild_id`, `user_id`, `timestamp::Int`, `member`  |
| `UserUpdate`        | `user::User`                                                     |
| `WebhooksUpdate`    | `guild_id`, `channel_id`                                         |

### Integrations

| Event               | Fields                                                   |
|---------------------|----------------------------------------------------------|
| `IntegrationCreate` | `integration::Integration`, `guild_id::Snowflake`        |
| `IntegrationUpdate` | `integration::Integration`, `guild_id::Snowflake`        |
| `IntegrationDelete` | `id`, `guild_id`, `application_id`                       |

### Invites

| Event          | Fields                                                                       |
|----------------|------------------------------------------------------------------------------|
| `InviteCreate` | `channel_id`, `code`, `created_at`, `guild_id`, `inviter`, `max_age`, `max_uses`, `target_type`, `target_user`, `target_application`, `temporary`, `uses` |
| `InviteDelete` | `channel_id`, `guild_id`, `code`                                             |

### Scheduled Events

| Event                              | Fields                                             |
|------------------------------------|----------------------------------------------------|
| `GuildScheduledEventCreate/Update/Delete` | `event::ScheduledEvent`                     |
| `GuildScheduledEventUserAdd/Remove`| `guild_scheduled_event_id`, `user_id`, `guild_id`  |

### Soundboard

| Event                              | Fields                                              |
|------------------------------------|-----------------------------------------------------|
| `GuildSoundboardSoundCreate/Update`| `sound::SoundboardSound`                            |
| `GuildSoundboardSoundDelete`       | `sound_id::Snowflake`, `guild_id::Snowflake`        |
| `GuildSoundboardSoundsUpdate`      | `guild_id`, `soundboard_sounds::Vector{SoundboardSound}` |

### Stage Instances

| Event                              | Fields                  |
|------------------------------------|-------------------------|
| `StageInstanceCreate/Update/Delete`| `stage::StageInstance`  |

### Entitlements & Subscriptions

| Event                                | Fields                           |
|--------------------------------------|----------------------------------|
| `EntitlementCreate/Update/Delete`    | `entitlement::Entitlement`       |
| `SubscriptionCreate/Update/Delete`   | `subscription::Subscription`     |

### Auto-Moderation

| Event                              | Fields                |
|------------------------------------|-----------------------|
| `AutoModerationRuleCreate/Update/Delete` | `rule::AutoModRule` |
| `AutoModerationActionExecution`    | `guild_id`, `action::AutoModAction`, `rule_id`, `rule_trigger_type`, `user_id`, `channel_id`, `message_id`, `alert_system_message_id`, `content`, `matched_keyword`, `matched_content` |

### Catch-All

| Event          | Fields                                       |
|----------------|----------------------------------------------|
| `UnknownEvent` | `name::String`, `data::Dict{String, Any}`    |

---

## 4. State & Caching

### Cache Strategies

```julia
CacheForever()            # Never evict
CacheNever()              # Never cache
CacheLRU(maxsize::Int)    # Least-recently-used eviction
CacheTTL(ttl_seconds::Float64)  # Time-based expiration
```

### State Structure

```julia
client.state::State

state.guilds        :: Store{Guild}                                    # guild_id → Guild
state.channels      :: Store{DiscordChannel}                           # channel_id → DiscordChannel
state.users         :: Store{User}                                     # user_id → User
state.members       :: Dict{Snowflake, Store{Member}}                  # guild_id → (user_id → Member)
state.roles         :: Dict{Snowflake, Store{Role}}                    # guild_id → (role_id → Role)
state.emojis        :: Dict{Snowflake, Store{Emoji}}                   # guild_id → (emoji_id → Emoji)
state.presences     :: Store{Presence}                                 # user_id → Presence
state.voice_states  :: Dict{Snowflake, Dict{Snowflake, VoiceState}}    # guild_id → (user_id → VoiceState)
state.me            :: Nullable{User}                                  # The bot's own User
```

### Store API

```julia
get(store, id::Snowflake, default=nothing)    # Retrieve (respects TTL/LRU)
store[id] = value                              # Insert (evicts if LRU full)
delete!(store, id)
haskey(store, id) -> Bool
keys(store), values(store), length(store)
```

State is updated automatically from gateway events. The cache is populated from `GuildCreate`, `MessageCreate`, `VoiceStateUpdateEvent`, etc.

---

## 5. REST — Messages

All low-level REST functions accept `(rl::RateLimiter, ...; token::String, ...)`. Use the [Client convenience wrappers](#2-client) when possible.

```julia
# Convenience (on Client)
create_message(client, channel_id; content, embeds, components, files, tts, message_reference) -> Message
edit_message(client, channel_id, message_id; kwargs...) -> Message
delete_message(client, channel_id, message_id; reason=nothing)

# Low-level
get_channel_messages(rl, channel_id; token, limit=50, around=nothing, before=nothing, after=nothing) -> Vector{Message}
get_channel_message(rl, channel_id, message_id; token) -> Message
create_message(rl, channel_id; token, body=Dict(), files=nothing) -> Message
edit_message(rl, channel_id, message_id; token, body, files=nothing) -> Message
delete_message(rl, channel_id, message_id; token, reason=nothing)
crosspost_message(rl, channel_id, message_id; token) -> Message
bulk_delete_messages(rl, channel_id; token, message_ids::Vector{Snowflake}, reason=nothing)
```

### Polls

```julia
get_answer_voters(rl, channel_id, message_id, answer_id; token, limit=25) -> Dict
end_poll(rl, channel_id, message_id; token) -> Message
```

---

## 6. REST — Channels

```julia
get_channel(rl, channel_id; token) -> DiscordChannel
modify_channel(rl, channel_id; token, body, reason=nothing) -> DiscordChannel
delete_channel(rl, channel_id; token, reason=nothing)
trigger_typing_indicator(rl, channel_id; token)
get_pinned_messages(rl, channel_id; token) -> Vector{Message}
pin_message(rl, channel_id, message_id; token, reason=nothing)
unpin_message(rl, channel_id, message_id; token, reason=nothing)
```

---

!!! warning "Guild Management Permissions"
    Guild operations require elevated permissions:
    - `modify_guild`, `delete_guild`: `MANAGE_GUILD` (delete requires owner)
    - `create_guild_channel`: `MANAGE_CHANNELS`
    - `create_guild_ban`, `remove_guild_ban`, `bulk_guild_ban`: `BAN_MEMBERS`
    - `get_guild_bans`: `BAN_MEMBERS`
    - `get_guild_invites`: `MANAGE_GUILD`

## 7. REST — Guilds

```julia
get_guild(rl, guild_id; token, with_counts=false) -> Guild
get_guild_preview(rl, guild_id; token) -> Guild
modify_guild(rl, guild_id; token, body, reason=nothing) -> Guild
delete_guild(rl, guild_id; token)
get_guild_channels(rl, guild_id; token) -> Vector{DiscordChannel}
create_guild_channel(rl, guild_id; token, body, reason=nothing) -> DiscordChannel
get_guild_invites(rl, guild_id; token) -> Vector{Invite}
get_guild_integrations(rl, guild_id; token) -> Vector{Integration}
get_guild_bans(rl, guild_id; token, limit=1000) -> Vector{Ban}
create_guild_ban(rl, guild_id, user_id; token, body=Dict(), reason=nothing)
remove_guild_ban(rl, guild_id, user_id; token, reason=nothing)
bulk_guild_ban(rl, guild_id; token, body) -> Dict
```

---

!!! warning "Member and Role Management Permissions"
    - `modify_guild_member`: `MANAGE_NICKNAMES` (for nicknames) or `MODERATE_MEMBERS` (for timeouts)
    - `add_guild_member_role`, `remove_guild_member_role`: `MANAGE_ROLES` (and bot's highest role must be above the target role)
    - `remove_guild_member` (kick): `KICK_MEMBERS`
    - `get_guild_member`: No special permission required
    - `list_guild_members`, `search_guild_members`: Requires privileged `GUILD_MEMBERS` intent

## 8. REST — Members & Roles

### Members

```julia
get_guild_member(rl, guild_id, user_id; token) -> Member
list_guild_members(rl, guild_id; token, limit=1, after=missing) -> Vector{Member}
search_guild_members(rl, guild_id; token, query_str, limit=1) -> Vector{Member}
modify_guild_member(rl, guild_id, user_id; token, body, reason=nothing) -> Member
add_guild_member_role(rl, guild_id, user_id, role_id; token, reason=nothing)
remove_guild_member_role(rl, guild_id, user_id, role_id; token, reason=nothing)
remove_guild_member(rl, guild_id, user_id; token, reason=nothing)
```

### Roles

```julia
get_guild_roles(rl, guild_id; token) -> Vector{Role}
create_guild_role(rl, guild_id; token, body=Dict(), reason=nothing) -> Role
modify_guild_role(rl, guild_id, role_id; token, body, reason=nothing) -> Role
delete_guild_role(rl, guild_id, role_id; token, reason=nothing)
```

### Users

```julia
get_current_user(rl; token) -> User
get_user(rl, user_id; token) -> User
modify_current_user(rl; token, body) -> User
create_dm(rl; token, recipient_id) -> DiscordChannel
```

---

## 9. REST — Reactions

```julia
create_reaction(rl, channel_id, message_id, emoji; token)
delete_own_reaction(rl, channel_id, message_id, emoji; token)
delete_user_reaction(rl, channel_id, message_id, emoji, user_id; token)
get_reactions(rl, channel_id, message_id, emoji; token, limit=25, type=0) -> Vector{User}
delete_all_reactions(rl, channel_id, message_id; token)
delete_all_reactions_for_emoji(rl, channel_id, message_id, emoji; token)
```

The `emoji` parameter is a URL-encoded string: `"👍"` or `"custom_emoji:123456"`.

---

## 10. REST — Threads

```julia
start_thread_from_message(rl, channel_id, message_id; token, body, reason=nothing) -> DiscordChannel
start_thread_without_message(rl, channel_id; token, body, reason=nothing) -> DiscordChannel
start_thread_in_forum(rl, channel_id; token, body, files=nothing, reason=nothing) -> DiscordChannel
```

---

## 11. REST — Emoji & Stickers

### Emoji

```julia
list_guild_emojis(rl, guild_id; token) -> Vector{Emoji}
create_guild_emoji(rl, guild_id; token, body, reason=nothing) -> Emoji
modify_guild_emoji(rl, guild_id, emoji_id; token, body, reason=nothing) -> Emoji
delete_guild_emoji(rl, guild_id, emoji_id; token, reason=nothing)
```

### Stickers

```julia
get_sticker(rl, sticker_id; token) -> Sticker
list_guild_stickers(rl, guild_id; token) -> Vector{Sticker}
create_guild_sticker(rl, guild_id; token, name, description, tags, file, reason=nothing) -> Sticker
```

---

## 12. REST — Webhooks

```julia
create_webhook(rl, channel_id; token, body, reason=nothing) -> Webhook
get_webhook(rl, webhook_id; token) -> Webhook
get_webhook_with_token(rl, webhook_id, webhook_token; token) -> Webhook
modify_webhook(rl, webhook_id; token, body, reason=nothing) -> Webhook
delete_webhook(rl, webhook_id; token, reason=nothing)
execute_webhook(rl, webhook_id, webhook_token; token, body, files=nothing, wait=false, thread_id=nothing) -> Message|HTTP.Response
get_webhook_message(rl, webhook_id, webhook_token, message_id; token) -> Message
edit_webhook_message(rl, webhook_id, webhook_token, message_id; token, body, files=nothing) -> Message
delete_webhook_message(rl, webhook_id, webhook_token, message_id; token)
```

---

## 13. REST — Invites

```julia
get_invite(rl, invite_code; token, with_counts=false, with_expiration=false, guild_scheduled_event_id=nothing) -> Invite
delete_invite(rl, invite_code; token, reason=nothing)
```

---

## 14. REST — Audit Log

```julia
get_guild_audit_log(rl, guild_id; token, user_id=nothing, action_type=nothing, before=nothing, after=nothing, limit=50) -> AuditLog
```

---

## 15. REST — Auto-Moderation

```julia
list_auto_moderation_rules(rl, guild_id; token) -> Vector{AutoModRule}
get_auto_moderation_rule(rl, guild_id, rule_id; token) -> AutoModRule
create_auto_moderation_rule(rl, guild_id; token, body, reason=nothing) -> AutoModRule
modify_auto_moderation_rule(rl, guild_id, rule_id; token, body, reason=nothing) -> AutoModRule
delete_auto_moderation_rule(rl, guild_id, rule_id; token, reason=nothing)
```

---

## 16. REST — Scheduled Events

```julia
list_scheduled_events(rl, guild_id; token, with_user_count=false) -> Vector{ScheduledEvent}
create_guild_scheduled_event(rl, guild_id; token, body, reason=nothing) -> ScheduledEvent
get_guild_scheduled_event(rl, guild_id, event_id; token, with_user_count=false) -> ScheduledEvent
modify_guild_scheduled_event(rl, guild_id, event_id; token, body, reason=nothing) -> ScheduledEvent
delete_guild_scheduled_event(rl, guild_id, event_id; token)
get_guild_scheduled_event_users(rl, guild_id, event_id; token, limit=100, with_member=false) -> Vector
```

---

## 17. REST — Stage Instances

```julia
create_stage_instance(rl; token, body, reason=nothing) -> StageInstance
get_stage_instance(rl, channel_id; token) -> StageInstance
modify_stage_instance(rl, channel_id; token, body, reason=nothing) -> StageInstance
delete_stage_instance(rl, channel_id; token, reason=nothing)
```

---

## 18. REST — Soundboard

```julia
list_default_soundboard_sounds(rl; token) -> Vector{SoundboardSound}
list_guild_soundboard_sounds(rl, guild_id; token) -> Dict
get_guild_soundboard_sound(rl, guild_id, sound_id; token) -> SoundboardSound
create_guild_soundboard_sound(rl, guild_id; token, body, reason=nothing) -> SoundboardSound
modify_guild_soundboard_sound(rl, guild_id, sound_id; token, body, reason=nothing) -> SoundboardSound
delete_guild_soundboard_sound(rl, guild_id, sound_id; token, reason=nothing)
send_soundboard_sound(rl, channel_id; token, body)
```

---

## 19. REST — Voice Regions

```julia
list_voice_regions(rl; token) -> Vector{VoiceRegion}
```

---

## 20. REST — SKUs, Entitlements & Subscriptions

```julia
# SKUs
list_skus(rl, application_id; token) -> Vector{SKU}

# Entitlements
list_entitlements(rl, application_id; token, user_id=nothing, sku_ids=nothing, before=nothing, after=nothing, limit=100, guild_id=nothing, exclude_ended=false, exclude_deleted=true) -> Vector{Entitlement}
create_test_entitlement(rl, application_id; token, body) -> Entitlement
delete_test_entitlement(rl, application_id, entitlement_id; token)
consume_entitlement(rl, application_id, entitlement_id; token)

# Subscriptions
list_sku_subscriptions(rl, sku_id; token, before=nothing, after=nothing, limit=100, user_id=nothing) -> Vector{Subscription}
get_sku_subscription(rl, sku_id, subscription_id; token) -> Subscription
```

---

## 21. Interactions — Slash Commands

### CommandTree

```julia
tree = CommandTree()

# Register commands
register_command!(tree, name, description, handler;
    type = ApplicationCommandTypes.CHAT_INPUT,
    options = [],
    guild_id = missing,
)

register_component!(tree, custom_id, handler)     # Button / Select
register_modal!(tree, custom_id, handler)          # Modal submit
register_autocomplete!(tree, command_name, handler) # Autocomplete

# Sync with Discord
sync_commands!(client, tree; guild_id=nothing)

# Dispatch (called automatically by Client on InteractionCreate)
dispatch_interaction!(tree, client, interaction)
```

The client's `command_tree` is available as `client.command_tree`. Handlers registered via `@slash_command` are added to it automatically.

### Command Options

```julia
command_option(;
    type::Int,           # ApplicationCommandOptionTypes.*
    name::String,
    description::String,
    required::Bool = false,
    choices::Vector = [],
    options::Vector = [],         # For sub-commands
    channel_types::Vector{Int} = Int[],
    min_value = nothing,
    max_value = nothing,
    min_length = nothing,
    max_length = nothing,
    autocomplete::Bool = false,
)
```

### Full Example

```julia
options = [
    command_option(
        type = ApplicationCommandOptionTypes.STRING,
        name = "query",
        description = "Search query",
        required = true,
        autocomplete = true,
    ),
    command_option(
        type = ApplicationCommandOptionTypes.INTEGER,
        name = "limit",
        description = "Max results",
        required = false,
        min_value = 1,
        max_value = 25,
    ),
]

register_command!(client.command_tree, "search", "Search something", function(ctx)
    defer(ctx)
    query = get_option(ctx, "query", "")
    limit = get_option(ctx, "limit", 10)
    # ...
    respond(ctx; content="Found results for: $query")
end; options)
```

---

## 22. Interactions — Context & Responses

Every interaction handler receives an `InteractionContext`:

```julia
struct InteractionContext
    client::Client
    interaction::Interaction
    responded::Ref{Bool}
    deferred::Ref{Bool}
end
```

### Reading Data

```julia
get_options(ctx) -> Dict{String, Any}       # All options
get_option(ctx, name, default=nothing)       # Single option value
custom_id(ctx) -> String                     # For components
selected_values(ctx) -> Vector{String}       # For select menus
modal_values(ctx) -> Dict{String, String}    # For modals
```

### Property Accessors

```julia
ctx.user      # User who triggered the interaction
ctx.author    # Alias for ctx.user
ctx.guild_id  # Guild ID (or missing in DMs)
ctx.channel_id # Channel ID
ctx.state     # User-injected state from Client(; state=...)
```

### Responding

```julia
respond(ctx; content="", embeds=[], components=[], ephemeral=false, tts=false, files=nothing)
defer(ctx; ephemeral=false)                  # "Thinking..." indicator
edit_response(ctx; content=nothing, embeds=nothing, components=nothing, files=nothing)
followup(ctx; content="", embeds=[], components=[], ephemeral=false, files=nothing)
show_modal(ctx; title::String, custom_id::String, components::Vector)
```

### Response Flow

1. **Immediate**: Call `respond(ctx; ...)` within 3 seconds
2. **Deferred**: Call `defer(ctx)` first, then `respond(ctx; ...)` later (up to 15 minutes)
3. **Follow-up**: After responding, use `followup(ctx; ...)` for additional messages
4. **Edit**: Use `edit_response(ctx; ...)` to modify the original response

---

## 23. Interactions — Component Builders

### Layout

```julia
action_row(components::Vector) -> Dict   # Container for buttons / selects
```

### Buttons

```julia
button(;
    label = "",
    custom_id = "",
    style = ButtonStyles.PRIMARY,   # PRIMARY | SECONDARY | SUCCESS | DANGER | LINK | PREMIUM
    emoji = nothing,                # Dict("name" => "👍") or Dict("id" => "123", "name" => "custom")
    url = "",                       # Only for LINK style
    disabled = false,
    sku_id = nothing,               # Only for PREMIUM style
) -> Dict
```

### Select Menus

```julia
string_select(; custom_id, options::Vector, placeholder="", min_values=1, max_values=1, disabled=false) -> Dict
select_option(; label, value, description="", emoji=nothing, default=false) -> Dict

user_select(; custom_id, placeholder="", min_values=1, max_values=1, disabled=false) -> Dict
role_select(; custom_id, placeholder="", min_values=1, max_values=1, disabled=false) -> Dict
mentionable_select(; custom_id, placeholder="", min_values=1, max_values=1, disabled=false) -> Dict
channel_select(; custom_id, channel_types=Int[], placeholder="", min_values=1, max_values=1, disabled=false) -> Dict
```

### Text Input (for Modals)

```julia
text_input(;
    custom_id,
    label,
    style = TextInputStyles.SHORT,   # SHORT | PARAGRAPH
    min_length = 0,
    max_length = 4000,
    required = true,
    value = "",
    placeholder = "",
) -> Dict
```

### Embeds

```julia
embed(;
    title = "",
    description = "",
    url = "",
    color = 0,             # Integer color, e.g. 0x5865F2
    timestamp = "",        # ISO8601 string
    footer = nothing,      # Dict("text" => "...", "icon_url" => "...")
    image = nothing,       # Dict("url" => "...")
    thumbnail = nothing,   # Dict("url" => "...")
    author = nothing,      # Dict("name" => "...", "url" => "...", "icon_url" => "...")
    fields = [],           # [Dict("name" => "...", "value" => "...", "inline" => true)]
) -> Dict
```

### Example: Button + Select + Modal

```julia
# Buttons
components = [
    action_row([
        button(label="Confirm", custom_id="confirm", style=ButtonStyles.SUCCESS),
        button(label="Cancel",  custom_id="cancel",  style=ButtonStyles.DANGER),
    ])
]
respond(ctx; content="Choose:", components)

# Handle button click
register_component!(client.command_tree, "confirm", function(ctx)
    respond(ctx; content="Confirmed!", ephemeral=true)
end)

# Modal
show_modal(ctx;
    title = "Feedback",
    custom_id = "feedback_modal",
    components = [
        action_row([text_input(custom_id="msg", label="Your message", style=TextInputStyles.PARAGRAPH)])
    ]
)

register_modal!(client.command_tree, "feedback_modal", function(ctx)
    vals = modal_values(ctx)
    respond(ctx; content="Thanks! You said: $(vals["msg"])")
end)
```

---

## 24. Interactions — Decorator Macros

Convenience macros that register handlers on `client.command_tree`:

```julia
# Pre-execution checks (guards) — stack before @slash_command
@check has_permissions(PermManageGuild)
@check is_owner()

# Slash command (global)
@slash_command client "name" "description" handler

# Slash command (guild-specific, instant)
@slash_command client guild_id "name" "description" handler

# Slash command with options
@slash_command client "name" "description" options handler

# Component handlers
@button_handler client "custom_id" handler
@select_handler client "custom_id" handler
@modal_handler client "custom_id" handler
@autocomplete  client "command_name" handler
```

Each `handler` is a `function(ctx::InteractionContext)`.

### Built-in Check Factories

| Check | Description |
|-------|-------------|
| `has_permissions(perms...)` | Require specific Discord permissions. Accepts `Permissions` values or symbols (`:MANAGE_GUILD`, `:BAN_MEMBERS`). |
| `is_owner()` | Require guild owner. |
| `is_in_guild()` | Require guild context (deny DMs). |

Checks run in order before the command handler. If any check returns `false`,
an ephemeral "permission denied" message is sent automatically (unless the check
responded directly).

```julia
# Example: Admin + guild-only command
@check is_in_guild()
@check has_permissions(:ADMINISTRATOR)
@slash_command client "config" "Server configuration" function(ctx)
    respond(ctx; content="Config panel", ephemeral=true)
end
```

---

## 25. Interactions — Low-Level REST

```julia
# Global commands
get_global_application_commands(rl, app_id; token, with_localizations=false) -> Vector{ApplicationCommand}
create_global_application_command(rl, app_id; token, body) -> ApplicationCommand
edit_global_application_command(rl, app_id, cmd_id; token, body) -> ApplicationCommand
delete_global_application_command(rl, app_id, cmd_id; token)
bulk_overwrite_global_application_commands(rl, app_id; token, body::Vector) -> Vector{ApplicationCommand}

# Guild commands
get_guild_application_commands(rl, app_id, guild_id; token, with_localizations=false) -> Vector{ApplicationCommand}
create_guild_application_command(rl, app_id, guild_id; token, body) -> ApplicationCommand
edit_guild_application_command(rl, app_id, guild_id, cmd_id; token, body) -> ApplicationCommand
delete_guild_application_command(rl, app_id, guild_id, cmd_id; token)
bulk_overwrite_guild_application_commands(rl, app_id, guild_id; token, body::Vector) -> Vector{ApplicationCommand}

# Interaction responses
create_interaction_response(rl, interaction_id, interaction_token; token, body, files=nothing)
get_original_interaction_response(rl, app_id, interaction_token; token) -> Message
edit_original_interaction_response(rl, app_id, interaction_token; token, body, files=nothing) -> Message
delete_original_interaction_response(rl, app_id, interaction_token; token)
create_followup_message(rl, app_id, interaction_token; token, body, files=nothing) -> Message
get_followup_message(rl, app_id, interaction_token, message_id; token) -> Message
edit_followup_message(rl, app_id, interaction_token, message_id; token, body, files=nothing) -> Message
delete_followup_message(rl, app_id, interaction_token, message_id; token)
```

---

## 26. Voice — Connection

### VoiceClient

```julia
mutable struct VoiceClient
    client::Client
    guild_id::Snowflake
    channel_id::Snowflake
    session::Nullable{VoiceGatewaySession}
    udp_socket::Nullable{UDPSocket}
    player::AudioPlayer
    sequence::UInt16
    timestamp::UInt32
    encryption_mode::String
    connected::Bool
end
```

### API

```julia
vc = VoiceClient(client, guild_id, channel_id)
connect!(vc)       # Full handshake: gateway → voice WS → UDP → ready
disconnect!(vc)    # Close everything and leave channel
play!(vc, source)  # Play an AbstractAudioSource -> AudioPlayer
stop!(vc)          # Stop playback + send not-speaking
```

### Connection Flow

1. Sends `VOICE_STATE_UPDATE` to the main gateway
2. Waits for `VoiceStateUpdateEvent` + `VoiceServerUpdate` events
3. Connects to voice WebSocket (`wss://{endpoint}/?v=8`)
4. Receives HELLO → sends IDENTIFY → receives READY (ssrc, ip, port, modes)
5. IP discovery via UDP (74-byte request/response)
6. Selects encryption mode → sends SELECT_PROTOCOL
7. Receives SESSION_DESCRIPTION (secret_key)

### VoiceGatewaySession

```julia
mutable struct VoiceGatewaySession
    ws::Any
    guild_id::Snowflake
    channel_id::Snowflake
    user_id::Snowflake
    session_id::String
    endpoint::String
    token::String
    ssrc::UInt32            # Our SSRC
    ip::String              # Voice server IP
    port::Int               # Voice server UDP port
    modes::Vector{String}   # Supported encryption modes
    secret_key::Vector{UInt8}
    heartbeat_interval::Float64
    heartbeat_task::Nullable{Task}
    connected::Bool
    ready::Base.Event
end

send_speaking(session, speaking::Bool; microphone=true)
send_select_protocol(session, our_ip, our_port, mode)
```

---

## 27. Voice — Audio Sources & Playback

### AbstractAudioSource Interface

```julia
abstract type AbstractAudioSource end

read_frame(source) -> Union{Vector{Int16}, Nothing}   # 960 × channels Int16 samples, or nothing when done
close_source(source)                                    # Cleanup
```

### Built-in Sources

```julia
# Play any format via FFmpeg (must be in PATH)
FFmpegSource(path::String; channels=2, volume=1.0)

# Raw PCM Int16 buffer (48kHz stereo)
PCMSource(data::Vector{Int16}; channels=2)

# Raw PCM file on disk (48kHz, 16-bit signed LE, stereo)
FileSource(path::String; channels=2)

# Generate silence frames (keep-alive)
SilenceSource(duration_ms::Int; channels=2)
```

### AudioPlayer

```julia
mutable struct AudioPlayer
    source::Nullable{AbstractAudioSource}
    encoder::Nullable{OpusEncoder}
    playing::Bool
    paused::Bool
    volume::Float64    # 0.0 to 2.0
    task::Nullable{Task}
end

play!(player, source, send_fn)   # send_fn(opus_data::Vector{UInt8})
stop!(player)
pause!(player)
resume!(player)
is_playing(player) -> Bool
```

Volume is applied to PCM before Opus encoding. The playback loop maintains a 20ms cadence per frame.

### Audio Specs

| Parameter      | Value                |
|---------------|----------------------|
| Sample rate    | 48,000 Hz            |
| Channels       | 2 (stereo)           |
| Bit depth      | 16-bit signed Int16  |
| Frame duration | 20 ms                |
| Frame size     | 960 samples/channel  |
| Total frame    | 1,920 Int16 samples  |

---

## 28. Voice — Opus Codec

### Constants

```julia
OPUS_SAMPLE_RATE       = 48000
OPUS_CHANNELS          = 2
OPUS_FRAME_DURATION_MS = 20
OPUS_FRAME_SIZE        = 960     # samples per channel per frame
OPUS_MAX_PACKET_SIZE   = 4000
```

### Encoder / Decoder

```julia
OpusEncoder(sample_rate=48000, channels=2, application=OPUS_APPLICATION_AUDIO)
OpusDecoder(sample_rate=48000, channels=2)

opus_encode(encoder, pcm::Vector{Int16}) -> Vector{UInt8}
opus_decode(decoder, data::Vector{UInt8}, frame_size=960) -> Vector{Int16}

set_bitrate!(encoder, bitrate::Int)
set_signal!(encoder, signal::Int)   # OPUS_SIGNAL_MUSIC=3002 or OPUS_SIGNAL_VOICE=3001
```

Application modes: `OPUS_APPLICATION_AUDIO=2049`, `OPUS_APPLICATION_VOIP=2048`, `OPUS_APPLICATION_LOWDELAY=2051`.

---

## 29. Voice — UDP & RTP

### RTP Packet

```julia
struct RTPPacket
    version_flags::UInt8     # 0x80 (version 2)
    payload_type::UInt8      # 0x78 (120 = Opus)
    sequence::UInt16
    timestamp::UInt32
    ssrc::UInt32
    payload::Vector{UInt8}
end

rtp_header(seq::UInt16, timestamp::UInt32, ssrc::UInt32) -> Vector{UInt8}   # 12 bytes
parse_rtp_header(data::Vector{UInt8}) -> RTPPacket
```

### UDP Functions

```julia
create_voice_udp(address, port) -> UDPSocket
ip_discovery(sock, address, port, ssrc) -> (our_ip::String, our_port::Int)
send_voice_packet(sock, address, port, header, encrypted_audio)
```

### Constants

```julia
RTP_HEADER_SIZE    = 12
RTP_VERSION        = 0x80
RTP_PAYLOAD_TYPE   = 0x78
```

---

## 30. Voice — Encryption

### Supported Modes (preference order)

1. `aead_xchacha20_poly1305_rtpsize`
2. `xsalsa20_poly1305_lite`
3. `xsalsa20_poly1305_suffix`
4. `xsalsa20_poly1305`

### Functions

```julia
select_encryption_mode(server_modes::Vector{String}) -> String

# xsalsa20_poly1305 (NaCl secretbox)
xsalsa20_poly1305_encrypt(key, nonce, plaintext) -> ciphertext
xsalsa20_poly1305_decrypt(key, nonce, ciphertext) -> plaintext
# key: 32 bytes, nonce: 24 bytes, MAC overhead: 16 bytes

# AEAD XChaCha20-Poly1305 (with associated data)
aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, aad) -> ciphertext
aead_xchacha20_poly1305_decrypt(key, nonce, ciphertext, aad) -> plaintext
# key: 32 bytes, nonce: 24 bytes, MAC overhead: 16 bytes

random_nonce(len=24) -> Vector{UInt8}
init_sodium()   # Called automatically on module load
```

### Encryption Layout per Mode

| Mode                                | Nonce source         | Packet layout                    |
|-------------------------------------|---------------------|----------------------------------|
| `xsalsa20_poly1305`                | RTP header (padded) | `header \| encrypted`             |
| `xsalsa20_poly1305_suffix`         | Random 24 bytes     | `header \| encrypted \| nonce`    |
| `xsalsa20_poly1305_lite`           | 4-byte sequence     | `header \| encrypted \| nonce[4]` |
| `aead_xchacha20_poly1305_rtpsize`  | Random 24 bytes     | `header \| encrypted \| nonce`    |

---

## 31. Types — Core

### Snowflake

```julia
struct Snowflake
    value::UInt64
end
# Constructors: Snowflake(::UInt64), Snowflake(::AbstractString), Snowflake(::Integer)
# Methods: timestamp(s), string(s), ==, <, hash
```

### User

| Field                  | Type                  |
|------------------------|-----------------------|
| `id`                   | `Snowflake`           |
| `username`             | `String`              |
| `discriminator`        | `Optional{String}`    |
| `global_name`          | `Optional{String}`    |
| `avatar`               | `Nullable{String}`    |
| `bot`                  | `Optional{Bool}`      |
| `system`               | `Optional{Bool}`      |
| `mfa_enabled`          | `Optional{Bool}`      |
| `banner`               | `Optional{String}`    |
| `accent_color`         | `Optional{Int}`       |
| `locale`               | `Optional{String}`    |
| `verified`             | `Optional{Bool}`      |
| `email`                | `Optional{String}`    |
| `flags`                | `Optional{Int}`       |
| `premium_type`         | `Optional{Int}`       |
| `public_flags`         | `Optional{Int}`       |
| `avatar_decoration_data` | `Optional{Any}`     |

### Member

| Field                            | Type                   |
|----------------------------------|------------------------|
| `user`                           | `Optional{User}`       |
| `nick`                           | `Optional{String}`     |
| `avatar`                         | `Optional{String}`     |
| `roles`                          | `Vector{Snowflake}`    |
| `joined_at`                      | `String`               |
| `premium_since`                  | `Optional{String}`     |
| `deaf`                           | `Optional{Bool}`       |
| `mute`                           | `Optional{Bool}`       |
| `flags`                          | `Int`                  |
| `pending`                        | `Optional{Bool}`       |
| `permissions`                    | `Optional{String}`     |
| `communication_disabled_until`   | `Optional{String}`     |

### Role

| Field            | Type                |
|------------------|---------------------|
| `id`             | `Snowflake`         |
| `name`           | `String`            |
| `color`          | `Int`               |
| `hoist`          | `Bool`              |
| `icon`           | `Optional{String}`  |
| `unicode_emoji`  | `Optional{String}`  |
| `position`       | `Int`               |
| `permissions`    | `String`            |
| `managed`        | `Bool`              |
| `mentionable`    | `Bool`              |
| `tags`           | `Optional{RoleTags}`|
| `flags`          | `Int`               |

### Emoji

| Field            | Type                       |
|------------------|----------------------------|
| `id`             | `Nullable{Snowflake}`      |
| `name`           | `Nullable{String}`         |
| `roles`          | `Optional{Vector{Snowflake}}` |
| `user`           | `Optional{User}`           |
| `require_colons` | `Optional{Bool}`           |
| `managed`        | `Optional{Bool}`           |
| `animated`       | `Optional{Bool}`           |
| `available`      | `Optional{Bool}`           |

---

## 32. Types — Guild & Channel

### Guild

| Field                        | Type                              |
|------------------------------|-----------------------------------|
| `id`                         | `Snowflake`                       |
| `name`                       | `String`                          |
| `icon`                       | `Nullable{String}`                |
| `splash`, `discovery_splash` | `Nullable{String}`                |
| `owner`                      | `Optional{Bool}`                  |
| `owner_id`                   | `Optional{Snowflake}`             |
| `permissions`                | `Optional{String}`                |
| `afk_channel_id`             | `Nullable{Snowflake}`             |
| `afk_timeout`                | `Optional{Int}`                   |
| `verification_level`         | `Optional{Int}`                   |
| `roles`                      | `Optional{Vector{Role}}`          |
| `emojis`                     | `Optional{Vector{Emoji}}`         |
| `features`                   | `Optional{Vector{String}}`        |
| `system_channel_id`          | `Nullable{Snowflake}`             |
| `rules_channel_id`           | `Nullable{Snowflake}`             |
| `premium_tier`               | `Optional{Int}`                   |
| `premium_subscription_count` | `Optional{Int}`                   |
| `preferred_locale`           | `Optional{String}`                |
| `nsfw_level`                 | `Optional{Int}`                   |
| `channels`                   | `Optional{Vector{DiscordChannel}}`|
| `threads`                    | `Optional{Vector{DiscordChannel}}`|
| `members`                    | `Optional{Vector{Member}}`        |
| `voice_states`               | `Optional{Vector{Any}}`           |
| *...and more (see source)*   |                                   |

### UnavailableGuild

| Field         | Type             |
|---------------|------------------|
| `id`          | `Snowflake`      |
| `unavailable` | `Optional{Bool}` |

### DiscordChannel

| Field                    | Type                               |
|--------------------------|------------------------------------|
| `id`                     | `Snowflake`                        |
| `type`                   | `Int` (see `ChannelTypes`)         |
| `guild_id`               | `Optional{Snowflake}`              |
| `position`               | `Optional{Int}`                    |
| `permission_overwrites`  | `Optional{Vector{Overwrite}}`      |
| `name`                   | `Optional{String}`                 |
| `topic`                  | `Optional{String}`                 |
| `nsfw`                   | `Optional{Bool}`                   |
| `last_message_id`        | `Optional{Snowflake}`              |
| `bitrate`                | `Optional{Int}`                    |
| `user_limit`             | `Optional{Int}`                    |
| `rate_limit_per_user`    | `Optional{Int}`                    |
| `recipients`             | `Optional{Vector{User}}`           |
| `parent_id`              | `Optional{Snowflake}`              |
| `thread_metadata`        | `Optional{ThreadMetadata}`         |
| `available_tags`         | `Optional{Vector{ForumTag}}`       |
| `applied_tags`           | `Optional{Vector{Snowflake}}`      |
| `flags`                  | `Optional{Int}`                    |
| *...and more (see source)* |                                  |

### Overwrite

| Field   | Type        |
|---------|-------------|
| `id`    | `Snowflake` |
| `type`  | `Int`       |
| `allow` | `String`    |
| `deny`  | `String`    |

---

## 33. Types — Message & Embed

### Message

| Field                  | Type                                    |
|------------------------|-----------------------------------------|
| `id`                   | `Snowflake`                             |
| `channel_id`           | `Snowflake`                             |
| `author`               | `Optional{User}`                        |
| `content`              | `Optional{String}`                      |
| `timestamp`            | `Optional{String}`                      |
| `edited_timestamp`     | `Optional{String}`                      |
| `tts`                  | `Optional{Bool}`                        |
| `mention_everyone`     | `Optional{Bool}`                        |
| `mentions`             | `Optional{Vector{User}}`               |
| `mention_roles`        | `Optional{Vector{Snowflake}}`           |
| `attachments`          | `Optional{Vector{Attachment}}`          |
| `embeds`               | `Optional{Vector{Embed}}`              |
| `reactions`            | `Optional{Vector{Reaction}}`            |
| `pinned`               | `Optional{Bool}`                        |
| `webhook_id`           | `Optional{Snowflake}`                   |
| `type`                 | `Optional{Int}` (see `MessageTypes`)    |
| `flags`                | `Optional{Int}`                         |
| `referenced_message`   | `Optional{Message}`                     |
| `thread`               | `Optional{DiscordChannel}`              |
| `components`           | `Optional{Vector{Component}}`           |
| `sticker_items`        | `Optional{Vector{StickerItem}}`         |
| `poll`                 | `Optional{Poll}`                        |
| `guild_id`             | `Optional{Snowflake}`                   |
| `member`               | `Optional{Member}`                      |

### Embed

| Field         | Type                       |
|---------------|----------------------------|
| `title`       | `Optional{String}`         |
| `type`        | `Optional{String}`         |
| `description` | `Optional{String}`         |
| `url`         | `Optional{String}`         |
| `timestamp`   | `Optional{String}`         |
| `color`       | `Optional{Int}`            |
| `footer`      | `Optional{EmbedFooter}`    |
| `image`       | `Optional{EmbedImage}`     |
| `thumbnail`   | `Optional{EmbedThumbnail}` |
| `video`       | `Optional{EmbedVideo}`     |
| `provider`    | `Optional{EmbedProvider}`  |
| `author`      | `Optional{EmbedAuthor}`    |
| `fields`      | `Optional{Vector{EmbedField}}` |

### EmbedField

| Field    | Type              |
|----------|-------------------|
| `name`   | `String`          |
| `value`  | `String`          |
| `inline` | `Optional{Bool}`  |

### Attachment

| Field           | Type               |
|-----------------|--------------------|
| `id`            | `Snowflake`        |
| `filename`      | `String`           |
| `content_type`  | `Optional{String}` |
| `size`          | `Int`              |
| `url`           | `String`           |
| `proxy_url`     | `String`           |
| `height`        | `Optional{Int}`    |
| `width`         | `Optional{Int}`    |
| `duration_secs` | `Optional{Float64}`|

### Component

| Field          | Type                             |
|----------------|----------------------------------|
| `type`         | `Int` (see `ComponentTypes`)     |
| `custom_id`    | `Optional{String}`               |
| `style`        | `Optional{Int}`                  |
| `label`        | `Optional{String}`               |
| `emoji`        | `Optional{Emoji}`                |
| `url`          | `Optional{String}`               |
| `disabled`     | `Optional{Bool}`                 |
| `components`   | `Optional{Vector{Component}}`    |
| `options`      | `Optional{Vector{SelectOption}}` |
| `placeholder`  | `Optional{String}`               |
| `min_values`   | `Optional{Int}`                  |
| `max_values`   | `Optional{Int}`                  |
| `value`        | `Optional{String}`               |
| `sku_id`       | `Optional{Snowflake}`            |

### Poll

| Field              | Type                     |
|--------------------|--------------------------|
| `question`         | `PollMedia`              |
| `answers`          | `Vector{PollAnswer}`     |
| `expiry`           | `Optional{String}`       |
| `allow_multiselect`| `Bool`                   |
| `layout_type`      | `Int`                    |
| `results`          | `Optional{PollResults}`  |

---

## 34. Types — Interaction

### Interaction

| Field             | Type                          |
|-------------------|-------------------------------|
| `id`              | `Snowflake`                   |
| `application_id`  | `Snowflake`                   |
| `type`            | `Int` (see `InteractionTypes`)|
| `data`            | `Optional{InteractionData}`   |
| `guild_id`        | `Optional{Snowflake}`         |
| `channel`         | `Optional{DiscordChannel}`    |
| `channel_id`      | `Optional{Snowflake}`         |
| `member`          | `Optional{Member}`            |
| `user`            | `Optional{User}`              |
| `token`           | `String`                      |
| `version`         | `Int`                         |
| `message`         | `Optional{Message}`           |
| `app_permissions` | `Optional{String}`            |
| `locale`          | `Optional{String}`            |
| `guild_locale`    | `Optional{String}`            |

### InteractionData

| Field            | Type                                     |
|------------------|------------------------------------------|
| `id`             | `Optional{Snowflake}`                    |
| `name`           | `Optional{String}`                       |
| `type`           | `Optional{Int}`                          |
| `resolved`       | `Optional{ResolvedData}`                 |
| `options`        | `Optional{Vector{InteractionDataOption}}`|
| `custom_id`      | `Optional{String}`                       |
| `component_type` | `Optional{Int}`                          |
| `values`         | `Optional{Vector{String}}`               |
| `target_id`      | `Optional{Snowflake}`                    |
| `components`     | `Optional{Vector{Component}}`            |

### ApplicationCommand

| Field                        | Type                                         |
|------------------------------|----------------------------------------------|
| `id`                         | `Snowflake`                                  |
| `type`                       | `Optional{Int}`                              |
| `application_id`             | `Snowflake`                                  |
| `guild_id`                   | `Optional{Snowflake}`                        |
| `name`                       | `String`                                     |
| `description`                | `String`                                     |
| `options`                    | `Optional{Vector{ApplicationCommandOption}}` |
| `default_member_permissions` | `Nullable{String}`                           |
| `nsfw`                       | `Optional{Bool}`                             |
| `version`                    | `Optional{Snowflake}`                        |

---

## 35. Types — Presence & Voice

### Presence

| Field           | Type                    |
|-----------------|-------------------------|
| `user`          | `Any`                   |
| `guild_id`      | `Optional{Snowflake}`   |
| `status`        | `String`                |
| `activities`    | `Vector{Activity}`      |
| `client_status` | `ClientStatus`          |

### Activity

| Field            | Type                          |
|------------------|-------------------------------|
| `name`           | `String`                      |
| `type`           | `Int` (see `ActivityTypes`)   |
| `url`            | `Optional{String}`            |
| `created_at`     | `Optional{Int}`               |
| `timestamps`     | `Optional{ActivityTimestamps}`|
| `application_id` | `Optional{Snowflake}`         |
| `details`        | `Optional{String}`            |
| `state`          | `Optional{String}`            |

### VoiceState

| Field                         | Type                  |
|-------------------------------|-----------------------|
| `guild_id`                    | `Optional{Snowflake}` |
| `channel_id`                  | `Nullable{Snowflake}` |
| `user_id`                     | `Snowflake`           |
| `member`                      | `Optional{Member}`    |
| `session_id`                  | `String`              |
| `deaf`                        | `Bool`                |
| `mute`                        | `Bool`                |
| `self_deaf`                   | `Bool`                |
| `self_mute`                   | `Bool`                |
| `self_stream`                 | `Optional{Bool}`      |
| `self_video`                  | `Bool`                |
| `suppress`                    | `Bool`                |
| `request_to_speak_timestamp`  | `Nullable{String}`    |

### VoiceRegion

| Field        | Type     |
|--------------|----------|
| `id`         | `String` |
| `name`       | `String` |
| `optimal`    | `Bool`   |
| `deprecated` | `Bool`   |
| `custom`     | `Bool`   |

---

## 36. Types — Miscellaneous

### Invite

| Field                        | Type                       |
|------------------------------|----------------------------|
| `type`                       | `Int`                      |
| `code`                       | `String`                   |
| `guild`                      | `Optional{Guild}`          |
| `channel`                    | `Nullable{DiscordChannel}` |
| `inviter`                    | `Optional{User}`           |
| `target_type`                | `Optional{Int}`            |
| `approximate_presence_count` | `Optional{Int}`            |
| `approximate_member_count`   | `Optional{Int}`            |
| `expires_at`                 | `Optional{String}`         |

### Webhook

| Field            | Type                    |
|------------------|-------------------------|
| `id`             | `Snowflake`             |
| `type`           | `Int`                   |
| `guild_id`       | `Optional{Snowflake}`   |
| `channel_id`     | `Nullable{Snowflake}`   |
| `user`           | `Optional{User}`        |
| `name`           | `Nullable{String}`      |
| `avatar`         | `Nullable{String}`      |
| `token`          | `Optional{String}`      |
| `application_id` | `Nullable{Snowflake}`   |
| `url`            | `Optional{String}`      |

### AuditLog

| Field                  | Type                          |
|------------------------|-------------------------------|
| `application_commands` | `Vector{ApplicationCommand}`  |
| `audit_log_entries`    | `Vector{AuditLogEntry}`       |
| `threads`              | `Vector{DiscordChannel}`      |
| `users`                | `Vector{User}`                |
| `webhooks`             | `Vector{Webhook}`             |

### AuditLogEntry

| Field         | Type                           |
|---------------|--------------------------------|
| `target_id`   | `Nullable{String}`             |
| `changes`     | `Optional{Vector{AuditLogChange}}` |
| `user_id`     | `Nullable{Snowflake}`          |
| `id`          | `Snowflake`                    |
| `action_type` | `Int`                          |
| `options`     | `Optional{AuditLogEntryInfo}`  |
| `reason`      | `Optional{String}`             |

### AutoModRule

| Field              | Type                          |
|--------------------|-------------------------------|
| `id`               | `Snowflake`                   |
| `guild_id`         | `Snowflake`                   |
| `name`             | `String`                      |
| `creator_id`       | `Snowflake`                   |
| `event_type`       | `Int`                         |
| `trigger_type`     | `Int`                         |
| `trigger_metadata` | `AutoModTriggerMetadata`      |
| `actions`          | `Vector{AutoModAction}`       |
| `enabled`          | `Bool`                        |
| `exempt_roles`     | `Vector{Snowflake}`           |
| `exempt_channels`  | `Vector{Snowflake}`           |

### ScheduledEvent

| Field                    | Type                         |
|--------------------------|------------------------------|
| `id`                     | `Snowflake`                  |
| `guild_id`               | `Snowflake`                  |
| `channel_id`             | `Nullable{Snowflake}`        |
| `name`                   | `String`                     |
| `description`            | `Optional{String}`           |
| `scheduled_start_time`   | `String`                     |
| `scheduled_end_time`     | `Nullable{String}`           |
| `privacy_level`          | `Int`                        |
| `status`                 | `Int`                        |
| `entity_type`            | `Int`                        |
| `entity_metadata`        | `Nullable{EntityMetadata}`   |
| `creator`                | `Optional{User}`             |
| `user_count`             | `Optional{Int}`              |
| `recurrence_rule`        | `Nullable{RecurrenceRule}`   |

### StageInstance

| Field                        | Type                    |
|------------------------------|-------------------------|
| `id`                         | `Snowflake`             |
| `guild_id`                   | `Snowflake`             |
| `channel_id`                 | `Snowflake`             |
| `topic`                      | `String`                |
| `privacy_level`              | `Int`                   |
| `guild_scheduled_event_id`   | `Nullable{Snowflake}`   |

### SoundboardSound

| Field        | Type                    |
|--------------|-------------------------|
| `name`       | `String`                |
| `sound_id`   | `Snowflake`             |
| `volume`     | `Float64`               |
| `emoji_id`   | `Nullable{Snowflake}`   |
| `emoji_name` | `Nullable{String}`      |
| `guild_id`   | `Optional{Snowflake}`   |
| `available`  | `Bool`                  |
| `user`       | `Optional{User}`        |

### Ban

| Field    | Type              |
|----------|-------------------|
| `reason` | `Nullable{String}`|
| `user`   | `User`            |

### Sticker

| Field         | Type                |
|---------------|---------------------|
| `id`          | `Snowflake`         |
| `name`        | `String`            |
| `description` | `Nullable{String}`  |
| `tags`        | `String`            |
| `type`        | `Int`               |
| `format_type` | `Int`               |
| `guild_id`    | `Optional{Snowflake}` |
| `user`        | `Optional{User}`    |

### SKU / Entitlement / Subscription

**SKU**: `id`, `type`, `application_id`, `name`, `slug`, `flags`

**Entitlement**: `id`, `sku_id`, `application_id`, `user_id`, `type`, `deleted`, `starts_at`, `ends_at`, `guild_id`, `consumed`

**Subscription**: `id`, `user_id`, `sku_ids`, `entitlement_ids`, `current_period_start`, `current_period_end`, `status`, `canceled_at`, `country`

### Integration

| Field                 | Type                           |
|-----------------------|--------------------------------|
| `id`                  | `Snowflake`                    |
| `name`                | `String`                       |
| `type`                | `String`                       |
| `enabled`             | `Optional{Bool}`               |
| `account`             | `IntegrationAccount`           |
| `user`                | `Optional{User}`               |
| `application`         | `Optional{IntegrationApplication}` |

### Onboarding

| Field                | Type                         |
|----------------------|------------------------------|
| `guild_id`           | `Snowflake`                  |
| `prompts`            | `Vector{OnboardingPrompt}`   |
| `default_channel_ids`| `Vector{Snowflake}`          |
| `enabled`            | `Bool`                       |
| `mode`               | `Int`                        |

---

## 37. Enums

All enums are modules with `const` integer (or string) values. Access as `ModuleName.CONSTANT`.

### Channel Types — `ChannelTypes`

| Constant              | Value |
|-----------------------|-------|
| `GUILD_TEXT`          | 0     |
| `DM`                 | 1     |
| `GUILD_VOICE`        | 2     |
| `GROUP_DM`           | 3     |
| `GUILD_CATEGORY`     | 4     |
| `GUILD_ANNOUNCEMENT` | 5     |
| `ANNOUNCEMENT_THREAD`| 10    |
| `PUBLIC_THREAD`      | 11    |
| `PRIVATE_THREAD`     | 12    |
| `GUILD_STAGE_VOICE`  | 13    |
| `GUILD_DIRECTORY`    | 14    |
| `GUILD_FORUM`        | 15    |
| `GUILD_MEDIA`        | 16    |

### Interaction Types — `InteractionTypes`

| Constant                          | Value |
|-----------------------------------|-------|
| `PING`                            | 1     |
| `APPLICATION_COMMAND`             | 2     |
| `MESSAGE_COMPONENT`              | 3     |
| `APPLICATION_COMMAND_AUTOCOMPLETE`| 4     |
| `MODAL_SUBMIT`                    | 5     |

### Interaction Callback Types — `InteractionCallbackTypes`

| Constant                                   | Value |
|--------------------------------------------|-------|
| `PONG`                                     | 1     |
| `CHANNEL_MESSAGE_WITH_SOURCE`              | 4     |
| `DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE`     | 5     |
| `DEFERRED_UPDATE_MESSAGE`                  | 6     |
| `UPDATE_MESSAGE`                           | 7     |
| `APPLICATION_COMMAND_AUTOCOMPLETE_RESULT`  | 8     |
| `MODAL`                                    | 9     |
| `PREMIUM_REQUIRED`                         | 10    |
| `LAUNCH_ACTIVITY`                          | 12    |

### Application Command Types — `ApplicationCommandTypes`

| Constant            | Value |
|---------------------|-------|
| `CHAT_INPUT`        | 1     |
| `USER`              | 2     |
| `MESSAGE`           | 3     |
| `PRIMARY_ENTRY_POINT`| 4    |

### Application Command Option Types — `ApplicationCommandOptionTypes`

| Constant            | Value |
|---------------------|-------|
| `SUB_COMMAND`       | 1     |
| `SUB_COMMAND_GROUP` | 2     |
| `STRING`            | 3     |
| `INTEGER`           | 4     |
| `BOOLEAN`           | 5     |
| `USER`              | 6     |
| `CHANNEL`           | 7     |
| `ROLE`              | 8     |
| `MENTIONABLE`       | 9     |
| `NUMBER`            | 10    |
| `ATTACHMENT`        | 11    |

### Component Types — `ComponentTypes`

| Constant            | Value |
|---------------------|-------|
| `ACTION_ROW`        | 1     |
| `BUTTON`            | 2     |
| `STRING_SELECT`     | 3     |
| `TEXT_INPUT`         | 4     |
| `USER_SELECT`       | 5     |
| `ROLE_SELECT`       | 6     |
| `MENTIONABLE_SELECT`| 7     |
| `CHANNEL_SELECT`    | 8     |
| `SECTION`           | 9     |
| `TEXT_DISPLAY`       | 10    |
| `THUMBNAIL`         | 11    |
| `MEDIA_GALLERY`     | 12    |
| `FILE`              | 13    |
| `SEPARATOR`         | 14    |
| `CONTAINER`         | 17    |

### Button Styles — `ButtonStyles`

| Constant    | Value |
|-------------|-------|
| `PRIMARY`   | 1     |
| `SECONDARY` | 2     |
| `SUCCESS`   | 3     |
| `DANGER`    | 4     |
| `LINK`      | 5     |
| `PREMIUM`   | 6     |

### Text Input Styles — `TextInputStyles`

| Constant    | Value |
|-------------|-------|
| `SHORT`     | 1     |
| `PARAGRAPH` | 2     |

### Activity Types — `ActivityTypes`

| Constant    | Value |
|-------------|-------|
| `GAME`      | 0     |
| `STREAMING` | 1     |
| `LISTENING` | 2     |
| `WATCHING`  | 3     |
| `CUSTOM`    | 4     |
| `COMPETING` | 5     |

### Other Enums

`MessageTypes`, `VerificationLevels`, `DefaultMessageNotificationLevels`, `ExplicitContentFilterLevels`, `MFALevels`, `NSFWLevels`, `PremiumTiers`, `PremiumTypes`, `StatusTypes`, `WebhookTypes`, `AuditLogEventTypes`, `AutoModTriggerTypes`, `AutoModEventTypes`, `AutoModActionTypes`, `ScheduledEventStatuses`, `ScheduledEventEntityTypes`, `StickerTypes`, `StickerFormatTypes`, `SKUTypes`, `EntitlementTypes`, `GuildFeatures`, `Locales`, `AllowedMentionTypes`, `SortOrderTypes`, `ForumLayoutTypes`, `OnboardingModes`

See `src/types/enums.jl` for all values.

---

## 38. Flags & Intents

Flags are UInt64-backed types with bitwise operators (`|`, `&`, `~`, `xor`). Check flags with `has_flag(a, b)`.

### Gateway Intents — `Intents`

```julia
IntentGuilds                       # 1 << 0
IntentGuildMembers                 # 1 << 1   (privileged)
IntentGuildModeration              # 1 << 2
IntentGuildExpressions             # 1 << 3
IntentGuildIntegrations            # 1 << 4
IntentGuildWebhooks                # 1 << 5
IntentGuildInvites                 # 1 << 6
IntentGuildVoiceStates             # 1 << 7
IntentGuildPresences               # 1 << 8   (privileged)
IntentGuildMessages                # 1 << 9
IntentGuildMessageReactions        # 1 << 10
IntentGuildMessageTyping           # 1 << 11
IntentDirectMessages               # 1 << 12
IntentDirectMessageReactions       # 1 << 13
IntentDirectMessageTyping          # 1 << 14
IntentMessageContent               # 1 << 15  (privileged)
IntentGuildScheduledEvents         # 1 << 16
IntentAutoModerationConfiguration  # 1 << 20
IntentAutoModerationExecution      # 1 << 21
IntentGuildMessagePolls            # 1 << 24
IntentDirectMessagePolls           # 1 << 25

IntentAllNonPrivileged   # All non-privileged intents combined
IntentAll                # All intents (including privileged)
```

Usage: `intents = IntentGuilds | IntentGuildMessages | IntentMessageContent`

### Permissions — `Permissions`

```julia
PermCreateInstantInvite    # 1 << 0
PermKickMembers            # 1 << 1
PermBanMembers             # 1 << 2
PermAdministrator          # 1 << 3
PermManageChannels         # 1 << 4
PermManageGuild            # 1 << 5
PermAddReactions           # 1 << 6
PermViewAuditLog           # 1 << 7
PermViewChannel            # 1 << 10
PermSendMessages           # 1 << 11
PermManageMessages         # 1 << 13
PermEmbedLinks             # 1 << 14
PermAttachFiles            # 1 << 15
PermReadMessageHistory     # 1 << 16
PermMentionEveryone        # 1 << 17
PermConnect                # 1 << 20
PermSpeak                  # 1 << 21
PermMuteMembers            # 1 << 22
PermDeafenMembers          # 1 << 23
PermMoveMembers            # 1 << 24
PermManageRoles            # 1 << 28
PermManageWebhooks         # 1 << 29
PermManageGuildExpressions # 1 << 30
PermUseApplicationCommands # 1 << 31
PermManageEvents           # 1 << 33
PermManageThreads          # 1 << 34
PermSendMessagesInThreads  # 1 << 38
PermModerateMembers        # 1 << 40
PermSendVoiceMessages      # 1 << 46
PermSendPolls              # 1 << 49
# ... and more (see src/types/flags.jl)
```

### Message Flags — `MessageFlags`

```julia
MsgFlagEphemeral         # 1 << 6
MsgFlagSuppressEmbeds    # 1 << 2
MsgFlagSuppressNotifications  # 1 << 12
MsgFlagIsVoiceMessage    # 1 << 13
```

### Other Flag Types

`UserFlags`, `SystemChannelFlags`, `ChannelFlags`, `GuildMemberFlags`, `RoleFlags`, `AttachmentFlags`

---

## 39. Permissions

### Helper Functions

```julia
compute_base_permissions(
    member_roles::Vector{Snowflake},
    guild_roles::Vector{Role},
    owner_id::Snowflake,
    user_id::Snowflake
) -> Permissions

compute_channel_permissions(
    base::Permissions,
    member_roles::Vector{Snowflake},
    overwrites::Vector{Overwrite},
    guild_id::Snowflake,
    user_id::Snowflake
) -> Permissions
```

### Usage

```julia
# Check if a member has a permission
perms = compute_base_permissions(member.roles, guild_roles, guild.owner_id, user.id)
channel_perms = compute_channel_permissions(perms, member.roles, channel.permission_overwrites, guild.id, user.id)

if has_flag(channel_perms, PermSendMessages)
    # User can send messages
end
```

---

## 40. Gateway Internals

Normally you don't interact with these directly. Documented for advanced use cases.

### GatewayOpcodes

| Constant                | Value | Direction |
|-------------------------|-------|-----------|
| `DISPATCH`              | 0     | Receive   |
| `HEARTBEAT`             | 1     | Both      |
| `IDENTIFY`              | 2     | Send      |
| `PRESENCE_UPDATE`       | 3     | Send      |
| `VOICE_STATE_UPDATE`    | 4     | Send      |
| `RESUME`                | 6     | Send      |
| `RECONNECT`             | 7     | Receive   |
| `REQUEST_GUILD_MEMBERS` | 8     | Send      |
| `INVALID_SESSION`       | 9     | Receive   |
| `HELLO`                 | 10    | Receive   |
| `HEARTBEAT_ACK`         | 11    | Receive   |

### VoiceOpcodes

| Constant              | Value | Direction |
|-----------------------|-------|-----------|
| `IDENTIFY`            | 0     | Send      |
| `SELECT_PROTOCOL`     | 1     | Send      |
| `READY`               | 2     | Receive   |
| `HEARTBEAT`           | 3     | Send      |
| `SESSION_DESCRIPTION` | 4     | Receive   |
| `SPEAKING`            | 5     | Both      |
| `HEARTBEAT_ACK`       | 6     | Receive   |
| `RESUME`              | 7     | Send      |
| `HELLO`               | 8     | Receive   |
| `RESUMED`             | 9     | Receive   |
| `CLIENT_DISCONNECT`   | 13    | Receive   |

### GatewaySession

```julia
mutable struct GatewaySession
    ws::Any
    session_id::Nullable{String}
    resume_gateway_url::Nullable{String}
    seq::Nullable{Int}
    heartbeat_task::Nullable{Task}
    connected::Bool
end
```

### ShardInfo

```julia
mutable struct ShardInfo
    id::Int
    total::Int
    task::Nullable{Task}
    session::GatewaySession
    events::Channel{AbstractEvent}   # Shared across all shards
    commands::Channel{GatewayCommand}
    ready::Base.Event
end
```

Accord.jl runs an automatic **Supervisor Task** that monitors all shards every 5 seconds. If a shard's task dies unexpectedly while the client is running, the supervisor will automatically restart it.

shard_for_guild(guild_id, num_shards) = (guild_id.value >> 22) % num_shards
```

### GatewayCommand

```julia
struct GatewayCommand
    op::Int
    data::Any
end
```

Used internally to send commands to the gateway (voice state, presence, etc.).

---

*Generated from Accord.jl source code. For the latest version, see the source files in `src/`.*
