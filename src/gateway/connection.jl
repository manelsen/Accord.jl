# Gateway WebSocket connection lifecycle
#
# Internal module: Manages the WebSocket connection to Discord's gateway, including
# connect/reconnect logic, zlib decompression, opcode dispatch (HELLO, HEARTBEAT,
# IDENTIFY, RESUME), and event routing to the client's event channel.

const GATEWAY_URL = "wss://gateway.discord.gg/?v=$(API_VERSION)&encoding=json"

"""Use this internal struct to send control commands to the gateway connection actor.

[`GatewayCommand`](@ref) sent to the connection actor.

# Example
```julia
cmd = GatewayCommand(GatewayOpcodes.PRESENCE_UPDATE, Dict("status" => "online"))
```
"""
struct GatewayCommand
    op::Int
    data::Any
end

"""
    GatewaySession

Use this internal struct to track the state of an active gateway WebSocket connection.

Holds state for a single [`GatewaySession`](@ref).

# Example
```julia
session = GatewaySession()  # creates a fresh, unconnected session
session.connected            # => false
```
"""
mutable struct GatewaySession
    ws::Nullable{HTTP.WebSockets.WebSocket}
    session_id::Nullable{String}
    resume_gateway_url::Nullable{String}
    seq::Nullable{Int}
    seq_ref::Ref{Union{Int,Nothing}}  # shared with heartbeat
    heartbeat_task::Nullable{Task}
    heartbeat_state::Nullable{HeartbeatState}
    zlib_buffer::IOBuffer
    stop_event::Base.Event
    connected::Bool
end

function GatewaySession()
    GatewaySession(nothing, nothing, nothing, nothing, Ref{Union{Int,Nothing}}(nothing),
                   nothing, nothing, IOBuffer(), Base.Event(), false)
end

"""
    gateway_connect(token, intents, shard, events_channel, commands_channel; resume=false)

Use this internal function to establish and maintain a WebSocket connection to Discord's gateway.

Main gateway connection loop. Runs as a `Task`.
- Connects to Discord gateway via WebSocket
- Handles IDENTIFY/RESUME
- Decompresses zlib-stream payloads
- Dispatches events to `events_channel` (which receives [`AbstractEvent`](@ref)s)
- Receives commands from `commands_channel` (which receives [`GatewayCommand`](@ref)s)
- Auto-reconnects on disconnection

!!! note
    This function automatically reconnects on network errors and resumable close codes.
    Fatal close codes (e.g. invalid token, disallowed intents) will stop the loop.
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
        resume_url = session.resume_gateway_url
        url = if resume && !isnothing(resume_url)
            resume_url * "/?v=$(API_VERSION)&encoding=json"
        else
            GATEWAY_URL
        end

        @info "Connecting to gateway" url resume

        try
            HTTP.WebSockets.open(url; readtimeout=0) do ws
                session.ws = ws
                session.connected = true
                session.zlib_buffer = IOBuffer()
                session.stop_event = Base.Event()

                _gateway_loop(ws, token, intents, shard, events_channel,
                             commands_channel, ready_event, session, resume)
            end
        catch e
            if e isa HTTP.WebSockets.WebSocketError
                msg = e.message
                if msg isa HTTP.WebSockets.CloseFrameBody
                    code = msg.status
                    @warn "Gateway WebSocket closed" code
                    if !GatewayCloseCodes.can_reconnect(code)
                        @error "Cannot reconnect — fatal close code" code
                        # DIAGNOSTICS
                        Accord.Diagnoser.report(e, catch_backtrace())
                        reconnect = false
                        continue
                    end
                else
                    @warn "Gateway WebSocket error" message=msg
                end
            elseif e isa Base.IOError || e isa HTTP.Exceptions.ConnectError
                @warn "Gateway connection error, will retry" exception=e
            else
                @error "Unexpected gateway error" exception=e
                reconnect = false
                continue
            end
        end

        hb = session.heartbeat_state
        if !isnothing(hb)
            stop_heartbeat!(hb)
        end

        # If session was explicitly stopped (connected set to false externally), don't reconnect
        if !session.connected
            reconnect = false
        end
        session.connected = false

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
    while !session.stop_event.set
        data = try
            HTTP.WebSockets.receive(ws)
        catch e
            @warn "WebSocket receive error, breaking loop" exception=e
            break
        end

        if data isa Nothing || data isa HTTP.WebSockets.CloseFrameBody
            @warn "WebSocket received close/nothing, breaking loop"
            break
        end

        # Decompress zlib-stream
        payload = _decompress(session, data)
        isnothing(payload) && continue

        # Parse JSON
        # To avoid double-parsing the 'd' payload, we use JSON3.read(payload) to get an Object
        # then we extract the raw string representation of 'd'.
        msg_obj = try
            JSON3.read(payload)
        catch e
            @warn "Failed to parse gateway JSON" exception=e
            continue
        end

        op = get(msg_obj, :op, nothing)
        d_obj = get(msg_obj, :d, nothing)
        s = get(msg_obj, :s, nothing)
        t = get(msg_obj, :t, nothing)

        # Update sequence
        if !isnothing(s)
            session.seq = Int(s)
            session.seq_ref[] = session.seq
        end

        if op == GatewayOpcodes.DISPATCH
            # t is the event name (String)
            # d_obj is the data. We want the raw JSON of d.
            # JSON3.write(d_obj) is efficient if d_obj is a JSON3.Object
            d_raw = !isnothing(d_obj) ? JSON3.write(d_obj) : nothing
            _handle_dispatch(string(t), d_raw, events_channel, session, ready_event)

        elseif op == GatewayOpcodes.HELLO
            interval = d_obj[:heartbeat_interval]
            # Start heartbeat (use session's persistent seq_ref)
            hb_task, hb_state = start_heartbeat(ws, interval, session.seq_ref, session.stop_event)
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
            hb_state = session.heartbeat_state
            if !isnothing(hb_state)
                heartbeat_ack!(hb_state)
            end

        elseif op == GatewayOpcodes.RECONNECT
            @info "Gateway requested reconnect"
            break

        elseif op == GatewayOpcodes.INVALID_SESSION
            can_resume = d_obj === true
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
        return String(data)
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
