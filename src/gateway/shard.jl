# Shard management — multi-shard support via Tasks
#
# Internal module: Manages the lifecycle of individual gateway shards. Each shard
# runs as an async Task and communicates via Channels for events and commands.

"""
    IdentifyLimiter

Paces IDENTIFY across a bot's shards. Discord allows one identify per 5 seconds
in each bucket, and a shard's bucket is `shard_id % max_concurrency`
(`max_concurrency` comes from `GET /gateway/bot`). Going faster gets the session
invalidated. One limiter is shared by all shards of a client and is consulted
before every new session, including reconnects; resumes don't identify.
"""
mutable struct IdentifyLimiter
    max_concurrency::Int
    next_slot::Vector{Float64}  # per bucket: earliest time() of its next identify
    configured::Bool            # max_concurrency given or fetched, not the default
    lock::ReentrantLock
end

const IDENTIFY_INTERVAL = 5.0

function IdentifyLimiter(max_concurrency::Union{Int, Nothing}=nothing)
    !isnothing(max_concurrency) && max_concurrency < 1 &&
        throw(ArgumentError("max_concurrency must be >= 1, got $max_concurrency"))
    mc = something(max_concurrency, 1)
    IdentifyLimiter(mc, zeros(mc), !isnothing(max_concurrency), ReentrantLock())
end

function set_max_concurrency!(lim::IdentifyLimiter, mc::Int)
    mc >= 1 || throw(ArgumentError("max_concurrency must be >= 1, got $mc"))
    lock(lim.lock) do
        lim.max_concurrency = mc
        lim.next_slot = zeros(mc)
        lim.configured = true
    end
    return lim
end

# Reserve the next identify slot of `shard_id`'s bucket and sleep until it.
# Slots are handed out in call order, so shards started in order identify in order.
function wait_identify!(lim::IdentifyLimiter, shard_id::Int)
    at = lock(lim.lock) do
        b = shard_id % lim.max_concurrency + 1
        t = max(time(), lim.next_slot[b])
        lim.next_slot[b] = t + IDENTIFY_INTERVAL
        t
    end
    delay = at - time()
    delay > 0 && sleep(delay)
    return nothing
end

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
    identify_limiter::IdentifyLimiter
end

function ShardInfo(id::Int, total::Int, events::Channel{AbstractEvent},
                   identify_limiter::IdentifyLimiter=IdentifyLimiter())
    ShardInfo(
        id, total, nothing, GatewaySession(),
        events, Channel{GatewayCommand}(64),
        Base.Event(), identify_limiter
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
    shard.session.stopped = false
    shard.task = @_spawn_io gateway_connect(
        token, intents, (shard.id, shard.total),
        shard.events, shard.commands, shard.ready;
        session=shard.session, identify_limiter=shard.identify_limiter
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
    shard.session.stopped = true
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
    resp.status >= 400 && error("Discord API error ($(resp.status)): $(String(resp.body))")
    data = JSON3.read(resp.body, Dict{String, Any})
    return (
        url = data["url"],
        shards = data["shards"],
        session_start_limit = data["session_start_limit"],
    )
end
