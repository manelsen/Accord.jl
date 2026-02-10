# Gateway Event Type Hierarchy
# All events inherit from AbstractEvent for multiple dispatch

abstract type AbstractEvent end

# --- Ready ---
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

struct ResumedEvent <: AbstractEvent end

# --- Channel Events ---
struct ChannelCreate <: AbstractEvent
    channel::DiscordChannel
end
struct ChannelUpdate <: AbstractEvent
    channel::DiscordChannel
end
struct ChannelDelete <: AbstractEvent
    channel::DiscordChannel
end
struct ChannelPinsUpdate <: AbstractEvent
    guild_id::Optional{Snowflake}
    channel_id::Snowflake
    last_pin_timestamp::Optional{String}
end

# --- Thread Events ---
struct ThreadCreate <: AbstractEvent
    channel::DiscordChannel
end
struct ThreadUpdate <: AbstractEvent
    channel::DiscordChannel
end
struct ThreadDelete <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    parent_id::Snowflake
    type::Int
end

struct ThreadListSync <: AbstractEvent
    guild_id::Snowflake
    channel_ids::Optional{Vector{Snowflake}}
    threads::Vector{DiscordChannel}
    members::Vector{ThreadMember}
end

struct ThreadMemberUpdate <: AbstractEvent
    member::ThreadMember
    guild_id::Snowflake
end

struct ThreadMembersUpdate <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    member_count::Int
    added_members::Optional{Vector{ThreadMember}}
    removed_member_ids::Optional{Vector{Snowflake}}
end

# --- Guild Events ---
struct GuildCreate <: AbstractEvent
    guild::Guild
end
struct GuildUpdate <: AbstractEvent
    guild::Guild
end
struct GuildDelete <: AbstractEvent
    guild::UnavailableGuild
end

struct GuildAuditLogEntryCreate <: AbstractEvent
    entry::AuditLogEntry
    guild_id::Snowflake
end

struct GuildBanAdd <: AbstractEvent
    guild_id::Snowflake
    user::User
end
struct GuildBanRemove <: AbstractEvent
    guild_id::Snowflake
    user::User
end

struct GuildEmojisUpdate <: AbstractEvent
    guild_id::Snowflake
    emojis::Vector{Emoji}
end

struct GuildStickersUpdate <: AbstractEvent
    guild_id::Snowflake
    stickers::Vector{Sticker}
end

struct GuildIntegrationsUpdate <: AbstractEvent
    guild_id::Snowflake
end

# --- Guild Member Events ---
struct GuildMemberAdd <: AbstractEvent
    member::Member
    guild_id::Snowflake
end
struct GuildMemberRemove <: AbstractEvent
    guild_id::Snowflake
    user::User
end
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
struct GuildRoleCreate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end
struct GuildRoleUpdate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end
struct GuildRoleDelete <: AbstractEvent
    guild_id::Snowflake
    role_id::Snowflake
end

# --- Guild Scheduled Event Events ---
struct GuildScheduledEventCreate <: AbstractEvent
    event::ScheduledEvent
end
struct GuildScheduledEventUpdate <: AbstractEvent
    event::ScheduledEvent
end
struct GuildScheduledEventDelete <: AbstractEvent
    event::ScheduledEvent
end
struct GuildScheduledEventUserAdd <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end
struct GuildScheduledEventUserRemove <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end

# --- Soundboard Events ---
struct GuildSoundboardSoundCreate <: AbstractEvent
    sound::SoundboardSound
end
struct GuildSoundboardSoundUpdate <: AbstractEvent
    sound::SoundboardSound
end
struct GuildSoundboardSoundDelete <: AbstractEvent
    sound_id::Snowflake
    guild_id::Snowflake
end
struct GuildSoundboardSoundsUpdate <: AbstractEvent
    guild_id::Snowflake
    soundboard_sounds::Vector{SoundboardSound}
end
struct SoundboardSounds <: AbstractEvent
    guild_id::Snowflake
    soundboard_sounds::Vector{SoundboardSound}
end

# --- Integration Events ---
struct IntegrationCreate <: AbstractEvent
    integration::Integration
    guild_id::Snowflake
end
struct IntegrationUpdate <: AbstractEvent
    integration::Integration
    guild_id::Snowflake
end
struct IntegrationDelete <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    application_id::Optional{Snowflake}
end

# --- Interaction Event ---
struct InteractionCreate <: AbstractEvent
    interaction::Interaction
end

# --- Invite Events ---
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
struct InviteDelete <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    code::String
end

# --- Message Events ---
struct MessageCreate <: AbstractEvent
    message::Message
end
struct MessageUpdate <: AbstractEvent
    message::Message
end
struct MessageDelete <: AbstractEvent
    id::Snowflake
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end
struct MessageDeleteBulk <: AbstractEvent
    ids::Vector{Snowflake}
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end

# --- Message Reaction Events ---
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
struct MessageReactionRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    emoji::Emoji
    burst::Bool
    type::Int
end
struct MessageReactionRemoveAll <: AbstractEvent
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
end
struct MessageReactionRemoveEmoji <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    message_id::Snowflake
    emoji::Emoji
end

# --- Message Poll Vote Events ---
struct MessagePollVoteAdd <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end
struct MessagePollVoteRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end

# --- Presence Update ---
struct PresenceUpdate <: AbstractEvent
    presence::Presence
end

# --- Stage Instance Events ---
struct StageInstanceCreate <: AbstractEvent
    stage::StageInstance
end
struct StageInstanceUpdate <: AbstractEvent
    stage::StageInstance
end
struct StageInstanceDelete <: AbstractEvent
    stage::StageInstance
end

# --- Typing ---
struct TypingStart <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    user_id::Snowflake
    timestamp::Int
    member::Optional{Member}
end

# --- User Update ---
struct UserUpdate <: AbstractEvent
    user::User
end

# --- Voice Events ---
struct VoiceStateUpdateEvent <: AbstractEvent
    state::VoiceState
end
struct VoiceServerUpdate <: AbstractEvent
    token::String
    guild_id::Snowflake
    endpoint::Nullable{String}
end
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
struct WebhooksUpdate <: AbstractEvent
    guild_id::Snowflake
    channel_id::Snowflake
end

# --- Entitlement Events ---
struct EntitlementCreate <: AbstractEvent
    entitlement::Entitlement
end
struct EntitlementUpdate <: AbstractEvent
    entitlement::Entitlement
end
struct EntitlementDelete <: AbstractEvent
    entitlement::Entitlement
end

# --- Subscription Events ---
struct SubscriptionCreate <: AbstractEvent
    subscription::Subscription
end
struct SubscriptionUpdate <: AbstractEvent
    subscription::Subscription
end
struct SubscriptionDelete <: AbstractEvent
    subscription::Subscription
end

# --- Auto Moderation Events ---
struct AutoModerationRuleCreate <: AbstractEvent
    rule::AutoModRule
end
struct AutoModerationRuleUpdate <: AbstractEvent
    rule::AutoModRule
end
struct AutoModerationRuleDelete <: AbstractEvent
    rule::AutoModRule
end
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
