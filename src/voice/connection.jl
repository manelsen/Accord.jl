# Voice gateway WebSocket connection
#
# Internal module: Manages the voice-specific WebSocket connection to Discord.
# Handles voice HELLO, READY, SESSION_DESCRIPTION, heartbeating (v8, with
# seq_ack) and routes DAVE opcodes, JSON and binary, to the DAVE session.

"""
    VoiceGatewaySession

Use this internal struct to manage the voice gateway WebSocket connection state.

State for a voice gateway WebSocket connection.
"""
mutable struct VoiceGatewaySession
    ws::Nullable{HTTP.WebSockets.WebSocket}
    guild_id::Snowflake
    channel_id::Snowflake
    user_id::Snowflake
    session_id::String
    endpoint::String
    token::String
    ssrc::UInt32
    ip::String
    port::Int
    modes::Vector{String}
    secret_key::Vector{UInt8}
    heartbeat_interval::Float64
    heartbeat_task::Nullable{Task}
    connected::Bool
    ready::Base.Event
    described::Base.Event              # set once opcode 4 (secret key) arrives
    seq_ack::Int                       # last sequence number received (-1: none yet)
    send_lock::ReentrantLock           # heartbeat, gateway loop and player all write
    dave::Union{DaveSession, Nothing}  # E2EE state; `nothing` when the call has no DAVE
    close_code::Union{Int, Nothing}
end

function VoiceGatewaySession(guild_id::Snowflake, channel_id::Snowflake, user_id::Snowflake,
                             session_id::String, endpoint::String, token::String)
    VoiceGatewaySession(
        nothing, guild_id, channel_id, user_id, session_id,
        # Remove trailing port if present, ensure wss://
        startswith(endpoint, "wss://") ? endpoint : "wss://$endpoint",
        token, UInt32(0), "", 0, String[], UInt8[], 0.0,
        nothing, false, Base.Event(), Base.Event(), -1, ReentrantLock(), nothing, nothing
    )
end

# Voice gateway close codes that mean "don't retry".
const VOICE_CLOSE_E2EE_REQUIRED = 4017

# Serialise writes to the voice WebSocket.
function _voice_send(session::VoiceGatewaySession, payload)
    ws = session.ws
    isnothing(ws) && throw(ArgumentError("Voice gateway websocket is not connected"))
    lock(() -> HTTP.WebSockets.send(ws, payload), session.send_lock)
end

_voice_send_json(session::VoiceGatewaySession, op::Integer, d) =
    _voice_send(session, JSON3.write(Dict("op" => op, "d" => d)))

_voice_send_binary(session::VoiceGatewaySession, op::Integer, payload::Vector{UInt8}) =
    _voice_send(session, dave_binary_frame(op, payload))

"""
    voice_gateway_connect(session::VoiceGatewaySession) -> Task

Use this internal function to establish the voice gateway connection.

Connect to the voice gateway WebSocket and complete the handshake.
"""
function voice_gateway_connect(session::VoiceGatewaySession)
    url = "$(session.endpoint)/?v=8"

    @_spawn_io begin
        try
            HTTP.WebSockets.open(url) do ws
                session.ws = ws
                session.connected = true
                _voice_gateway_loop(ws, session)
            end
        catch e
            _voice_closed!(session, e)
        end
        session.connected = false
        notify(session.ready)       # unblock connect! so it can report a failure
        notify(session.described)
    end
end

# Log why the voice connection ended; remember the close code.
function _voice_closed!(session::VoiceGatewaySession, e)
    if e isa HTTP.WebSockets.WebSocketError && e.message isa HTTP.WebSockets.CloseFrameBody
        session.close_code = e.message.status
        if session.close_code == VOICE_CLOSE_E2EE_REQUIRED
            @error "Discord requires DAVE end-to-end encryption for this voice channel, " *
                   "but libdave is not loaded. Set ENV[\"ACCORD_LIBDAVE\"] to the path of " *
                   "the libdave shared library before connecting." code=session.close_code
        else
            @error "Voice gateway closed" code=session.close_code reason=e.message.message
        end
    else
        @error "Voice gateway error" exception=e
    end
end

# The highest DAVE version we can speak: libdave's, or 0 without libdave.
_max_dave_version() = LibDave.available() ? LibDave.max_protocol_version() : 0

function _voice_gateway_loop(ws, session::VoiceGatewaySession)
    while session.connected
        data = try
            HTTP.WebSockets.receive(ws)
        catch e
            session.connected && _voice_closed!(session, e)
            break
        end

        (data isa Nothing || data isa HTTP.WebSockets.CloseFrameBody) && break

        if data isa AbstractVector{UInt8}
            _voice_handle_binary(session, data)
            continue
        end

        msg = try
            JSON3.read(data, Dict{String, Any})
        catch e
            @warn "Failed to parse voice gateway JSON" exception=e
            continue
        end
        seq = get(msg, "seq", nothing)
        seq isa Integer && (session.seq_ack = seq)

        _voice_handle_json(ws, session, msg["op"], get(msg, "d", nothing))
    end

    session.connected = false
end

function _voice_handle_json(ws, session::VoiceGatewaySession, op, d)
    if op == VoiceOpcodes.HELLO
        # The interval from HELLO is authoritative (the one in READY is not)
        interval = Float64(d["heartbeat_interval"])
        session.heartbeat_interval = interval
        session.heartbeat_task = errormonitor(@_spawn_io _voice_heartbeat(interval, session))

        _voice_send_json(session, VoiceOpcodes.IDENTIFY, Dict(
            "server_id" => string(session.guild_id),
            "user_id" => string(session.user_id),
            "session_id" => session.session_id,
            "token" => session.token,
            "max_dave_protocol_version" => _max_dave_version(),
        ))

    elseif op == VoiceOpcodes.READY
        session.ssrc = UInt32(d["ssrc"])
        session.ip = d["ip"]
        session.port = d["port"]
        session.modes = d["modes"]
        @info "Voice ready" ssrc=session.ssrc ip=session.ip port=session.port
        notify(session.ready)

    elseif op == VoiceOpcodes.SESSION_DESCRIPTION
        session.secret_key = UInt8.(d["secret_key"])
        dave_version = Int(get(d, "dave_protocol_version", 0))
        @info "Voice session established" mode=d["mode"] dave_protocol_version=dave_version
        if dave_version > 0 || !isnothing(session.dave)
            dave_session_description!(_dave_session!(session), dave_version)
        end
        notify(session.described)

    elseif op == VoiceOpcodes.HEARTBEAT_ACK
        @debug "Voice heartbeat ACK"

    elseif op == VoiceOpcodes.RESUMED
        @info "Voice session resumed"

    elseif op in (VoiceOpcodes.CLIENTS_CONNECT, VoiceOpcodes.CLIENT_DISCONNECT,
                  VoiceOpcodes.DAVE_PREPARE_TRANSITION, VoiceOpcodes.DAVE_EXECUTE_TRANSITION,
                  VoiceOpcodes.DAVE_PREPARE_EPOCH)
        ds = op in (VoiceOpcodes.CLIENTS_CONNECT, VoiceOpcodes.CLIENT_DISCONNECT) ?
            _dave_session_if_possible!(session) : _dave_session!(session)
        isnothing(ds) || dave_handle_json!(ds, op, d)

    else
        @debug "Voice gateway opcode" op
    end
end

function _voice_handle_binary(session::VoiceGatewaySession, frame::AbstractVector{UInt8})
    seq, op, payload = try
        parse_dave_binary(frame)
    catch e
        @warn "Malformed binary voice frame" exception=e
        return
    end
    session.seq_ack = seq
    try
        dave_handle_binary!(_dave_session!(session), op, payload)
    catch e
        @error "DAVE: failed to handle binary opcode" op exception=e
    end
end

# The DAVE session for this connection, created on first use.
function _dave_session!(session::VoiceGatewaySession)
    if isnothing(session.dave)
        LibDave.available() ||
            error("Discord sent a DAVE message but libdave is not loaded (set ENV[\"ACCORD_LIBDAVE\"])")
        session.dave = DaveSession(string(session.user_id), session.channel_id.value;
            send_json = (op, d) -> _voice_send_json(session, op, d),
            send_binary = (op, payload) -> _voice_send_binary(session, op, payload))
    end
    return session.dave
end

# Participant tracking (ops 11/13) is harmless without libdave: skip quietly.
_dave_session_if_possible!(session::VoiceGatewaySession) =
    LibDave.available() ? _dave_session!(session) : nothing

# Voice gateway v8 heartbeat: {"t": nonce, "seq_ack": last sequence number}.
_voice_heartbeat_payload(nonce::Integer, seq_ack::Integer) =
    Dict("t" => nonce, "seq_ack" => seq_ack)

function _voice_heartbeat(interval_ms::Float64, session::VoiceGatewaySession)
    interval = interval_ms / 1000.0
    while session.connected
        try
            _voice_send_json(session, VoiceOpcodes.HEARTBEAT,
                             _voice_heartbeat_payload(round(Int, time() * 1000), session.seq_ack))
        catch e
            @warn "Voice heartbeat send failed" exception=e
            break
        end
        sleep(interval)
    end
end

"""Use this internal function to signal when your bot starts or stops speaking.

Send Speaking opcode to the voice gateway."""
function send_speaking(session::VoiceGatewaySession, speaking::Bool; microphone::Bool=true)
    flags = speaking && microphone ? 1 : 0
    _voice_send_json(session, VoiceOpcodes.SPEAKING,
                     Dict("speaking" => flags, "delay" => 0, "ssrc" => session.ssrc))
end

"""Use this internal function to complete the voice connection handshake after IP discovery.

Send Select Protocol to the voice gateway after IP discovery."""
function send_select_protocol(session::VoiceGatewaySession, our_ip::String, our_port::Int, mode::String)
    _voice_send_json(session, VoiceOpcodes.SELECT_PROTOCOL, Dict(
        "protocol" => "udp",
        "data" => Dict("address" => our_ip, "port" => our_port, "mode" => mode),
    ))
end
