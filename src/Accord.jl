module Accord

# === Constants ===
const API_VERSION = 10
const API_BASE = "https://discord.com/api/v$(API_VERSION)"
const ACCORD_VERSION = v"0.1.0"
const USER_AGENT = "DiscordBot (Accord.jl, $ACCORD_VERSION)"

# === Type aliases ===
const Optional{T} = Union{T, Missing}
const Nullable{T} = Union{T, Nothing}

# === Dependencies ===
using Dates
using Logging
using Sockets

import HTTP
import JSON3
import StructTypes
import CodecZlib
using PrecompileTools
import LRUCache
import Opus_jll
import libsodium_jll

# === Types (order matters for dependencies) ===
include("types/macros.jl")
include("types/snowflake.jl")
include("types/enums.jl")
include("types/flags.jl")
include("types/flags_docs.jl")

# Base types (no dependencies on other discord types)
include("types/user.jl")
include("types/overwrite.jl")
include("types/role.jl")
include("types/emoji.jl")
include("types/sticker.jl")
include("types/member.jl")
include("types/ban.jl")

# Types that depend on base types
include("types/embed.jl")
include("types/attachment.jl")
include("types/reaction.jl")
include("types/component.jl")
include("types/poll.jl")
include("types/channel.jl")
include("types/message.jl")
include("types/guild.jl")
include("types/guild_template.jl")

# Complex types
include("types/interaction.jl")
include("types/invite.jl")
include("types/webhook.jl")
include("types/audit_log.jl")
include("types/automod.jl")
include("types/scheduled_event.jl")
include("types/presence.jl")
include("types/voice.jl")
include("types/integration.jl")
include("types/connection.jl")
include("types/soundboard.jl")
include("types/stage_instance.jl")
include("types/sku.jl")
include("types/onboarding.jl")

# === Gateway ===
include("gateway/opcodes.jl")
include("gateway/events.jl")
include("gateway/heartbeat.jl")
include("gateway/dispatch.jl")
include("gateway/connection.jl")
include("gateway/shard.jl")

# === REST ===
include("rest/route.jl")
include("rest/ratelimiter.jl")
include("rest/http_client.jl")
include("rest/endpoints/guild.jl")
include("rest/endpoints/guild_template.jl")
include("rest/endpoints/channel.jl")
include("rest/endpoints/message.jl")
include("rest/endpoints/user.jl")
include("rest/endpoints/interaction.jl")
include("rest/endpoints/application.jl")
include("rest/endpoints/webhook.jl")
include("rest/endpoints/emoji.jl")
include("rest/endpoints/sticker.jl")
include("rest/endpoints/invite.jl")
include("rest/endpoints/audit_log.jl")
include("rest/endpoints/automod.jl")
include("rest/endpoints/scheduled_event.jl")
include("rest/endpoints/stage_instance.jl")
include("rest/endpoints/soundboard.jl")
include("rest/endpoints/sku.jl")
include("rest/endpoints/voice.jl")
include("rest/endpoints/onboarding.jl")

# === Interactions (needed by Client) ===
include("interactions/command_tree.jl")

# === Client ===
include("client/state.jl")
include("client/event_handler.jl")
include("client/client.jl")

# === Interactions (rest) ===
include("interactions/context.jl")
include("interactions/checks.jl")
include("interactions/decorators.jl")
include("interactions/components.jl")

# === Voice ===
include("voice/encryption.jl")
include("voice/opus.jl")
include("voice/udp.jl")
include("voice/player.jl")
include("voice/sources.jl")
include("voice/connection.jl")
include("voice/client.jl")

# === Utils ===
include("utils/permissions.jl")

# === Exports ===

# Core & Snowflake
export Snowflake, timestamp, Optional, Nullable

# Main Discord Types
export User, Guild, UnavailableGuild, DiscordChannel, Message, Member, Role, Emoji
export Embed, Attachment, Reaction, Component, Interaction, SelectOption
export Invite, Webhook, AuditLog, AutoModRule, ScheduledEvent, Poll
export Presence, Activity, VoiceState, VoiceRegion
export InteractionContext, InteractionData, ApplicationCommand
export Overwrite, Ban, ThreadMetadata, ThreadMember, ForumTag
export Sticker, StickerItem, StickerPack, StageInstance, GuildTemplate
export MessageReference, MessageActivity, AllowedMentions

# Client & Lifecycle
export Client, start, stop, wait_until_ready, on, on_error
export wait_for, EventWaiter
export reply, create_message, edit_message, delete_message, create_reaction
export get_channel, get_guild, get_user
export update_voice_state, update_presence, request_guild_members

# Events
export AbstractEvent, UnknownEvent, ReadyEvent, ResumedEvent
export ChannelCreate, ChannelUpdate, ChannelDelete, ChannelPinsUpdate
export ThreadCreate, ThreadUpdate, ThreadDelete, ThreadListSync, ThreadMemberUpdate, ThreadMembersUpdate
export GuildCreate, GuildUpdate, GuildDelete, GuildAuditLogEntryCreate
export GuildBanAdd, GuildBanRemove, GuildEmojisUpdate, GuildStickersUpdate
export GuildIntegrationsUpdate
export GuildMemberAdd, GuildMemberRemove, GuildMemberUpdate, GuildMembersChunk
export GuildRoleCreate, GuildRoleUpdate, GuildRoleDelete
export GuildScheduledEventCreate, GuildScheduledEventUpdate, GuildScheduledEventDelete
export GuildScheduledEventUserAdd, GuildScheduledEventUserRemove
export GuildSoundboardSoundCreate, GuildSoundboardSoundUpdate, GuildSoundboardSoundDelete
export GuildSoundboardSoundsUpdate, SoundboardSounds
export IntegrationCreate, IntegrationUpdate, IntegrationDelete
export InteractionCreate, MessageCreate, MessageUpdate, MessageDelete, MessageDeleteBulk
export MessageReactionAdd, MessageReactionRemove, MessageReactionRemoveAll, MessageReactionRemoveEmoji
export MessagePollVoteAdd, MessagePollVoteRemove
export PresenceUpdate, TypingStart, UserUpdate
export VoiceStateUpdateEvent, VoiceServerUpdate, VoiceChannelEffectSend, WebhooksUpdate
export EntitlementCreate, EntitlementUpdate, EntitlementDelete
export SubscriptionCreate, SubscriptionUpdate, SubscriptionDelete
export AutoModerationRuleCreate, AutoModerationRuleUpdate, AutoModerationRuleDelete
export AutoModerationActionExecution

# State & Cache
export State, Store, CacheStrategy, CacheForever, CacheNever, CacheLRU, CacheTTL

# Macros (The Public Interface)
export @slash_command, @user_command, @message_command
export @button_handler, @select_handler, @modal_handler, @autocomplete
export @on_message, @option, @check

# Interactions Helpers
export get_options, get_option, custom_id, selected_values, modal_values, target
export respond, defer, edit_response, followup, show_modal
export sync_commands!, register_command!, register_component!, register_modal!, dispatch_interaction!
export CommandTree

# Check guards
export has_permissions, is_owner, is_in_guild, cooldown

# Component Builders
export action_row, button, string_select, select_option
export user_select, role_select, mentionable_select, channel_select
export text_input, embed, command_option
export embed_field, embed_footer, embed_author, activity
export container, section, text_display, thumbnail, media_gallery, media_gallery_item, file_component, separator, unfurled_media

# Enums (as modules)
export ChannelTypes, MessageTypes, InteractionTypes, InteractionCallbackTypes
export ApplicationCommandTypes, ApplicationCommandOptionTypes
export ComponentTypes, ButtonStyles, TextInputStyles
export ActivityTypes, StatusTypes, WebhookTypes, AuditLogEventTypes
export AutoModTriggerTypes, AutoModEventTypes, AutoModActionTypes
export ScheduledEventStatuses, ScheduledEventEntityTypes
export StickerTypes, StickerFormatTypes
export Locales, GuildFeatures

# Flags & Intents
export Intents, IntentGuilds, IntentGuildMembers, IntentGuildModeration
export IntentGuildExpressions, IntentGuildIntegrations, IntentGuildWebhooks
export IntentGuildInvites, IntentGuildVoiceStates, IntentGuildPresences
export IntentGuildMessages, IntentGuildMessageReactions, IntentGuildMessageTyping
export IntentDirectMessages, IntentDirectMessageReactions, IntentDirectMessageTyping
export IntentMessageContent, IntentGuildScheduledEvents
export IntentAutoModerationConfiguration, IntentAutoModerationExecution
export IntentGuildMessagePolls, IntentDirectMessagePolls
export IntentAllNonPrivileged, IntentAll
export has_flag

export Permissions
export PermAdministrator, PermManageChannels, PermManageGuild, PermKickMembers, PermBanMembers
export PermSendMessages, PermEmbedLinks, PermAttachFiles, PermReadMessageHistory
export PermConnect, PermSpeak, PermMuteMembers, PermDeafenMembers, PermMoveMembers
export PermManageRoles, PermManageWebhooks, PermViewChannel, PermManageMessages, PermViewAuditLog

export MessageFlags, MsgFlagEphemeral, MsgFlagSuppressEmbeds
export UserFlags, SystemChannelFlags, ChannelFlags, GuildMemberFlags, RoleFlags, AttachmentFlags

# Voice
export VoiceClient, connect!, disconnect!
export AbstractAudioSource, PCMSource, FileSource, FFmpegSource
export AudioPlayer, play!, stop!, pause!, resume!, is_playing

# REST Internals (needed by tests)
export RateLimiter, Route

# Initialize libsodium on module load
function __init__()
    init_sodium()
    _init_perm_map!()
end

# === Precompilation workload ===
@compile_workload begin
    # JSON3 round-trips for core types (biggest compilation cost)
    for T in (User, Guild, DiscordChannel, Message, Member, Role, Emoji,
              Interaction, Embed, Overwrite, Sticker, StageInstance)
        json = JSON3.write(T())
        JSON3.read(json, T)
    end

    # Vector variants
    for T in (User, Role, Emoji, DiscordChannel, Member)
        JSON3.read("[]", Vector{T})
    end

    # Snowflake serialization
    s = Snowflake(123456789)
    JSON3.write(s)
    JSON3.read("\"123456789\"", Snowflake)

    # parse_event for the most frequent events
    for (name, data) in [
        ("GUILD_CREATE", Dict{String,Any}("id" => "1", "name" => "test")),
        ("MESSAGE_CREATE", Dict{String,Any}("id" => "1", "channel_id" => "1", "type" => 0, "content" => "")),
        ("CHANNEL_CREATE", Dict{String,Any}("id" => "1", "type" => 0)),
    ]
        try; parse_event(name, data); catch; end
    end

    # Route and URL
    r = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "1")
    url(r)
end

end # module Accord
