module Accord

# === Constants ===
const API_VERSION = 10
const API_BASE = "https://discord.com/api/v$(API_VERSION)"
const ACCORD_VERSION = v"0.3.0-alpha"
const USER_AGENT = "DiscordBot (Accord.jl, $ACCORD_VERSION)"

# === Type aliases ===
const Optional{T} = Union{T, Missing}
const Nullable{T} = Union{T, Nothing}
const Maybe{T} = Union{T, Missing, Nothing}

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

# Forward declaration for Client
abstract type AbstractClient end

# === Interactions (dependencies for Client) ===
include("interactions/context.jl")
include("interactions/checks.jl")
include("interactions/command_tree.jl")

# === Client ===
include("client/state.jl")
include("client/event_handler.jl")
include("client/client.jl") # Defines Client <: AbstractClient

# === Interactions (Macros & UI) ===
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
# === Utils ===
include("utils/permissions.jl")
include("diagnostics/Diagnoser.jl")

# === Internal namespace ===
# Stable escape hatch for non-public APIs used by advanced users and tests.
module Internals
using ..Accord

# Voice internals
const VoiceGatewaySession = Accord.VoiceGatewaySession
const CRYPTO_SECRETBOX_KEYBYTES = Accord.CRYPTO_SECRETBOX_KEYBYTES
const CRYPTO_SECRETBOX_NONCEBYTES = Accord.CRYPTO_SECRETBOX_NONCEBYTES
const ENCRYPTION_MODES = Accord.ENCRYPTION_MODES
const select_encryption_mode = Accord.select_encryption_mode
const xsalsa20_poly1305_encrypt = Accord.xsalsa20_poly1305_encrypt
const rtp_header = Accord.rtp_header
const VoiceOpcodes = Accord.VoiceOpcodes

# Command/check internals
const pending_checks = Accord.pending_checks
const push_pending_check! = Accord.push_pending_check!
const drain_pending_checks! = Accord.drain_pending_checks!
const run_checks = Accord.run_checks
const register_command! = Accord.register_command!
const register_component! = Accord.register_component!
const register_modal! = Accord.register_modal!
const dispatch_interaction! = Accord.dispatch_interaction!

# REST infra internals
const RateLimiter = Accord.RateLimiter
const Route = Accord.Route
end

const internals = Internals

# === Exports ===

# Core & Snowflake
export Snowflake, timestamp, Optional, Nullable, Internals, internals

# Main Discord Types
export User, Guild, UnavailableGuild, DiscordChannel, Message, Member, Role, Emoji
export Embed, Attachment, Component, Interaction
export Invite, Webhook, AuditLog, AutoModRule, ScheduledEvent, Poll
export Presence, Activity, VoiceState, VoiceRegion
export InteractionContext, InteractionData, InteractionDataOption, ApplicationCommand
export Overwrite, Ban, ThreadMember
export Sticker, StageInstance, GuildTemplate

# Client & Lifecycle
export Client, start, stop, wait_until_ready, on, on_error
export wait_for, EventWaiter
export create_message, edit_message, delete_message, create_reaction
export create_poll, modify_thread
export create_forum_tag, modify_forum_tag, delete_forum_tag
export get_channel, get_guild, get_user
export update_voice_state, update_presence, request_guild_members

# Events
export AbstractEvent, UnknownEvent, ReadyEvent
export ChannelCreate, ChannelDelete
export GuildCreate, GuildDelete
export GuildMemberAdd, GuildMemberRemove, GuildMemberUpdate
export InteractionCreate, MessageCreate
export PresenceUpdate, TypingStart

# State & Cache
export State, Store, CacheForever, CacheNever, CacheLRU, CacheTTL

# Macros (The Public Interface)
export @slash_command, @user_command, @message_command
export @button_handler, @select_handler, @modal_handler, @autocomplete
export @on_message, @option, @check
export @on, @embed, @group, @subcommand

# Interactions Helpers
export get_options, get_option, custom_id, selected_values, modal_values, target
export respond, defer, edit_response, followup, show_modal
export sync_commands!

# Check guards
export has_permissions, is_owner, is_in_guild, cooldown

# Component Builders
export action_row, button, string_select, select_option
export text_input, embed, command_option
export embed_field, embed_footer, embed_author, activity
export container, section, text_display, thumbnail, media_gallery, media_gallery_item, file_component, separator, unfurled_media

# Enums (as modules)
export ChannelTypes, MessageTypes, InteractionTypes
export ApplicationCommandTypes, ApplicationCommandOptionTypes
export ComponentTypes, ButtonStyles, TextInputStyles
export ActivityTypes
export StickerTypes

# Flags & Intents
export Intents, IntentGuilds, IntentGuildMembers
export IntentGuildPresences
export IntentGuildMessages
export IntentMessageContent
export IntentAllNonPrivileged, IntentAll
export has_flag

export Permissions
export PermAdministrator, PermManageGuild, PermKickMembers, PermBanMembers
export PermSendMessages, PermEmbedLinks, PermAttachFiles, PermReadMessageHistory
export PermConnect, PermSpeak
export PermViewChannel, PermManageMessages

export MessageFlags, MsgFlagEphemeral, MsgFlagSuppressEmbeds

# Voice
export VoiceClient, connect!, disconnect!
export AbstractAudioSource, PCMSource, FileSource, FFmpegSource, SilenceSource
export AudioPlayer, play!, stop!, pause!, resume!, is_playing
export OpusEncoder, OpusDecoder, opus_encode, opus_decode, set_bitrate!, set_signal!
export OPUS_SAMPLE_RATE, OPUS_CHANNELS, OPUS_FRAME_SIZE, OPUS_FRAME_DURATION_MS, OPUS_MAX_PACKET_SIZE
export OPUS_APPLICATION_AUDIO, OPUS_APPLICATION_VOIP
export read_frame, close_source

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
