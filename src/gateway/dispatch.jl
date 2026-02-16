# Event dispatch: parse raw gateway payload → typed event struct
#
# Internal module: Converts raw JSON dictionaries from gateway DISPATCH payloads
# into strongly-typed AbstractEvent subtypes using JSON3 deserialization.

"""
    parse_event(event_name::String, data::Dict) -> AbstractEvent

Use this internal function to convert raw gateway payloads into typed event structures for processing.

Parse a raw gateway dispatch payload into a typed [`AbstractEvent`](@ref) struct.
"""
function parse_event(event_name::String, data::Dict{String, Any})
    # Look up event type
    EventType = get(EVENT_TYPES, event_name, nothing)

    if isnothing(EventType)
        @debug "Unknown gateway event" event_name
        return UnknownEvent(event_name, data)
    end

    try
        return _construct_event(EventType, data)
    catch e
        @warn "Failed to parse event, returning UnknownEvent" event_name exception=e
        return UnknownEvent(event_name, data)
    end
end

# Construction helpers for events that wrap a single resource
function _construct_event(::Type{ChannelCreate}, data::Dict)
    ChannelCreate(JSON3.read(JSON3.write(data), DiscordChannel))
end
function _construct_event(::Type{ChannelUpdate}, data::Dict)
    ChannelUpdate(JSON3.read(JSON3.write(data), DiscordChannel))
end
function _construct_event(::Type{ChannelDelete}, data::Dict)
    ChannelDelete(JSON3.read(JSON3.write(data), DiscordChannel))
end
function _construct_event(::Type{ChannelPinsUpdate}, data::Dict)
    ChannelPinsUpdate(
        _get_snowflake(data, "guild_id"),
        Snowflake(data["channel_id"]),
        get(data, "last_pin_timestamp", missing),
    )
end

function _construct_event(::Type{ThreadCreate}, data::Dict)
    ThreadCreate(JSON3.read(JSON3.write(data), DiscordChannel))
end
function _construct_event(::Type{ThreadUpdate}, data::Dict)
    ThreadUpdate(JSON3.read(JSON3.write(data), DiscordChannel))
end
function _construct_event(::Type{ThreadDelete}, data::Dict)
    ThreadDelete(
        Snowflake(data["id"]),
        Snowflake(data["guild_id"]),
        Snowflake(data["parent_id"]),
        data["type"],
    )
end
function _construct_event(::Type{ThreadListSync}, data::Dict)
    ThreadListSync(
        Snowflake(data["guild_id"]),
        _get_snowflake_array(data, "channel_ids"),
        JSON3.read(JSON3.write(get(data, "threads", [])), Vector{DiscordChannel}),
        JSON3.read(JSON3.write(get(data, "members", [])), Vector{ThreadMember}),
    )
end
function _construct_event(::Type{ThreadMemberUpdate}, data::Dict)
    guild_id = Snowflake(data["guild_id"])
    member = JSON3.read(JSON3.write(data), ThreadMember)
    ThreadMemberUpdate(member, guild_id)
end
function _construct_event(::Type{ThreadMembersUpdate}, data::Dict)
    ThreadMembersUpdate(
        Snowflake(data["id"]),
        Snowflake(data["guild_id"]),
        data["member_count"],
        haskey(data, "added_members") ? JSON3.read(JSON3.write(data["added_members"]), Vector{ThreadMember}) : missing,
        _get_snowflake_array(data, "removed_member_ids"),
    )
end

function _construct_event(::Type{GuildCreate}, data::Dict)
    GuildCreate(JSON3.read(JSON3.write(data), Guild))
end
function _construct_event(::Type{GuildUpdate}, data::Dict)
    GuildUpdate(JSON3.read(JSON3.write(data), Guild))
end
function _construct_event(::Type{GuildDelete}, data::Dict)
    GuildDelete(JSON3.read(JSON3.write(data), UnavailableGuild))
end

function _construct_event(::Type{GuildAuditLogEntryCreate}, data::Dict)
    guild_id = Snowflake(pop!(data, "guild_id"))
    entry = JSON3.read(JSON3.write(data), AuditLogEntry)
    GuildAuditLogEntryCreate(entry, guild_id)
end

function _construct_event(::Type{GuildBanAdd}, data::Dict)
    GuildBanAdd(Snowflake(data["guild_id"]), JSON3.read(JSON3.write(data["user"]), User))
end
function _construct_event(::Type{GuildBanRemove}, data::Dict)
    GuildBanRemove(Snowflake(data["guild_id"]), JSON3.read(JSON3.write(data["user"]), User))
end

function _construct_event(::Type{GuildEmojisUpdate}, data::Dict)
    GuildEmojisUpdate(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["emojis"]), Vector{Emoji}),
    )
end
function _construct_event(::Type{GuildStickersUpdate}, data::Dict)
    GuildStickersUpdate(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["stickers"]), Vector{Sticker}),
    )
end
function _construct_event(::Type{GuildIntegrationsUpdate}, data::Dict)
    GuildIntegrationsUpdate(Snowflake(data["guild_id"]))
end

function _construct_event(::Type{GuildMemberAdd}, data::Dict)
    guild_id = Snowflake(pop!(data, "guild_id"))
    member = JSON3.read(JSON3.write(data), Member)
    GuildMemberAdd(member, guild_id)
end
function _construct_event(::Type{GuildMemberRemove}, data::Dict)
    GuildMemberRemove(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["user"]), User),
    )
end
function _construct_event(::Type{GuildMemberUpdate}, data::Dict)
    GuildMemberUpdate(
        Snowflake(data["guild_id"]),
        [Snowflake(r) for r in data["roles"]],
        JSON3.read(JSON3.write(data["user"]), User),
        get(data, "nick", missing),
        get(data, "avatar", missing),
        get(data, "joined_at", missing),
        get(data, "premium_since", missing),
        get(data, "deaf", missing),
        get(data, "mute", missing),
        get(data, "pending", missing),
        get(data, "communication_disabled_until", missing),
        get(data, "flags", missing),
    )
end
function _construct_event(::Type{GuildMembersChunk}, data::Dict)
    GuildMembersChunk(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["members"]), Vector{Member}),
        data["chunk_index"],
        data["chunk_count"],
        _get_snowflake_array(data, "not_found"),
        haskey(data, "presences") ? JSON3.read(JSON3.write(data["presences"]), Vector{Presence}) : missing,
        get(data, "nonce", missing),
    )
end

function _construct_event(::Type{GuildRoleCreate}, data::Dict)
    GuildRoleCreate(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["role"]), Role),
    )
end
function _construct_event(::Type{GuildRoleUpdate}, data::Dict)
    GuildRoleUpdate(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["role"]), Role),
    )
end
function _construct_event(::Type{GuildRoleDelete}, data::Dict)
    GuildRoleDelete(Snowflake(data["guild_id"]), Snowflake(data["role_id"]))
end

function _construct_event(::Type{GuildScheduledEventCreate}, data::Dict)
    GuildScheduledEventCreate(JSON3.read(JSON3.write(data), ScheduledEvent))
end
function _construct_event(::Type{GuildScheduledEventUpdate}, data::Dict)
    GuildScheduledEventUpdate(JSON3.read(JSON3.write(data), ScheduledEvent))
end
function _construct_event(::Type{GuildScheduledEventDelete}, data::Dict)
    GuildScheduledEventDelete(JSON3.read(JSON3.write(data), ScheduledEvent))
end
function _construct_event(::Type{GuildScheduledEventUserAdd}, data::Dict)
    GuildScheduledEventUserAdd(
        Snowflake(data["guild_scheduled_event_id"]),
        Snowflake(data["user_id"]),
        Snowflake(data["guild_id"]),
    )
end
function _construct_event(::Type{GuildScheduledEventUserRemove}, data::Dict)
    GuildScheduledEventUserRemove(
        Snowflake(data["guild_scheduled_event_id"]),
        Snowflake(data["user_id"]),
        Snowflake(data["guild_id"]),
    )
end

function _construct_event(::Type{GuildSoundboardSoundCreate}, data::Dict)
    GuildSoundboardSoundCreate(JSON3.read(JSON3.write(data), SoundboardSound))
end
function _construct_event(::Type{GuildSoundboardSoundUpdate}, data::Dict)
    GuildSoundboardSoundUpdate(JSON3.read(JSON3.write(data), SoundboardSound))
end
function _construct_event(::Type{GuildSoundboardSoundDelete}, data::Dict)
    GuildSoundboardSoundDelete(Snowflake(data["sound_id"]), Snowflake(data["guild_id"]))
end
function _construct_event(::Type{GuildSoundboardSoundsUpdate}, data::Dict)
    GuildSoundboardSoundsUpdate(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["soundboard_sounds"]), Vector{SoundboardSound}),
    )
end
function _construct_event(::Type{SoundboardSounds}, data::Dict)
    SoundboardSounds(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["soundboard_sounds"]), Vector{SoundboardSound}),
    )
end

function _construct_event(::Type{IntegrationCreate}, data::Dict)
    guild_id = Snowflake(pop!(data, "guild_id"))
    IntegrationCreate(JSON3.read(JSON3.write(data), Integration), guild_id)
end
function _construct_event(::Type{IntegrationUpdate}, data::Dict)
    guild_id = Snowflake(pop!(data, "guild_id"))
    IntegrationUpdate(JSON3.read(JSON3.write(data), Integration), guild_id)
end
function _construct_event(::Type{IntegrationDelete}, data::Dict)
    IntegrationDelete(
        Snowflake(data["id"]),
        Snowflake(data["guild_id"]),
        _get_snowflake(data, "application_id"),
    )
end

function _construct_event(::Type{InteractionCreate}, data::Dict)
    InteractionCreate(JSON3.read(JSON3.write(data), Interaction))
end

function _construct_event(::Type{InviteCreate}, data::Dict)
    InviteCreate(
        Snowflake(data["channel_id"]),
        data["code"],
        data["created_at"],
        _get_snowflake(data, "guild_id"),
        haskey(data, "inviter") ? JSON3.read(JSON3.write(data["inviter"]), User) : missing,
        data["max_age"],
        data["max_uses"],
        get(data, "target_type", missing),
        haskey(data, "target_user") ? JSON3.read(JSON3.write(data["target_user"]), User) : missing,
        get(data, "target_application", missing),
        data["temporary"],
        data["uses"],
    )
end
function _construct_event(::Type{InviteDelete}, data::Dict)
    InviteDelete(
        Snowflake(data["channel_id"]),
        _get_snowflake(data, "guild_id"),
        data["code"],
    )
end

function _construct_event(::Type{MessageCreate}, data::Dict)
    MessageCreate(JSON3.read(JSON3.write(data), Message))
end
function _construct_event(::Type{MessageUpdate}, data::Dict)
    MessageUpdate(JSON3.read(JSON3.write(data), Message))
end
function _construct_event(::Type{MessageDelete}, data::Dict)
    MessageDelete(
        Snowflake(data["id"]),
        Snowflake(data["channel_id"]),
        _get_snowflake(data, "guild_id"),
    )
end
function _construct_event(::Type{MessageDeleteBulk}, data::Dict)
    MessageDeleteBulk(
        [Snowflake(id) for id in data["ids"]],
        Snowflake(data["channel_id"]),
        _get_snowflake(data, "guild_id"),
    )
end

function _construct_event(::Type{MessageReactionAdd}, data::Dict)
    MessageReactionAdd(
        Snowflake(data["user_id"]),
        Snowflake(data["channel_id"]),
        Snowflake(data["message_id"]),
        _get_snowflake(data, "guild_id"),
        haskey(data, "member") ? JSON3.read(JSON3.write(data["member"]), Member) : missing,
        JSON3.read(JSON3.write(data["emoji"]), Emoji),
        _get_snowflake(data, "message_author_id"),
        get(data, "burst", false),
        get(data, "burst_colors", missing),
        get(data, "type", 0),
    )
end
function _construct_event(::Type{MessageReactionRemove}, data::Dict)
    MessageReactionRemove(
        Snowflake(data["user_id"]),
        Snowflake(data["channel_id"]),
        Snowflake(data["message_id"]),
        _get_snowflake(data, "guild_id"),
        JSON3.read(JSON3.write(data["emoji"]), Emoji),
        get(data, "burst", false),
        get(data, "type", 0),
    )
end
function _construct_event(::Type{MessageReactionRemoveAll}, data::Dict)
    MessageReactionRemoveAll(
        Snowflake(data["channel_id"]),
        Snowflake(data["message_id"]),
        _get_snowflake(data, "guild_id"),
    )
end
function _construct_event(::Type{MessageReactionRemoveEmoji}, data::Dict)
    MessageReactionRemoveEmoji(
        Snowflake(data["channel_id"]),
        _get_snowflake(data, "guild_id"),
        Snowflake(data["message_id"]),
        JSON3.read(JSON3.write(data["emoji"]), Emoji),
    )
end

function _construct_event(::Type{MessagePollVoteAdd}, data::Dict)
    MessagePollVoteAdd(
        Snowflake(data["user_id"]),
        Snowflake(data["channel_id"]),
        Snowflake(data["message_id"]),
        _get_snowflake(data, "guild_id"),
        data["answer_id"],
    )
end
function _construct_event(::Type{MessagePollVoteRemove}, data::Dict)
    MessagePollVoteRemove(
        Snowflake(data["user_id"]),
        Snowflake(data["channel_id"]),
        Snowflake(data["message_id"]),
        _get_snowflake(data, "guild_id"),
        data["answer_id"],
    )
end

function _construct_event(::Type{PresenceUpdate}, data::Dict)
    PresenceUpdate(JSON3.read(JSON3.write(data), Presence))
end

function _construct_event(::Type{StageInstanceCreate}, data::Dict)
    StageInstanceCreate(JSON3.read(JSON3.write(data), StageInstance))
end
function _construct_event(::Type{StageInstanceUpdate}, data::Dict)
    StageInstanceUpdate(JSON3.read(JSON3.write(data), StageInstance))
end
function _construct_event(::Type{StageInstanceDelete}, data::Dict)
    StageInstanceDelete(JSON3.read(JSON3.write(data), StageInstance))
end

function _construct_event(::Type{TypingStart}, data::Dict)
    TypingStart(
        Snowflake(data["channel_id"]),
        _get_snowflake(data, "guild_id"),
        Snowflake(data["user_id"]),
        data["timestamp"],
        haskey(data, "member") ? JSON3.read(JSON3.write(data["member"]), Member) : missing,
    )
end

function _construct_event(::Type{UserUpdate}, data::Dict)
    UserUpdate(JSON3.read(JSON3.write(data), User))
end

function _construct_event(::Type{VoiceStateUpdateEvent}, data::Dict)
    VoiceStateUpdateEvent(JSON3.read(JSON3.write(data), VoiceState))
end
function _construct_event(::Type{VoiceServerUpdate}, data::Dict)
    VoiceServerUpdate(data["token"], Snowflake(data["guild_id"]), get(data, "endpoint", nothing))
end
function _construct_event(::Type{VoiceChannelEffectSend}, data::Dict)
    VoiceChannelEffectSend(
        Snowflake(data["channel_id"]),
        Snowflake(data["guild_id"]),
        Snowflake(data["user_id"]),
        haskey(data, "emoji") ? JSON3.read(JSON3.write(data["emoji"]), Emoji) : missing,
        get(data, "animation_type", missing),
        get(data, "animation_id", missing),
        get(data, "sound_id", missing),
        get(data, "sound_volume", missing),
    )
end

function _construct_event(::Type{WebhooksUpdate}, data::Dict)
    WebhooksUpdate(Snowflake(data["guild_id"]), Snowflake(data["channel_id"]))
end

function _construct_event(::Type{EntitlementCreate}, data::Dict)
    EntitlementCreate(JSON3.read(JSON3.write(data), Entitlement))
end
function _construct_event(::Type{EntitlementUpdate}, data::Dict)
    EntitlementUpdate(JSON3.read(JSON3.write(data), Entitlement))
end
function _construct_event(::Type{EntitlementDelete}, data::Dict)
    EntitlementDelete(JSON3.read(JSON3.write(data), Entitlement))
end

function _construct_event(::Type{SubscriptionCreate}, data::Dict)
    SubscriptionCreate(JSON3.read(JSON3.write(data), Subscription))
end
function _construct_event(::Type{SubscriptionUpdate}, data::Dict)
    SubscriptionUpdate(JSON3.read(JSON3.write(data), Subscription))
end
function _construct_event(::Type{SubscriptionDelete}, data::Dict)
    SubscriptionDelete(JSON3.read(JSON3.write(data), Subscription))
end

function _construct_event(::Type{AutoModerationRuleCreate}, data::Dict)
    AutoModerationRuleCreate(JSON3.read(JSON3.write(data), AutoModRule))
end
function _construct_event(::Type{AutoModerationRuleUpdate}, data::Dict)
    AutoModerationRuleUpdate(JSON3.read(JSON3.write(data), AutoModRule))
end
function _construct_event(::Type{AutoModerationRuleDelete}, data::Dict)
    AutoModerationRuleDelete(JSON3.read(JSON3.write(data), AutoModRule))
end
function _construct_event(::Type{AutoModerationActionExecution}, data::Dict)
    AutoModerationActionExecution(
        Snowflake(data["guild_id"]),
        JSON3.read(JSON3.write(data["action"]), AutoModAction),
        Snowflake(data["rule_id"]),
        data["rule_trigger_type"],
        Snowflake(data["user_id"]),
        _get_snowflake(data, "channel_id"),
        _get_snowflake(data, "message_id"),
        _get_snowflake(data, "alert_system_message_id"),
        get(data, "content", missing),
        get(data, "matched_keyword", missing),
        get(data, "matched_content", missing),
    )
end

function _construct_event(::Type{ReadyEvent}, data::Dict)
    ReadyEvent(
        data["v"],
        JSON3.read(JSON3.write(data["user"]), User),
        JSON3.read(JSON3.write(data["guilds"]), Vector{UnavailableGuild}),
        data["session_id"],
        data["resume_gateway_url"],
        get(data, "shard", missing),
        get(data, "application", nothing),
    )
end

function _construct_event(::Type{ResumedEvent}, data::Dict)
    ResumedEvent()
end

# --- Utility helpers ---

function _get_snowflake(data::Dict, key::String)
    haskey(data, key) && !isnothing(data[key]) ? Snowflake(data[key]) : missing
end

function _get_snowflake_array(data::Dict, key::String)
    haskey(data, key) ? [Snowflake(s) for s in data[key]] : missing
end
