# Gateway WebSocket connection lifecycle

const GATEWAY_URL = "wss://gateway.discord.gg/?v=$(API_VERSION)&encoding=json&compress=zlib-stream"
const ZLIB_SUFFIX = UInt8[0x00, 0x00, 0xff, 0xff]

"""Gateway command sent to the connection actor."""
struct GatewayCommand
    op::Int
    data::Any
end

"""
    GatewaySession

Holds state for a single gateway WebSocket session.
"""
mutable struct GatewaySession
    ws::Any  # WebSocket connection
    session_id::Nullable{String}
    resume_gateway_url::Nullable{String}
    seq::Nullable{Int}
    heartbeat_task::Nullable{Task}
    heartbeat_state::Nullable{HeartbeatState}
    zlib_buffer::IOBuffer
    zlib_stream::Any  # TranscodingStream
    stop_event::Base.Event
    connected::Bool
end

function GatewaySession()
    GatewaySession(nothing, nothing, nothing, nothing, nothing, nothing,
                   IOBuffer(), nothing, Base.Event(), false)
end

"""
    gateway_connect(token, intents, shard, events_channel, commands_channel; resume=false)

Main gateway connection loop. Runs as a Task.
- Connects to Discord gateway via WebSocket
- Handles IDENTIFY/RESUME
- Decompresses zlib-stream payloads
- Dispatches events to `events_channel`
- Receives commands from `commands_channel`
- Auto-reconnects on disconnection
"""
function gateway_connect(
    token::String,
    intents::UInt32,
    shard::Tuple{Int,Int},
    events_channel::Channel{AbstractEvent},
    commands_channel::Channel{GatewayCommand},
    ready_event::Base.Event;
    session::GatewaySession = GatewaySession()
)
    reconnect = true
    resume = false

    while reconnect
        url = if resume && !isnothing(session.resume_gateway_url)
            session.resume_gateway_url * "/?v=$(API_VERSION)&encoding=json&compress=zlib-stream"
        else
            GATEWAY_URL
        end

        @info "Connecting to gateway" url resume

        try
            HTTP.WebSockets.open(url) do ws
                session.ws = ws
                session.connected = true
                session.zlib_buffer = IOBuffer()
                session.stop_event = Base.Event()

                _gateway_loop(ws, token, intents, shard, events_channel,
                             commands_channel, ready_event, session, resume)
            end
        catch e
            if e isa HTTP.WebSockets.WebSocketError
                code = e.status
                @warn "Gateway WebSocket closed" code
                if !GatewayCloseCodes.can_reconnect(code)
                    @error "Cannot reconnect — fatal close code" code
                    reconnect = false
                    continue
                end
            elseif e isa Base.IOError || e isa HTTP.Exceptions.ConnectError
                @warn "Gateway connection error, will retry" exception=e
            else
                @error "Unexpected gateway error" exception=e
                reconnect = false
                continue
            end
        end

        session.connected = false
        if !isnothing(session.heartbeat_state)
            stop_heartbeat!(session.heartbeat_state)
        end

        if reconnect
            resume = !isnothing(session.session_id) && !isnothing(session.seq)
            wait_time = 1.0 + rand() * 4.0
            @info "Reconnecting in $(round(wait_time, digits=1))s" resume
            sleep(wait_time)
        end
    end

    @info "Gateway connection loop ended"
end

function _gateway_loop(
    ws, token, intents, shard, events_channel, commands_channel,
    ready_event, session, resume
)
    while !Base.Event.isready(session.stop_event)
        data = try
            HTTP.WebSockets.receive(ws)
        catch e
            @debug "WebSocket receive error" exception=e
            break
        end

        data isa Nothing && break

        # Decompress zlib-stream
        payload = _decompress(session, data)
        isnothing(payload) && continue

        # Parse JSON
        msg = try
            JSON3.read(payload, Dict{String, Any})
        catch e
            @warn "Failed to parse gateway JSON" exception=e
            continue
        end

        op = msg["op"]
        d = get(msg, "d", nothing)
        s = get(msg, "s", nothing)
        t = get(msg, "t", nothing)

        # Update sequence
        if !isnothing(s)
            session.seq = s
        end

        if op == GatewayOpcodes.DISPATCH
            _handle_dispatch(t, d, events_channel, session, ready_event)

        elseif op == GatewayOpcodes.HELLO
            interval = d["heartbeat_interval"]
            seq_ref = Ref{Union{Int,Nothing}}(session.seq)

            # Start heartbeat
            hb_task, hb_state = start_heartbeat(ws, interval, seq_ref, session.stop_event)
            session.heartbeat_task = hb_task
            session.heartbeat_state = hb_state

            # Identify or Resume
            if resume && !isnothing(session.session_id)
                _send_resume(ws, token, session.session_id, session.seq)
            else
                _send_identify(ws, token, intents, shard)
            end

        elseif op == GatewayOpcodes.HEARTBEAT
            # Immediately send heartbeat
            seq = session.seq
            payload_str = isnothing(seq) ? """{"op":1,"d":null}""" : """{"op":1,"d":$seq}"""
            HTTP.WebSockets.send(ws, payload_str)

        elseif op == GatewayOpcodes.HEARTBEAT_ACK
            if !isnothing(session.heartbeat_state)
                heartbeat_ack!(session.heartbeat_state)
            end

        elseif op == GatewayOpcodes.RECONNECT
            @info "Gateway requested reconnect"
            break

        elseif op == GatewayOpcodes.INVALID_SESSION
            can_resume = d === true
            @warn "Invalid session" can_resume
            if !can_resume
                session.session_id = nothing
                session.seq = nothing
            end
            sleep(1.0 + rand() * 4.0)
            break
        end

        # Process commands from the client
        while isready(commands_channel)
            cmd = take!(commands_channel)
            _send_gateway_command(ws, cmd)
        end
    end
end

function _handle_dispatch(event_name, data, events_channel, session, ready_event)
    isnothing(event_name) && return
    isnothing(data) && return

    # Parse to typed event
    event = parse_event(event_name, data)

    # Capture session info from READY
    if event isa ReadyEvent
        session.session_id = event.session_id
        session.resume_gateway_url = event.resume_gateway_url
        notify(ready_event)
    end

    # Put event into channel (non-blocking)
    try
        put!(events_channel, event)
    catch e
        @warn "Failed to dispatch event" event_name exception=e
    end
end

function _decompress(session::GatewaySession, data)
    if data isa Vector{UInt8}
        write(session.zlib_buffer, data)

        # Check for zlib flush marker
        bufdata = take!(session.zlib_buffer)
        if length(bufdata) >= 4 && bufdata[end-3:end] == ZLIB_SUFFIX
            try
                decompressed = transcode(CodecZlib.ZlibDecompressor, bufdata)
                return String(decompressed)
            catch e
                @warn "Zlib decompression failed" exception=e
                return nothing
            end
        else
            # Incomplete frame, put data back
            write(session.zlib_buffer, bufdata)
            return nothing
        end
    elseif data isa String
        return data
    else
        return nothing
    end
end

function _send_identify(ws, token, intents, shard)
    payload = Dict(
        "op" => GatewayOpcodes.IDENTIFY,
        "d" => Dict(
            "token" => token,
            "intents" => intents,
            "properties" => Dict(
                "os" => string(Sys.KERNEL),
                "browser" => "Accord.jl",
                "device" => "Accord.jl",
            ),
            "shard" => [shard[1], shard[2]],
            "compress" => true,
        )
    )
    HTTP.WebSockets.send(ws, JSON3.write(payload))
end

function _send_resume(ws, token, session_id, seq)
    payload = Dict(
        "op" => GatewayOpcodes.RESUME,
        "d" => Dict(
            "token" => token,
            "session_id" => session_id,
            "seq" => seq,
        )
    )
    HTTP.WebSockets.send(ws, JSON3.write(payload))
end

function _send_gateway_command(ws, cmd::GatewayCommand)
    payload = Dict("op" => cmd.op, "d" => cmd.data)
    HTTP.WebSockets.send(ws, JSON3.write(payload))
end
