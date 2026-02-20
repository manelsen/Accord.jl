# State Actor for Accord.jl

using Actors

"""
    StateActor

An actor that owns the Accord state and responds to queries and updates.
"""
struct GetGuild id::Snowflake end
struct GetUser id::Snowflake end
struct GetChannel id::Snowflake end
struct UpdateState event::AbstractEvent end

function state_actor_behavior(state::State, msg::GetGuild)
    return get(state.guilds, msg.id)
end

function state_actor_behavior(state::State, msg::GetUser)
    return get(state.users, msg.id)
end

function state_actor_behavior(state::State, msg::GetChannel)
    return get(state.channels, msg.id)
end

function state_actor_behavior(state::State, msg::UpdateState)
    update_state!(state, msg.event)
    return nothing
end

# Multi-dispatch behavior for state actor
function state_actor(state::State, msg)
    if msg isa GetGuild
        return state_actor_behavior(state, msg)
    elseif msg isa GetUser
        return state_actor_behavior(state, msg)
    elseif msg isa GetChannel
        return state_actor_behavior(state, msg)
    elseif msg isa UpdateState
        return state_actor_behavior(state, msg)
    else
        @warn "StateActor received unknown message" msg_type=typeof(msg)
        return nothing
    end
end

"""
    spawn_state_actor(state::State)

Spawns a new StateActor and returns its Link.
"""
function spawn_state_actor(state::State)
    # Since State is mutable, we can just pass it and side-effect it
    # Actors.jl ensures sequential access to this specific State object
    return spawn(state_actor, state)
end
