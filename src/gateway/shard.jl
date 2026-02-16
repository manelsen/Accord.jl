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

# Example
```julia
events = Channel{AbstractEvent}(1024)
shard = ShardInfo(0, 1, events)  # shard 0 of 1
```
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

# Example
```julia
task = start_shard(shard, "Bot my_token", UInt32(513))
```
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

# Example
```julia
stop_shard(shard)  # triggers graceful shutdown
```
"""
function stop_shard(shard::ShardInfo)
    notify(shard.session.stop_event)
    shard.session.connected = false
end

"""
    send_to_shard(shard::ShardInfo, cmd::GatewayCommand)

Use this internal function to send control commands to a running shard.

Send a [`GatewayCommand`](@ref) to a specific [`ShardInfo`](@ref).

# Example
```julia
cmd = GatewayCommand(GatewayOpcodes.PRESENCE_UPDATE, payload)
send_to_shard(shard, cmd)
```
"""
function send_to_shard(shard::ShardInfo, cmd::GatewayCommand)
    put!(shard.commands, cmd)
end

"""
    shard_for_guild(guild_id::Snowflake, num_shards::Int) -> Int

Use this internal function to determine which shard should handle events for a specific guild.

Calculate which shard handles a given guild [`Snowflake`](@ref).
Formula: (guild_id >> 22) % num_shards

# Example
```julia
shard_id = shard_for_guild(Snowflake(123456789), 4)  # => 0, 1, 2, or 3
```
"""
function shard_for_guild(guild_id::Snowflake, num_shards::Int)
    Int((guild_id.value >> 22) % num_shards)
end

"""
    get_gateway_bot(token::String) -> (url, shards, session_start_limit)

Use this to retrieve gateway connection info and determine how many shards your bot needs.

Fetch /gateway/bot to get recommended shard count and session limits.

# Example
```julia
info = get_gateway_bot("Bot my_token")
println("Recommended shards: ", info.shards)
println("Remaining sessions: ", info.session_start_limit["remaining"])
```
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
