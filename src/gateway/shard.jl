# Shard management — multi-shard support via Tasks

"""
    ShardInfo

Tracks state for a single gateway shard.
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

Start a gateway connection for this shard in a new Task.
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

Signal the shard to disconnect.
"""
function stop_shard(shard::ShardInfo)
    notify(shard.session.stop_event)
    shard.session.connected = false
end

"""
    send_to_shard(shard::ShardInfo, cmd::GatewayCommand)

Send a gateway command to a specific shard.
"""
function send_to_shard(shard::ShardInfo, cmd::GatewayCommand)
    put!(shard.commands, cmd)
end

"""
    shard_for_guild(guild_id::Snowflake, num_shards::Int) -> Int

Calculate which shard handles a given guild.
Formula: (guild_id >> 22) % num_shards
"""
function shard_for_guild(guild_id::Snowflake, num_shards::Int)
    Int((guild_id.value >> 22) % num_shards)
end

"""
    get_gateway_bot(token::String) -> (url, shards, session_start_limit)

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
