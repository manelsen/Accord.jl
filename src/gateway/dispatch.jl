# Event dispatch: parse raw gateway payload → typed event struct
#
# Internal module: Converts raw JSON dictionaries from gateway DISPATCH payloads
# into strongly-typed AbstractEvent subtypes using JSON3 deserialization.

"""
    parse_event(event_name::String, data::Union{Dict{String, Any}, String}) -> AbstractEvent

Parse a raw gateway dispatch payload (either as a Dict or a JSON string) into a typed [`AbstractEvent`](@ref) struct.
If `data` is a String, it is deserialized directly into the event struct, avoiding intermediate Dict conversion.
"""
function parse_event(event_name::String, data::Union{Dict{String, Any}, String})
    # Look up event type
    EventType = get(EVENT_TYPES, event_name, nothing)

    if isnothing(EventType)
        @debug "Unknown gateway event" event_name
        dict_data = data isa String ? JSON3.read(data, Dict{String, Any}) : data
        return UnknownEvent(event_name, dict_data)
    end

    try
        return _construct_event(EventType, data)
    catch e
        @warn "Failed to parse event, returning UnknownEvent" event_name exception=e
        dict_data = data isa String ? JSON3.read(data, Dict{String, Any}) : data
        return UnknownEvent(event_name, dict_data)
    end
end

# Default paths. Gateway payloads arrive as JSON strings, so String is the
# canonical input: events declared with `@discord_struct` decode straight from
# it. A Dict (tests, hand-built payloads) is serialised once and takes the same
# path. Events that need custom logic define their own String method.
_construct_event(::Type{T}, data::String) where {T<:AbstractEvent} = JSON3.read(data, T)
_construct_event(::Type{T}, data::Dict) where {T<:AbstractEvent} = _construct_event(T, JSON3.write(data))

# Snowflake stored under `key` at the top level of a JSON payload.
_snowflake_at(data::String, key::Symbol) = Snowflake(JSON3.read(data)[key])

"""
    @wrap_resource_event EventType PayloadType

Generates the decoder for events that just wrap a single resource struct.
`EventType` is the dispatched event to build (e.g. `MessageCreate`) and `PayloadType` is the inner resource
(e.g. `Message`). Use this macro for the simple cases so `parse_event` stays DRY, but keep custom logic
in place for events that need extra parsing.
"""
macro wrap_resource_event(event_type, payload_type)
    # Dict input reaches this method through the generic Dict -> String path.
    esc(:(_construct_event(::Type{$event_type}, data::String) = $event_type(JSON3.read(data, $payload_type))))
end

# Construction helpers for events that wrap a single resource
@wrap_resource_event ChannelCreate DiscordChannel
@wrap_resource_event ChannelUpdate DiscordChannel
@wrap_resource_event ChannelDelete DiscordChannel

@wrap_resource_event ThreadCreate DiscordChannel
@wrap_resource_event ThreadUpdate DiscordChannel

_construct_event(::Type{ThreadMemberUpdate}, data::String) = ThreadMemberUpdate(JSON3.read(data, ThreadMember), _snowflake_at(data, :guild_id))

@wrap_resource_event GuildCreate Guild
@wrap_resource_event GuildUpdate Guild
@wrap_resource_event GuildDelete UnavailableGuild

_construct_event(::Type{GuildAuditLogEntryCreate}, data::String) = GuildAuditLogEntryCreate(JSON3.read(data, AuditLogEntry), _snowflake_at(data, :guild_id))

_construct_event(::Type{GuildMemberAdd}, data::String) = GuildMemberAdd(JSON3.read(data, Member), _snowflake_at(data, :guild_id))

@wrap_resource_event GuildScheduledEventCreate ScheduledEvent
@wrap_resource_event GuildScheduledEventUpdate ScheduledEvent
@wrap_resource_event GuildScheduledEventDelete ScheduledEvent

@wrap_resource_event GuildSoundboardSoundCreate SoundboardSound
@wrap_resource_event GuildSoundboardSoundUpdate SoundboardSound

_construct_event(::Type{IntegrationCreate}, data::String) = IntegrationCreate(JSON3.read(data, Integration), _snowflake_at(data, :guild_id))

_construct_event(::Type{IntegrationUpdate}, data::String) = IntegrationUpdate(JSON3.read(data, Integration), _snowflake_at(data, :guild_id))

@wrap_resource_event InteractionCreate Interaction

@wrap_resource_event MessageCreate Message
@wrap_resource_event MessageUpdate Message

function _construct_event(::Type{PresenceUpdate}, data::String)
    _construct_event(PresenceUpdate, JSON3.read(data, Dict{String, Any}))
end
function _construct_event(::Type{PresenceUpdate}, data::Dict)
    # Discord may omit `user` on some PRESENCE_UPDATE payloads.
    user = haskey(data, "user") && !isnothing(data["user"]) ? data["user"] : Dict{String, Any}()

    status_raw = get(data, "status", "offline")
    status = isnothing(status_raw) ? "offline" : string(status_raw)

    activities_raw = get(data, "activities", Any[])
    activities = isnothing(activities_raw) ?
        Activity[] :
        JSON3.read(JSON3.write(activities_raw), Vector{Activity})

    client_status = if haskey(data, "client_status") && !isnothing(data["client_status"])
        JSON3.read(JSON3.write(data["client_status"]), ClientStatus)
    else
        missing
    end

    PresenceUpdate(Presence(
        user,
        _get_snowflake(data, "guild_id"),
        status,
        activities,
        client_status,
    ))
end

@wrap_resource_event StageInstanceCreate StageInstance
@wrap_resource_event StageInstanceUpdate StageInstance
@wrap_resource_event StageInstanceDelete StageInstance

@wrap_resource_event UserUpdate User
@wrap_resource_event VoiceStateUpdateEvent VoiceState

@wrap_resource_event EntitlementCreate Entitlement
@wrap_resource_event EntitlementUpdate Entitlement
@wrap_resource_event EntitlementDelete Entitlement
@wrap_resource_event SubscriptionCreate Subscription
@wrap_resource_event SubscriptionUpdate Subscription
@wrap_resource_event SubscriptionDelete Subscription
@wrap_resource_event AutoModerationRuleCreate AutoModRule
@wrap_resource_event AutoModerationRuleUpdate AutoModRule
@wrap_resource_event AutoModerationRuleDelete AutoModRule

_construct_event(::Type{ResumedEvent}, ::String) = ResumedEvent()

# --- Utility helpers ---

function _get_snowflake(data::Dict, key::String)
    haskey(data, key) && !isnothing(data[key]) ? Snowflake(data[key]) : missing
end
