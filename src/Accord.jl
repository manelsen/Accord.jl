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
import LRUCache
import Opus_jll
import libsodium_jll

# === Types (order matters for dependencies) ===
include("types/macros.jl")
include("types/snowflake.jl")
include("types/enums.jl")
include("types/flags.jl")

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
# Types
export Snowflake, timestamp
export Optional, Nullable
export User, Guild, UnavailableGuild, DiscordChannel, Message, Member, Role, Emoji
export Embed, EmbedField, EmbedAuthor, EmbedFooter, EmbedImage, EmbedThumbnail
export Attachment, Reaction, Component, SelectOption
export Interaction, InteractionData, ApplicationCommand, ApplicationCommandOption
export Sticker, StickerItem, StickerPack
export Invite, Webhook, AuditLog, AuditLogEntry
export AutoModRule, AutoModAction, AutoModTriggerMetadata
export ScheduledEvent, Poll, PollAnswer, PollMedia
export Presence, Activity, VoiceState, VoiceRegion
export Integration, Connection, SoundboardSound, StageInstance
export SKU, Entitlement, Subscription
export Onboarding, OnboardingPrompt
export GuildTemplate
export Overwrite, Ban, ThreadMetadata, ThreadMember, ForumTag
export MessageReference, MessageActivity, AllowedMentions
export WelcomeScreen, WelcomeScreenChannel
export ResolvedData, InteractionDataOption

# Enums (as modules)
export ChannelTypes, MessageTypes, InteractionTypes, InteractionCallbackTypes
export ApplicationCommandTypes, ApplicationCommandOptionTypes
export ComponentTypes, ButtonStyles, TextInputStyles
export VerificationLevels, DefaultMessageNotificationLevels, ExplicitContentFilterLevels
export MFALevels, NSFWLevels, PremiumTiers, PremiumTypes
export ActivityTypes, StatusTypes, WebhookTypes, AuditLogEventTypes
export AutoModTriggerTypes, AutoModEventTypes, AutoModActionTypes
export ScheduledEventStatuses, ScheduledEventEntityTypes
export StickerTypes, StickerFormatTypes
export SKUTypes, EntitlementTypes
export GuildFeatures, Locales, AllowedMentionTypes

# Flags
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
export PermCreateInstantInvite, PermKickMembers, PermBanMembers, PermAdministrator
export PermManageChannels, PermManageGuild, PermAddReactions, PermViewAuditLog
export PermViewChannel, PermSendMessages, PermManageMessages, PermEmbedLinks
export PermAttachFiles, PermReadMessageHistory, PermMentionEveryone
export PermConnect, PermSpeak, PermMuteMembers, PermDeafenMembers, PermMoveMembers
export PermManageRoles, PermManageWebhooks, PermManageGuildExpressions
export PermUseApplicationCommands, PermManageEvents, PermManageThreads
export PermSendMessagesInThreads, PermModerateMembers, PermSendVoiceMessages, PermSendPolls

export MessageFlags, MsgFlagEphemeral, MsgFlagSuppressEmbeds
export UserFlags, SystemChannelFlags, ChannelFlags, GuildMemberFlags, RoleFlags, AttachmentFlags

# Events
export AbstractEvent, UnknownEvent
export ReadyEvent, ResumedEvent
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
export InteractionCreate
export InviteCreate, InviteDelete
export MessageCreate, MessageUpdate, MessageDelete, MessageDeleteBulk
export MessageReactionAdd, MessageReactionRemove, MessageReactionRemoveAll, MessageReactionRemoveEmoji
export MessagePollVoteAdd, MessagePollVoteRemove
export PresenceUpdate
export StageInstanceCreate, StageInstanceUpdate, StageInstanceDelete
export TypingStart, UserUpdate
export VoiceStateUpdateEvent, VoiceServerUpdate, VoiceChannelEffectSend
export WebhooksUpdate
export EntitlementCreate, EntitlementUpdate, EntitlementDelete
export SubscriptionCreate, SubscriptionUpdate, SubscriptionDelete
export AutoModerationRuleCreate, AutoModerationRuleUpdate, AutoModerationRuleDelete
export AutoModerationActionExecution

# Gateway
export GatewayOpcodes, GatewayCloseCodes, VoiceOpcodes
export GatewayCommand

# REST
export RateLimiter, Route
export discord_request, discord_get, discord_post, discord_put, discord_patch, discord_delete

# Client
export Client, start, stop, wait_until_ready, on, on_error
export wait_for, EventWaiter
export create_message, edit_message, delete_message, create_reaction, reply
export get_channel, get_guild, get_user
export update_voice_state, update_presence, request_guild_members

# State & Cache
export State, Store, CacheStrategy, CacheForever, CacheNever, CacheLRU, CacheTTL

# REST endpoints (module-level functions)
export get_guild, get_guild_preview, modify_guild, delete_guild
export get_guild_channels, create_guild_channel
export get_guild_member, list_guild_members, search_guild_members, modify_guild_member
export add_guild_member_role, remove_guild_member_role, remove_guild_member
export get_guild_bans, create_guild_ban, remove_guild_ban, bulk_guild_ban
export get_guild_roles, create_guild_role, modify_guild_role, delete_guild_role
export get_guild_invites, get_guild_integrations
export get_channel, modify_channel, delete_channel
export get_channel_messages, get_channel_message
export crosspost_message, bulk_delete_messages
export create_reaction, delete_own_reaction, delete_user_reaction, get_reactions
export delete_all_reactions, delete_all_reactions_for_emoji
export trigger_typing_indicator, get_pinned_messages, pin_message, unpin_message
export start_thread_from_message, start_thread_without_message, start_thread_in_forum
export get_current_user, get_user, modify_current_user, create_dm
export get_global_application_commands, create_global_application_command
export edit_global_application_command, delete_global_application_command
export bulk_overwrite_global_application_commands
export get_guild_application_commands, create_guild_application_command
export bulk_overwrite_guild_application_commands
export create_interaction_response, edit_original_interaction_response
export delete_original_interaction_response
export create_followup_message, edit_followup_message, delete_followup_message
export create_webhook, get_webhook, modify_webhook, delete_webhook, execute_webhook
export list_guild_emojis, create_guild_emoji, modify_guild_emoji, delete_guild_emoji
export get_sticker, list_guild_stickers, create_guild_sticker
export get_invite, delete_invite
export get_guild_audit_log
export list_auto_moderation_rules, create_auto_moderation_rule
export list_scheduled_events, create_guild_scheduled_event
export create_stage_instance, get_stage_instance, modify_stage_instance, delete_stage_instance
export list_voice_regions
export list_skus, list_entitlements
export get_guild_templates, create_guild_template, sync_guild_template
export modify_guild_template, delete_guild_template, create_guild_from_template

# Interactions
export InteractionContext, get_options, get_option, custom_id, selected_values, modal_values, target
export respond, defer, edit_response, followup, show_modal
export CommandTree, CommandDefinition
export register_command!, register_component!, register_modal!, register_autocomplete!
export sync_commands!, dispatch_interaction!
export @slash_command, @button_handler, @select_handler, @modal_handler, @autocomplete
export @user_command, @message_command
export @on_message, @option, @check

# Check guards
export has_permissions, is_owner, is_in_guild, cooldown, run_checks

# Component builders
export action_row, button, string_select, select_option
export user_select, role_select, mentionable_select, channel_select
export text_input, embed, command_option
export embed_field, embed_footer, embed_author, activity
export container, section, text_display, thumbnail
export media_gallery, media_gallery_item, file_component, separator, unfurled_media

# Voice
export VoiceClient, connect!, disconnect!
export AbstractAudioSource, read_frame, close_source
export PCMSource, FileSource, FFmpegSource, SilenceSource
export AudioPlayer, play!, stop!, pause!, resume!, is_playing
export OpusEncoder, OpusDecoder, opus_encode, opus_decode

# Permissions
export compute_base_permissions, compute_channel_permissions

# Initialize libsodium on module load
function __init__()
    init_sodium()
    _init_perm_map!()
end

end # module Accord
