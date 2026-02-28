# Voice gateway WebSocket connection
#
# Internal module: Manages the voice-specific WebSocket connection to Discord.
# Handles voice HELLO, READY, SESSION_DESCRIPTION opcodes and heartbeating.

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
end

function VoiceGatewaySession(guild_id::Snowflake, channel_id::Snowflake, user_id::Snowflake,
                             session_id::String, endpoint::String, token::String)
    VoiceGatewaySession(
        nothing, guild_id, channel_id, user_id, session_id,
        # Remove trailing port if present, ensure wss://
        startswith(endpoint, "wss://") ? endpoint : "wss://$endpoint",
        token, UInt32(0), "", 0, String[], UInt8[], 0.0,
        nothing, false, Base.Event()
    )
end

"""
    voice_gateway_connect(session::VoiceGatewaySession) -> Task

Use this internal function to establish the voice gateway connection.

Connect to the voice gateway WebSocket and complete the handshake.
"""
function voice_gateway_connect(session::VoiceGatewaySession)
    url = "$(session.endpoint)/?v=8"

    @async begin
        try
            HTTP.WebSockets.open(url) do ws
                session.ws = ws
                session.connected = true
                _voice_gateway_loop(ws, session)
            end
        catch e
            @error "Voice gateway error" exception=e
            session.connected = false
        end
    end
end

function _voice_gateway_loop(ws, session::VoiceGatewaySession)
    while session.connected
        data = try
            HTTP.WebSockets.receive(ws)
        catch e
            @debug "Voice WS receive error" exception=e
            break
        end

        (data isa Nothing || data isa HTTP.WebSockets.CloseFrameBody) && break

        msg = try
            JSON3.read(data, Dict{String, Any})
        catch e
            @warn "Failed to parse voice gateway JSON" exception=e
            continue
        end

        op = msg["op"]
        d = get(msg, "d", nothing)

        if op == VoiceOpcodes.HELLO
            # Start heartbeat
            interval = d["heartbeat_interval"]
            session.heartbeat_interval = interval
            session.heartbeat_task = @async _voice_heartbeat(ws, interval, session)

            # Send Identify
            identify = Dict(
                "op" => VoiceOpcodes.IDENTIFY,
                "d" => Dict(
                    "server_id" => string(session.guild_id),
                    "user_id" => string(session.user_id),
                    "session_id" => session.session_id,
                    "token" => session.token,
                )
            )
            HTTP.WebSockets.send(ws, JSON3.write(identify))

        elseif op == VoiceOpcodes.READY
            session.ssrc = UInt32(d["ssrc"])
            session.ip = d["ip"]
            session.port = d["port"]
            session.modes = d["modes"]
            @info "Voice ready" ssrc=session.ssrc ip=session.ip port=session.port

            # Notify that the voice session is ready for IP discovery
            notify(session.ready)

        elseif op == VoiceOpcodes.SESSION_DESCRIPTION
            session.secret_key = UInt8.(d["secret_key"])
            @info "Voice session established" mode=d["mode"]

        elseif op == VoiceOpcodes.HEARTBEAT_ACK
            # ACK received
            @debug "Voice heartbeat ACK"

        elseif op == VoiceOpcodes.RESUMED
            @info "Voice session resumed"

        else
            @debug "Voice gateway opcode" op
        end
    end

    session.connected = false
end

function _voice_heartbeat(ws, interval_ms::Float64, session::VoiceGatewaySession)
    interval = interval_ms / 1000.0
    while session.connected
        nonce = rand(UInt32)
        payload = Dict("op" => VoiceOpcodes.HEARTBEAT, "d" => nonce)
        try
            HTTP.WebSockets.send(ws, JSON3.write(payload))
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
    ws = session.ws
    isnothing(ws) && throw(ArgumentError("Voice gateway websocket is not connected"))

    flags = microphone ? 1 : 0
    if !speaking
        flags = 0
    end
    payload = Dict(
        "op" => VoiceOpcodes.SPEAKING,
        "d" => Dict(
            "speaking" => flags,
            "delay" => 0,
            "ssrc" => session.ssrc,
        )
    )
    HTTP.WebSockets.send(ws, JSON3.write(payload))
end

"""Use this internal function to complete the voice connection handshake after IP discovery.

Send Select Protocol to the voice gateway after IP discovery."""
function send_select_protocol(session::VoiceGatewaySession, our_ip::String, our_port::Int, mode::String)
    ws = session.ws
    isnothing(ws) && throw(ArgumentError("Voice gateway websocket is not connected"))

    payload = Dict(
        "op" => VoiceOpcodes.SELECT_PROTOCOL,
        "d" => Dict(
            "protocol" => "udp",
            "data" => Dict(
                "address" => our_ip,
                "port" => our_port,
                "mode" => mode,
            )
        )
    )
    HTTP.WebSockets.send(ws, JSON3.write(payload))
end
