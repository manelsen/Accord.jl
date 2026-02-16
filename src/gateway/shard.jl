# Shard management — multi-shard support via Tasks
#
# Internal module: Manages the lifecycle of individual gateway shards. Each shard
# runs as an async Task and communicates via Channels for events and commands.

"""
    ShardInfo

Use this internal struct to manage the lifecycle and events of a single gateway shard.

Tracks state for a single gateway shard. Uses [`GatewaySession`](@ref) for the connection.
Events are dispatched to a shared [`AbstractEvent`](@ref) channel.
Commands are received via a [`GatewayCommand`](@ref) channel.
"""
mutable struct ShardInfo
    id::Int
    total::Int
    task::Nullable{Task}
    session::GatewaySession
    events::Channel{AbstractEvent}
    commands::Channel{GatewayCommand}
    ready::Base.Event
end

function ShardInfo(id::Int, total::Int, events::Channel{AbstractEvent})
    ShardInfo(
        id, total, nothing, GatewaySession(),
        events, Channel{GatewayCommand}(64),
        Base.Event()
    )
end

"""
    start_shard(shard::ShardInfo, token::String, intents::UInt32)

Use this internal function to launch a new shard connection as a background task.

Start a gateway connection for this [`ShardInfo`](@ref) in a new `Task`.
"""
function start_shard(shard::ShardInfo, token::String, intents::UInt32)
    shard.task = @async gateway_connect(
        token, intents, (shard.id, shard.total),
        shard.events, shard.commands, shard.ready;
        session=shard.session
    )
    return shard.task
end

"""
    stop_shard(shard::ShardInfo)

Use this internal function to gracefully terminate a shard connection.

Signal the [`ShardInfo`](@ref) to disconnect.
"""
function stop_shard(shard::ShardInfo)
    notify(shard.session.stop_event)
    shard.session.connected = false
end

"""
    send_to_shard(shard::ShardInfo, cmd::GatewayCommand)

Use this internal function to send control commands to a running shard.

Send a [`GatewayCommand`](@ref) to a specific [`ShardInfo`](@ref).
"""
function send_to_shard(shard::ShardInfo, cmd::GatewayCommand)
    put!(shard.commands, cmd)
end

"""
    shard_for_guild(guild_id::Snowflake, num_shards::Int) -> Int

Use this internal function to determine which shard should handle events for a specific guild.

Calculate which shard handles a given guild [`Snowflake`](@ref).
Formula: (guild_id >> 22) % num_shards
"""
function shard_for_guild(guild_id::Snowflake, num_shards::Int)
    Int((guild_id.value >> 22) % num_shards)
end

"""
    get_gateway_bot(token::String) -> (url, shards, session_start_limit)

Use this to retrieve gateway connection info and determine how many shards your bot needs.

Fetch /gateway/bot to get recommended shard count and session limits.
"""
function get_gateway_bot(token::String)
    headers = [
        "Authorization" => token,
        "User-Agent" => USER_AGENT,
    ]
    resp = HTTP.get("$(API_BASE)/gateway/bot", headers)
    data = JSON3.read(resp.body, Dict{String, Any})
    return (
        url = data["url"],
        shards = data["shards"],
        session_start_limit = data["session_start_limit"],
    )
end
