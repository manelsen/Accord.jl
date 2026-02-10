# Heartbeat actor — runs as a Task, sends heartbeats at the specified interval

mutable struct HeartbeatState
    interval_ms::Int
    last_send::Float64
    last_ack::Float64
    seq::Nullable{Int}
    ack_received::Bool
    running::Bool
end

HeartbeatState(interval_ms::Int) = HeartbeatState(
    interval_ms, 0.0, 0.0, nothing, true, true
)

"""
    start_heartbeat(ws, interval_ms, seq_ref, stop_event) -> Task

Launch a heartbeat actor that sends OP 1 Heartbeat at the given interval.
Returns the Task. Set `stop_event` to signal shutdown.

`seq_ref` is a `Ref{Union{Int,Nothing}}` tracking the last sequence number.
"""
function start_heartbeat(ws, interval_ms::Int, seq_ref::Ref, stop_event::Base.Event)
    state = HeartbeatState(interval_ms)

    task = @async begin
        # Jitter: first heartbeat at interval * rand()
        first_wait = interval_ms * rand() / 1000.0
        sleep(first_wait)

        while state.running && !stop_event.set
            # Check if we got an ACK for the last heartbeat
            if !state.ack_received && state.last_send > 0
                @warn "Heartbeat ACK not received — zombie connection detected"
                state.running = false
                break
            end

            # Send heartbeat
            payload = if isnothing(seq_ref[])
                """{"op":1,"d":null}"""
            else
                """{"op":1,"d":$(seq_ref[])}"""
            end

            try
                HTTP.WebSockets.send(ws, payload)
                state.last_send = time()
                state.ack_received = false
            catch e
                @warn "Failed to send heartbeat" exception=e
                state.running = false
                break
            end

            # Wait for next interval
            sleep(interval_ms / 1000.0)
        end
    end

    return task, state
end

"""Mark that a heartbeat ACK was received."""
function heartbeat_ack!(state::HeartbeatState)
    state.last_ack = time()
    state.ack_received = true
end

"""Stop the heartbeat loop."""
function stop_heartbeat!(state::HeartbeatState)
    state.running = false
end

"""Calculate the current latency in milliseconds."""
function heartbeat_latency(state::HeartbeatState)
    if state.last_ack > 0 && state.last_send > 0
        return (state.last_ack - state.last_send) * 1000
    end
    return -1.0
end
