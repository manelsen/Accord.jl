# Heartbeat actor — runs as a Task, sends heartbeats at the specified interval
#
# Internal module: Sends OP 1 Heartbeat payloads at the interval specified by
# Discord's HELLO payload. Detects zombie connections when ACKs stop arriving.

mutable struct HeartbeatState
    interval_ms::Int
    last_send::Float64
    last_ack::Float64
    seq::Nullable{Int}
    ack_received::Bool
    running::Bool
    lock::ReentrantLock  # the heartbeat task and the receive loop run on different threads
end

HeartbeatState(interval_ms::Int) = HeartbeatState(
    interval_ms, 0.0, 0.0, nothing, true, true, ReentrantLock()
)

"""
    start_heartbeat(ws, interval_ms, seq_ref, stop_event; send_lock=ReentrantLock()) -> (Task, HeartbeatState)

Use this internal function to maintain the gateway connection by sending periodic heartbeats.

Launch a heartbeat actor that sends OP 1 Heartbeat at the given interval.
Returns the `Task`. Set `stop_event` to signal shutdown.

`seq_ref` is a `Ref{Union{Int,Nothing}}` tracking the last sequence number.
`send_lock` must be the lock shared by every writer of `ws` (and by the writer
of `seq_ref`), so heartbeat frames never interleave with other gateway sends.
"""
function start_heartbeat(ws, interval_ms::Int, seq_ref::Ref, stop_event::Base.Event;
                         send_lock::ReentrantLock=ReentrantLock())
    state = HeartbeatState(interval_ms)

    task = @_spawn_io begin
        # Jitter: first heartbeat at interval * rand()
        sleep(interval_ms * rand() / 1000.0)

        while state.running && !stop_event.set
            # Was the previous heartbeat acknowledged? If so, mark the next one
            # as pending *before* sending it, so a fast ACK can't be lost.
            zombie = lock(state.lock) do
                !state.ack_received && state.last_send > 0 && return true
                state.ack_received = false
                state.last_send = time()
                return false
            end

            if zombie
                @warn "Heartbeat ACK not received — zombie connection detected"
                stop_heartbeat!(state)
                # Actively close the WebSocket to unblock the main receive loop
                try
                    HTTP.WebSockets.close(ws)
                catch
                    # Ignore close errors, we just want it dead
                end
                break
            end

            try
                lock(send_lock) do
                    seq = seq_ref[]
                    HTTP.WebSockets.send(ws, isnothing(seq) ? """{"op":1,"d":null}""" : """{"op":1,"d":$seq}""")
                end
            catch e
                @warn "Failed to send heartbeat" exception=e
                stop_heartbeat!(state)
                break
            end

            sleep(interval_ms / 1000.0)
        end
    end

    return errormonitor(task), state
end

"""Use this to acknowledge receipt of a heartbeat ACK from the gateway.

Mark that a heartbeat ACK was received."""
function heartbeat_ack!(state::HeartbeatState)
    lock(state.lock) do
        state.last_ack = time()
        state.ack_received = true
    end
end

"""Use this to terminate the heartbeat task gracefully.

Stop the heartbeat loop."""
stop_heartbeat!(state::HeartbeatState) = lock(() -> state.running = false, state.lock)

"""Use this to measure the round-trip time between your bot and Discord's gateway.

Calculate the current latency in milliseconds."""
function heartbeat_latency(state::HeartbeatState)
    if state.last_ack > 0 && state.last_send > 0
        return (state.last_ack - state.last_send) * 1000
    end
    return -1.0
end
