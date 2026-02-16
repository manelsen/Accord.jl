# Gateway Event Type Hierarchy
# All events inherit from AbstractEvent for multiple dispatch
#
# Internal module: Defines the complete hierarchy of Discord gateway event structs.
# Each event wraps the relevant Discord object(s) and inherits from AbstractEvent
# to enable Julia's multiple dispatch for event handling.

"""
    AbstractEvent
Base type for all Discord gateway events. Use this type when registering catch-all event handlers.
"""
abstract type AbstractEvent end
# --- Ready ---
"""
    ReadyEvent
Sent by Discord when the shard has successfully connected and identified.
Contains information about the bot user and the guilds it is in.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#ready)
"""
struct ReadyEvent <: AbstractEvent
    v::Int
    user::User
    guilds::Vector{UnavailableGuild}
    session_id::String
    resume_gateway_url::String
    shard::Optional{Vector{Int}}
    application::Any
end

StructTypes.StructType(::Type{ReadyEvent}) = StructTypes.Mutable()
StructTypes.omitempties(::Type{ReadyEvent}) = true

"""
    ResumedEvent
Sent by Discord when a shard has successfully resumed a disconnected session.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#resumed)
"""
struct ResumedEvent <: AbstractEvent end

# --- Channel Events ---

"""
    ChannelCreate
Sent when a new channel is created, relevant to the current user.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#channel-create)
"""
struct ChannelCreate <: AbstractEvent

    channel::DiscordChannel

end



"""
    ChannelUpdate
Sent when a channel is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#channel-update)
"""
struct ChannelUpdate <: AbstractEvent

    channel::DiscordChannel

end



"""
    ChannelDelete
Sent when a channel relevant to the current user is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#channel-delete)
"""
struct ChannelDelete <: AbstractEvent

    channel::DiscordChannel

end



"""
    ChannelPinsUpdate
Sent when a message is pinned or unpinned in a text channel.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#channel-pins-update)
"""
struct ChannelPinsUpdate <: AbstractEvent

    guild_id::Optional{Snowflake}

    channel_id::Snowflake

    last_pin_timestamp::Optional{String}

end



# --- Thread Events ---

"""
    ThreadCreate
Sent when a thread is created, relevant to the current user, or when the current user is added to a thread.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-create)
"""
struct ThreadCreate <: AbstractEvent

    channel::DiscordChannel

end



"""
    ThreadUpdate
Sent when a thread is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-update)
"""
struct ThreadUpdate <: AbstractEvent

    channel::DiscordChannel

end



"""
    ThreadDelete
Sent when a thread relevant to the current user is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-delete)
"""
struct ThreadDelete <: AbstractEvent

    id::Snowflake

    guild_id::Snowflake

    parent_id::Snowflake

    type::Int

end



"""
    ThreadListSync
Sent when the current user gains access to a channel, containing all active threads in that channel.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-list-sync)
"""
struct ThreadListSync <: AbstractEvent

    guild_id::Snowflake

    channel_ids::Optional{Vector{Snowflake}}

    threads::Vector{DiscordChannel}

    members::Vector{ThreadMember}

end



"""
    ThreadMemberUpdate
Sent when the thread member object for the current user is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-member-update)
"""
struct ThreadMemberUpdate <: AbstractEvent

    member::ThreadMember

    guild_id::Snowflake

end



"""
    ThreadMembersUpdate
Sent when anyone is added to or removed from a thread.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#thread-members-update)
"""
struct ThreadMembersUpdate <: AbstractEvent

    id::Snowflake

    guild_id::Snowflake

    member_count::Int

    added_members::Optional{Vector{ThreadMember}}

    removed_member_ids::Optional{Vector{Snowflake}}

end



# --- Guild Events ---

"""
    GuildCreate
Sent when a guild becomes available, or when the bot joins a new guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-create)
"""
struct GuildCreate <: AbstractEvent

    guild::Guild

end



"""
    GuildUpdate
Sent when a guild's properties are updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-update)
"""
struct GuildUpdate <: AbstractEvent

    guild::Guild

end



"""
    GuildDelete
Sent when a guild becomes unavailable, or when the bot leaves a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-delete)
"""
struct GuildDelete <: AbstractEvent

    guild::UnavailableGuild

end



"""
    GuildAuditLogEntryCreate
Sent when a new audit log entry is created in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-audit-log-entry-create)
"""
struct GuildAuditLogEntryCreate <: AbstractEvent

    entry::AuditLogEntry

    guild_id::Snowflake

end



"""
    GuildBanAdd
Sent when a user is banned from a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-ban-add)
"""
struct GuildBanAdd <: AbstractEvent

    guild_id::Snowflake

    user::User

end



"""
    GuildBanRemove
Sent when a user is unbanned from a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-ban-remove)
"""
struct GuildBanRemove <: AbstractEvent

    guild_id::Snowflake

    user::User

end



"""
    GuildEmojisUpdate
Sent when a guild's emojis are updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-emojis-update)
"""
struct GuildEmojisUpdate <: AbstractEvent

    guild_id::Snowflake

    emojis::Vector{Emoji}

end



"""
    GuildStickersUpdate
Sent when a guild's stickers are updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-stickers-update)
"""
struct GuildStickersUpdate <: AbstractEvent

    guild_id::Snowflake

    stickers::Vector{Sticker}

end



"""
    GuildIntegrationsUpdate
Sent when a guild's integrations are updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-integrations-update)
"""
struct GuildIntegrationsUpdate <: AbstractEvent

    guild_id::Snowflake

end



# --- Guild Member Events ---
"""
    GuildMemberAdd
Sent when a new user joins a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-member-add)
"""
struct GuildMemberAdd <: AbstractEvent
    member::Member
    guild_id::Snowflake
end

"""
    GuildMemberRemove
Sent when a user is removed from a guild (leave/kick/ban).
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-member-remove)
"""
struct GuildMemberRemove <: AbstractEvent
    guild_id::Snowflake
    user::User
end

"""
    GuildMemberUpdate
Sent when a guild member's roles, nickname, avatar, or timeout status is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-member-update)
"""
struct GuildMemberUpdate <: AbstractEvent
    guild_id::Snowflake
    roles::Vector{Snowflake}
    user::User
    nick::Optional{String}
    avatar::Optional{String}
    joined_at::Optional{String}
    premium_since::Optional{String}
    deaf::Optional{Bool}
    mute::Optional{Bool}
    pending::Optional{Bool}
    communication_disabled_until::Optional{String}
    flags::Optional{Int}
end

"""
    GuildMembersChunk
Sent in response to a Request Guild Members command.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-members-chunk)
"""
struct GuildMembersChunk <: AbstractEvent
    guild_id::Snowflake
    members::Vector{Member}
    chunk_index::Int
    chunk_count::Int
    not_found::Optional{Vector{Snowflake}}
    presences::Optional{Vector{Presence}}
    nonce::Optional{String}
end

# --- Guild Role Events ---
"""
    GuildRoleCreate
Sent when a guild role is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-role-create)
"""
struct GuildRoleCreate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end

"""
    GuildRoleUpdate
Sent when a guild role is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-role-update)
"""
struct GuildRoleUpdate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end

"""
    GuildRoleDelete
Sent when a guild role is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-role-delete)
"""
struct GuildRoleDelete <: AbstractEvent
    guild_id::Snowflake
    role_id::Snowflake
end

# --- Guild Scheduled Event Events ---
"""
    GuildScheduledEventCreate
Sent when a guild scheduled event is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-create)
"""
struct GuildScheduledEventCreate <: AbstractEvent
    event::ScheduledEvent
end

"""
    GuildScheduledEventUpdate
Sent when a guild scheduled event is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-update)
"""
struct GuildScheduledEventUpdate <: AbstractEvent
    event::ScheduledEvent
end

"""
    GuildScheduledEventDelete
Sent when a guild scheduled event is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-delete)
"""
struct GuildScheduledEventDelete <: AbstractEvent
    event::ScheduledEvent
end

"""
    GuildScheduledEventUserAdd
Sent when a user subscribes to a guild scheduled event.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-user-add)
"""
struct GuildScheduledEventUserAdd <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end

"""
    GuildScheduledEventUserRemove
Sent when a user unsubscribes from a guild scheduled event.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-scheduled-event-user-remove)
"""
struct GuildScheduledEventUserRemove <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end

# --- Soundboard Events ---
"""
    GuildSoundboardSoundCreate
Sent when a soundboard sound is created in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-soundboard-sound-create)
"""
struct GuildSoundboardSoundCreate <: AbstractEvent
    sound::SoundboardSound
end

"""
    GuildSoundboardSoundUpdate
Sent when a soundboard sound is updated in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-soundboard-sound-update)
"""
struct GuildSoundboardSoundUpdate <: AbstractEvent
    sound::SoundboardSound
end

"""
    GuildSoundboardSoundDelete
Sent when a soundboard sound is deleted from a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-soundboard-sound-delete)
"""
struct GuildSoundboardSoundDelete <: AbstractEvent
    sound_id::Snowflake
    guild_id::Snowflake
end

"""
    GuildSoundboardSoundsUpdate
Sent when soundboard sounds are updated in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#guild-soundboard-sounds-update)
"""
struct GuildSoundboardSoundsUpdate <: AbstractEvent
    guild_id::Snowflake
    soundboard_sounds::Vector{SoundboardSound}
end

"""
    SoundboardSounds
Sent when the bot joins a voice channel, containing all soundboard sounds for that guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#soundboard-sounds)
"""
struct SoundboardSounds <: AbstractEvent
    guild_id::Snowflake
    soundboard_sounds::Vector{SoundboardSound}
end

# --- Integration Events ---
"""
    IntegrationCreate
Sent when an integration is created in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#integration-create)
"""
struct IntegrationCreate <: AbstractEvent
    integration::Integration
    guild_id::Snowflake
end

"""
    IntegrationUpdate
Sent when an integration is updated in a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#integration-update)
"""
struct IntegrationUpdate <: AbstractEvent
    integration::Integration
    guild_id::Snowflake
end

"""
    IntegrationDelete
Sent when an integration is deleted from a guild.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#integration-delete)
"""
struct IntegrationDelete <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    application_id::Optional{Snowflake}
end

# --- Interaction Event ---
"""
    InteractionCreate
Sent when a user uses an application command or message component.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#interaction-create)
"""
struct InteractionCreate <: AbstractEvent
    interaction::Interaction
end

# --- Invite Events ---
"""
    InviteCreate
Sent when a new invite to a channel is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#invite-create)
"""
struct InviteCreate <: AbstractEvent
    channel_id::Snowflake
    code::String
    created_at::String
    guild_id::Optional{Snowflake}
    inviter::Optional{User}
    max_age::Int
    max_uses::Int
    target_type::Optional{Int}
    target_user::Optional{User}
    target_application::Optional{Any}
    temporary::Bool
    uses::Int
end

"""
    InviteDelete
Sent when an invite is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#invite-delete)
"""
struct InviteDelete <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    code::String
end

# --- Message Events ---
"""
    MessageCreate
Sent when a message is created in a channel.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-create)
"""
struct MessageCreate <: AbstractEvent
    message::Message
end

"""
    MessageUpdate
Sent when a message is updated (edited).
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-update)
"""
struct MessageUpdate <: AbstractEvent
    message::Message
end

"""
    MessageDelete
Sent when a message is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-delete)
"""
struct MessageDelete <: AbstractEvent
    id::Snowflake
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end

"""
    MessageDeleteBulk
Sent when multiple messages are deleted at once (bulk delete).
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-delete-bulk)
"""
struct MessageDeleteBulk <: AbstractEvent
    ids::Vector{Snowflake}
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end

# --- Message Reaction Events ---
"""
    MessageReactionAdd
Sent when a user adds a reaction to a message.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-reaction-add)
"""
struct MessageReactionAdd <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    member::Optional{Member}
    emoji::Emoji
    message_author_id::Optional{Snowflake}
    burst::Bool
    burst_colors::Optional{Vector{String}}
    type::Int
end

"""
    MessageReactionRemove
Sent when a user removes a reaction from a message.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove)
"""
struct MessageReactionRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    emoji::Emoji
    burst::Bool
    type::Int
end

"""
    MessageReactionRemoveAll
Sent when a user explicitly removes all reactions from a message.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-all)
"""
struct MessageReactionRemoveAll <: AbstractEvent
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
end

"""
    MessageReactionRemoveEmoji
Sent when a bot removes all instances of a given emoji reaction from a message.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-emoji)
"""
struct MessageReactionRemoveEmoji <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    message_id::Snowflake
    emoji::Emoji
end

# --- Message Poll Vote Events ---
"""
    MessagePollVoteAdd
Sent when a user votes in a poll.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-add)
"""
struct MessagePollVoteAdd <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end

"""
    MessagePollVoteRemove
Sent when a user removes their vote from a poll.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-remove)
"""
struct MessagePollVoteRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end

# --- Presence Update ---
"""
    PresenceUpdate
Sent when a user's presence or info (username, avatar) is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#presence-update)
"""
struct PresenceUpdate <: AbstractEvent
    presence::Presence
end

# --- Stage Instance Events ---
"""
    StageInstanceCreate
Sent when a Stage instance is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#stage-instance-create)
"""
struct StageInstanceCreate <: AbstractEvent
    stage::StageInstance
end

"""
    StageInstanceUpdate
Sent when a Stage instance is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#stage-instance-update)
"""
struct StageInstanceUpdate <: AbstractEvent
    stage::StageInstance
end

"""
    StageInstanceDelete
Sent when a Stage instance is deleted (closed).
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#stage-instance-delete)
"""
struct StageInstanceDelete <: AbstractEvent
    stage::StageInstance
end

# --- Typing ---
"""
    TypingStart
Sent when a user starts typing in a channel.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#typing-start)
"""
struct TypingStart <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    user_id::Snowflake
    timestamp::Int
    member::Optional{Member}
end

# --- User Update ---
"""
    UserUpdate
Sent when properties of the bot's user object change.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#user-update)
"""
struct UserUpdate <: AbstractEvent
    user::User
end

# --- Voice Events ---
"""
    VoiceStateUpdateEvent
Sent when a user joins/leaves/moves voice channels.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#voice-state-update)
"""
struct VoiceStateUpdateEvent <: AbstractEvent
    state::VoiceState
end

"""
    VoiceServerUpdate
Sent when a guild's voice server is updated. Used for connecting to voice.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#voice-server-update)
"""
struct VoiceServerUpdate <: AbstractEvent
    token::String
    guild_id::Snowflake
    endpoint::Nullable{String}
end

"""
    VoiceChannelEffectSend
Sent when a voice channel effect (e.g. emoji, animation) is sent.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#voice-channel-effect-send)
"""
struct VoiceChannelEffectSend <: AbstractEvent
    channel_id::Snowflake
    guild_id::Snowflake
    user_id::Snowflake
    emoji::Optional{Emoji}
    animation_type::Optional{Int}
    animation_id::Optional{Int}
    sound_id::Optional{Any}
    sound_volume::Optional{Float64}
end

# --- Webhooks Update ---
"""
    WebhooksUpdate
Sent when a guild channel's webhooks are created, updated, or deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#webhooks-update)
"""
struct WebhooksUpdate <: AbstractEvent
    guild_id::Snowflake
    channel_id::Snowflake
end

# --- Entitlement Events ---
"""
    EntitlementCreate
Sent when an entitlement is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#entitlement-create)
"""
struct EntitlementCreate <: AbstractEvent
    entitlement::Entitlement
end

"""
    EntitlementUpdate
Sent when an entitlement is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#entitlement-update)
"""
struct EntitlementUpdate <: AbstractEvent
    entitlement::Entitlement
end

"""
    EntitlementDelete
Sent when an entitlement is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#entitlement-delete)
"""
struct EntitlementDelete <: AbstractEvent
    entitlement::Entitlement
end

# --- Subscription Events ---
"""
    SubscriptionCreate
Sent when a subscription is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#subscription-create)
"""
struct SubscriptionCreate <: AbstractEvent
    subscription::Subscription
end

"""
    SubscriptionUpdate
Sent when a subscription is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#subscription-update)
"""
struct SubscriptionUpdate <: AbstractEvent
    subscription::Subscription
end

"""
    SubscriptionDelete
Sent when a subscription is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#subscription-delete)
"""
struct SubscriptionDelete <: AbstractEvent
    subscription::Subscription
end

# --- Auto Moderation Events ---
"""
    AutoModerationRuleCreate
Sent when an AutoMod rule is created.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#auto-moderation-rule-create)
"""
struct AutoModerationRuleCreate <: AbstractEvent
    rule::AutoModRule
end

"""
    AutoModerationRuleUpdate
Sent when an AutoMod rule is updated.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#auto-moderation-rule-update)
"""
struct AutoModerationRuleUpdate <: AbstractEvent
    rule::AutoModRule
end

"""
    AutoModerationRuleDelete
Sent when an AutoMod rule is deleted.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#auto-moderation-rule-delete)
"""
struct AutoModerationRuleDelete <: AbstractEvent
    rule::AutoModRule
end

"""
    AutoModerationActionExecution
Sent when an AutoMod rule is triggered and an action is executed.
[Discord docs](https://discord.com/developers/docs/topics/gateway-events#auto-moderation-action-execution)
"""
struct AutoModerationActionExecution <: AbstractEvent
    guild_id::Snowflake
    action::AutoModAction
    rule_id::Snowflake
    rule_trigger_type::Int
    user_id::Snowflake
    channel_id::Optional{Snowflake}
    message_id::Optional{Snowflake}
    alert_system_message_id::Optional{Snowflake}
    content::Optional{String}
    matched_keyword::Optional{String}
    matched_content::Optional{String}
end

# --- Unknown Event (fallback) ---
struct UnknownEvent <: AbstractEvent
    name::String
    data::Dict{String, Any}
end

# Event name → type mapping
const EVENT_TYPES = Dict{String, Type{<:AbstractEvent}}(
    "READY"                              => ReadyEvent,
    "RESUMED"                            => ResumedEvent,
    "CHANNEL_CREATE"                     => ChannelCreate,
    "CHANNEL_UPDATE"                     => ChannelUpdate,
    "CHANNEL_DELETE"                     => ChannelDelete,
    "CHANNEL_PINS_UPDATE"               => ChannelPinsUpdate,
    "THREAD_CREATE"                      => ThreadCreate,
    "THREAD_UPDATE"                      => ThreadUpdate,
    "THREAD_DELETE"                      => ThreadDelete,
    "THREAD_LIST_SYNC"                   => ThreadListSync,
    "THREAD_MEMBER_UPDATE"              => ThreadMemberUpdate,
    "THREAD_MEMBERS_UPDATE"             => ThreadMembersUpdate,
    "GUILD_CREATE"                       => GuildCreate,
    "GUILD_UPDATE"                       => GuildUpdate,
    "GUILD_DELETE"                       => GuildDelete,
    "GUILD_AUDIT_LOG_ENTRY_CREATE"      => GuildAuditLogEntryCreate,
    "GUILD_BAN_ADD"                      => GuildBanAdd,
    "GUILD_BAN_REMOVE"                  => GuildBanRemove,
    "GUILD_EMOJIS_UPDATE"               => GuildEmojisUpdate,
    "GUILD_STICKERS_UPDATE"             => GuildStickersUpdate,
    "GUILD_INTEGRATIONS_UPDATE"         => GuildIntegrationsUpdate,
    "GUILD_MEMBER_ADD"                   => GuildMemberAdd,
    "GUILD_MEMBER_REMOVE"              => GuildMemberRemove,
    "GUILD_MEMBER_UPDATE"              => GuildMemberUpdate,
    "GUILD_MEMBERS_CHUNK"              => GuildMembersChunk,
    "GUILD_ROLE_CREATE"                 => GuildRoleCreate,
    "GUILD_ROLE_UPDATE"                 => GuildRoleUpdate,
    "GUILD_ROLE_DELETE"                 => GuildRoleDelete,
    "GUILD_SCHEDULED_EVENT_CREATE"     => GuildScheduledEventCreate,
    "GUILD_SCHEDULED_EVENT_UPDATE"     => GuildScheduledEventUpdate,
    "GUILD_SCHEDULED_EVENT_DELETE"     => GuildScheduledEventDelete,
    "GUILD_SCHEDULED_EVENT_USER_ADD"   => GuildScheduledEventUserAdd,
    "GUILD_SCHEDULED_EVENT_USER_REMOVE" => GuildScheduledEventUserRemove,
    "GUILD_SOUNDBOARD_SOUND_CREATE"    => GuildSoundboardSoundCreate,
    "GUILD_SOUNDBOARD_SOUND_UPDATE"    => GuildSoundboardSoundUpdate,
    "GUILD_SOUNDBOARD_SOUND_DELETE"    => GuildSoundboardSoundDelete,
    "GUILD_SOUNDBOARD_SOUNDS_UPDATE"   => GuildSoundboardSoundsUpdate,
    "SOUNDBOARD_SOUNDS"                => SoundboardSounds,
    "INTEGRATION_CREATE"                => IntegrationCreate,
    "INTEGRATION_UPDATE"                => IntegrationUpdate,
    "INTEGRATION_DELETE"                => IntegrationDelete,
    "INTERACTION_CREATE"                => InteractionCreate,
    "INVITE_CREATE"                     => InviteCreate,
    "INVITE_DELETE"                     => InviteDelete,
    "MESSAGE_CREATE"                    => MessageCreate,
    "MESSAGE_UPDATE"                    => MessageUpdate,
    "MESSAGE_DELETE"                    => MessageDelete,
    "MESSAGE_DELETE_BULK"              => MessageDeleteBulk,
    "MESSAGE_REACTION_ADD"             => MessageReactionAdd,
    "MESSAGE_REACTION_REMOVE"          => MessageReactionRemove,
    "MESSAGE_REACTION_REMOVE_ALL"      => MessageReactionRemoveAll,
    "MESSAGE_REACTION_REMOVE_EMOJI"    => MessageReactionRemoveEmoji,
    "MESSAGE_POLL_VOTE_ADD"            => MessagePollVoteAdd,
    "MESSAGE_POLL_VOTE_REMOVE"         => MessagePollVoteRemove,
    "PRESENCE_UPDATE"                   => PresenceUpdate,
    "STAGE_INSTANCE_CREATE"            => StageInstanceCreate,
    "STAGE_INSTANCE_UPDATE"            => StageInstanceUpdate,
    "STAGE_INSTANCE_DELETE"            => StageInstanceDelete,
    "TYPING_START"                      => TypingStart,
    "USER_UPDATE"                       => UserUpdate,
    "VOICE_STATE_UPDATE"               => VoiceStateUpdateEvent,
    "VOICE_SERVER_UPDATE"              => VoiceServerUpdate,
    "VOICE_CHANNEL_EFFECT_SEND"        => VoiceChannelEffectSend,
    "WEBHOOKS_UPDATE"                   => WebhooksUpdate,
    "ENTITLEMENT_CREATE"               => EntitlementCreate,
    "ENTITLEMENT_UPDATE"               => EntitlementUpdate,
    "ENTITLEMENT_DELETE"               => EntitlementDelete,
    "SUBSCRIPTION_CREATE"              => SubscriptionCreate,
    "SUBSCRIPTION_UPDATE"              => SubscriptionUpdate,
    "SUBSCRIPTION_DELETE"              => SubscriptionDelete,
    "AUTO_MODERATION_RULE_CREATE"      => AutoModerationRuleCreate,
    "AUTO_MODERATION_RULE_UPDATE"      => AutoModerationRuleUpdate,
    "AUTO_MODERATION_RULE_DELETE"      => AutoModerationRuleDelete,
    "AUTO_MODERATION_ACTION_EXECUTION" => AutoModerationActionExecution,
)
