# Shard Actor for Accord.jl

using Actors

"""
    StartShard(token::String, intents::UInt32)

Message to start the shard connection.
"""
struct StartShard
    token::String
    intents::UInt32
end

"""
    SendCommand(cmd::GatewayCommand)

Message to send a gateway command (e.g., PresenceUpdate).
"""
struct SendCommand
    cmd::GatewayCommand
end

"""
    StopShard

Message to stop the shard connection.
"""
struct StopShard end

function shard_actor_behavior(shard::ShardInfo, msg)
    if msg isa StartShard
        # Launches the gateway loop in a Task.
        # The ShardActor supervises this ShardInfo's session.
        start_shard(shard, msg.token, msg.intents)
    elseif msg isa SendCommand
        put!(shard.commands, msg.cmd)
    elseif msg isa StopShard
        stop_shard(shard)
    else
        @warn "ShardActor received unknown message" msg_type=typeof(msg) shard_id=shard.id
    end
    return nothing
end

function spawn_shard_actor(shard::ShardInfo)
    return spawn(shard_actor_behavior, shard)
end
