# Recipe 08 — Sharding

**Difficulty:** Advanced
**What you will build:** Multi-shard bots for scaling beyond 2,500 guilds.

**Prerequisites:** [Recipe 01](01-basic-bot.md), [Recipe 07](07-caching.md)

---

## 1. When Do You Need Sharding?

!!! note "Discord's 2500-Guild Shard Requirement"
    Discord **requires** sharding when your bot joins **2,500 or more guilds**. Each shard handles a subset of guilds. Without sharding, your bot will receive gateway close code 4011 ("Sharding required") and cannot connect.

Discord requires sharding when your bot joins **2,500+ guilds**. Each shard handles a subset of guilds:

```text
Shard 0: guilds where (guild_id >> 22) % num_shards == 0
Shard 1: guilds where (guild_id >> 22) % num_shards == 1
...
```

## 2. Basic Sharding Setup

```julia
using Accord

token = ENV["DISCORD_TOKEN"]

# 4 shards
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
    num_shards = 4,
)

on(client, [`ReadyEvent`](@ref)) do c, event
    shard_info = ismissing(event.shard) ? "N/A" : "$(event.shard[1])/$(event.shard[2])"
    @info "Shard ready!" shard=shard_info guilds=length(event.guilds)
end

on(client, [`MessageCreate`](@ref)) do c, event
    msg = event.message
    ismissing(msg.content) && return
    msg.content == "!ping" && create_message(c, msg.channel_id; content="Pong!")
end

start(client)
```

Accord.jl starts shards with a 5-second delay between them (Discord's required rate limit).

!!! warning "Shard Count is Immutable After Connection"
    The number of shards (`num_shards`) cannot be changed while the bot is running. To change shard count, you must restart the bot. Plan your shard count based on current guild count plus expected growth.

## 3. How Shards Work Internally

```julia
struct ShardInfo
    id::Int          # 0-indexed shard ID
    total::Int       # total number of shards
    task::[`Task`](@ref)        # the async gateway connection task
    session::[`GatewaySession`](@ref)
    events::Channel{[`AbstractEvent`](@ref)}   # shared across all shards
    commands::Channel{[`GatewayCommand`](@ref)}
    ready::Base.Event
end
```

Key design:
- All shards share a **single events channel** — your handlers see events from all shards
- The [`Client`](@ref) routes gateway commands (voice state, presence) to the correct shard automatically
- Shard assignment: `shard_for_guild(guild_id, num_shards)` uses `(guild_id >> 22) % num_shards`

## 4. Auto-Detecting Shard Count

Discord's `/gateway/bot` endpoint tells you the recommended shard count:

```julia
info = get_gateway_bot("Bot $token")

println("Gateway URL: ", info.url)
println("Recommended shards: ", info.shards)
println("Session start limit: ", info.session_start_limit)

# Use the recommended count
client = Client(token; num_shards=info.shards)
```

The `session_start_limit` tells you how many session starts you have left (resets daily). This is important because each shard start costs one session.

## 5. Shard-Aware Operations

The [`Client`](@ref) automatically routes to the correct shard:

```julia
# This sends VOICE_STATE_UPDATE to the shard handling this guild
update_voice_state(client, guild_id; channel_id=voice_channel_id)

# This sends to ALL shards (presence is global)
update_presence(client; status="online", activities=[
    Dict("name" => "with $(client.num_shards) shards", "type" => ActivityTypes.GAME)
])

# This routes to the correct shard
request_guild_members(client, guild_id; query="", limit=100)
```

The routing formula:

```julia
shard_id = shard_for_guild(guild_id, client.num_shards)
shard = client.shards[shard_id + 1]  # 1-indexed Julia array
```

## 6. Multi-Process Sharding

For very large bots (50k+ guilds), you may want separate Julia processes per shard cluster. Here's a pattern:

### Launcher Script

```julia
# launcher.jl — starts one process per shard cluster
using Distributed

info = get_gateway_bot("Bot $(ENV["DISCORD_TOKEN"])")
total_shards = info.shards
shards_per_process = 4

for cluster_start in 0:shards_per_process:(total_shards - 1)
    cluster_end = min(cluster_start + shards_per_process - 1, total_shards - 1)
    shard_ids = cluster_start:cluster_end

    @info "Launching cluster" shards=shard_ids
    run(`julia --project=. shard_worker.jl
        --total-shards=$total_shards
        --shard-start=$cluster_start
        --shard-end=$cluster_end`; wait=false)
end
```

### Shard Worker

```julia
# shard_worker.jl — runs a subset of shards
using Accord

total = parse(Int, ARGS[findfirst(a -> a == "--total-shards", ARGS) + 1])
shard_start = parse(Int, ARGS[findfirst(a -> a == "--shard-start", ARGS) + 1])
shard_end = parse(Int, ARGS[findfirst(a -> a == "--shard-end", ARGS) + 1])
num_local = shard_end - shard_start + 1

@info "Worker starting" shards="$shard_start-$shard_end" total=total

client = Client(ENV["DISCORD_TOKEN"];
    intents = IntentGuilds | IntentGuildMessages,
    num_shards = total,
    # Only connect the shards assigned to this process
    # (requires custom shard range support)
)

# Register handlers...
start(client)
```

## 7. Monitoring Shard Health

```julia
function shard_status(client)
    for shard in client.shards
        status = if isnothing(shard.task)
            "not started"
        elseif istaskdone(shard.task)
            istaskfailed(shard.task) ? "failed" : "stopped"
        else
            "running"
        end
        @info "Shard $(shard.id)/$(shard.total)" status=status session_connected=shard.session.connected
    end
end

# Call periodically
on(client, ReadyEvent) do c, event
    @async begin
        while c.running
            sleep(60)
            shard_status(c)
        end
    end
end
```

## 8. Guild Count Across Shards

```julia
on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.content) && return

    if msg.content == "!guilds"
        total = length(c.state.guilds)
        create_message(c, msg.channel_id;
            content="I'm in **$total** guilds across **$(c.num_shards)** shards.")
    end
end
```

---

**Next steps:** [Recipe 09 — Auto-Moderation](09-automod.md) or [Recipe 11 — Architectural Patterns](11-architectural-patterns.md) for production structure.
