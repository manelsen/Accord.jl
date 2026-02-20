# Event Dispatcher Actor for Accord.jl

using Actors

"""
    DispatchEvent(event::AbstractEvent)

Message to dispatch an incoming gateway event.
"""
struct DispatchEvent event::AbstractEvent end

function dispatch_actor(client::Client, msg)
    if msg isa DispatchEvent
        event = msg.event
        
        # 1. Update state (we can cast this to state actor later, or do it here if client.state is still a struct)
        # For now, let's assume we call the state actor
        if hasproperty(client, :state_actor) && !isnothing(client.state_actor)
            cast(client.state_actor, UpdateState(event))
        else
            update_state!(client.state, event)
        end

        # 2. Dispatch to user handlers
        dispatch_event!(client.event_handler, client, event)

        # 3. Notify waiters
        _notify_waiters!(client, event)
    else
        @warn "DispatchActor received unknown message" msg_type=typeof(msg)
    end
    return nothing
end

function spawn_dispatch_actor(client::Client)
    return spawn(dispatch_actor, client)
end
