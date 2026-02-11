# Recipe 07 — Caching Strategies

**Difficulty:** Intermediate
**What you will build:** Per-resource cache configuration, memory-efficient state for bots at any scale.

**Prerequisites:** [Recipe 01](01-basic-bot.md)

---

## 1. Why Caching Matters

Every time you call `get_guild`, `get_channel`, or `get_user`, Accord.jl checks its in-memory cache first. Cache hits avoid:
- REST API calls (each costs ~50-200ms)
- Rate limit consumption (you only get ~50 requests/second)

But caching everything wastes memory. Accord.jl lets you choose per resource type.

## 2. The Four Cache Strategies

| Strategy | Constructor | Behavior |
|----------|-----------|----------|
| **CacheForever** | `CacheForever()` | Keep everything, never evict |
| **CacheNever** | `CacheNever()` | Never cache, always fetch from API |
| **CacheLRU** | `CacheLRU(n)` | Keep the `n` most recently used entries |
| **CacheTTL** | `CacheTTL(seconds)` | Expire entries after `seconds` |

## 3. Per-Resource Configuration

Configure caching in the `Client` constructor:

```julia
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages,

    # Cache strategies (these are the defaults)
    guild_strategy    = CacheForever(),     # guilds are small, keep all
    channel_strategy  = CacheForever(),     # channels are small, keep all
    user_strategy     = CacheLRU(10_000),   # keep 10k most active users
    member_strategy   = CacheLRU(10_000),   # keep 10k most active members
    presence_strategy = CacheNever(),       # presences are large, skip
)
```

## 4. Decision Matrix

Choose based on your bot's scale:

| Bot Size | Guilds | Users | Recommended Config |
|----------|--------|-------|--------------------|
| **Small** (<100 guilds) | `CacheForever()` | `CacheForever()` | Cache everything |
| **Medium** (100-1000 guilds) | `CacheForever()` | `CacheLRU(50_000)` | LRU for users/members |
| **Large** (1000+ guilds) | `CacheForever()` | `CacheLRU(100_000)` | LRU or TTL for users/members |
| **Very Large** (10k+ guilds) | `CacheTTL(3600)` | `CacheLRU(100_000)` | TTL for guilds too |

### Small Bot (Just Cache Everything)

```julia
client = Client(token;
    guild_strategy    = CacheForever(),
    channel_strategy  = CacheForever(),
    user_strategy     = CacheForever(),
    member_strategy   = CacheForever(),
    presence_strategy = CacheNever(),  # still skip presences
)
```

### Large Bot (Memory Conscious)

```julia
client = Client(token;
    guild_strategy    = CacheForever(),       # guilds are always needed
    channel_strategy  = CacheLRU(50_000),     # only active channels
    user_strategy     = CacheLRU(100_000),    # ~100k users
    member_strategy   = CacheLRU(100_000),
    presence_strategy = CacheNever(),
)
```

## 5. How `Store{T}` Works Internally

Each resource type has a `Store{T}`:

```julia
mutable struct Store{T}
    strategy::CacheStrategy
    data::Dict{Snowflake, T}        # the actual cache
    access_order::Vector{Snowflake}  # LRU tracking
    timestamps::Dict{Snowflake, Float64}  # TTL tracking
    maxsize::Int
end
```

- **CacheForever**: items go in `data`, never removed
- **CacheNever**: `setindex!` is a no-op, `get` always returns `nothing`
- **CacheLRU**: on access, the key moves to end of `access_order`; when full, the oldest is evicted
- **CacheTTL**: on access, checks if `time() - timestamps[key] > ttl`; if so, deletes and returns `nothing`

## 6. Automatic Cache Updates

The cache updates automatically from gateway events:

| Event | Cache Action |
|-------|-------------|
| `ReadyEvent` | Sets `state.me`, caches unavailable guilds |
| `GuildCreate` | Caches guild, channels, roles, emojis, members |
| `GuildUpdate` | Updates guild |
| `GuildDelete` | Removes guild and all associated data |
| `ChannelCreate/Update` | Caches channel |
| `ChannelDelete` | Removes channel |
| `GuildMemberAdd` | Caches member and user |
| `GuildMemberRemove` | Removes member |
| `GuildMemberUpdate` | Updates member fields |
| `GuildRoleCreate/Update` | Caches role |
| `GuildRoleDelete` | Removes role |
| `MessageCreate` | Caches message author |
| `VoiceStateUpdateEvent` | Updates voice state tracking |

## 7. Memory Estimation

Rough per-object memory estimates:

| Object | Approximate Size |
|--------|-----------------|
| `Guild` | 2-5 KB |
| `DiscordChannel` | 0.5-1 KB |
| `User` | 0.3-0.5 KB |
| `Member` | 0.2-0.5 KB |
| `Role` | 0.2-0.3 KB |
| `Presence` | 0.5-2 KB |

For a bot in 1,000 guilds with an average 500 members per guild:
- Guilds: 1,000 × 3 KB ≈ **3 MB**
- Channels: ~15,000 × 0.7 KB ≈ **10 MB**
- Users (LRU 100k): 100,000 × 0.4 KB ≈ **40 MB**

Total: ~53 MB — very manageable.

## 8. Inspecting the Cache

Use non-blocking mode for REPL inspection:

```julia
start(client; blocking=false)
wait_until_ready(client)

# Cache stats
@info "Guilds:   $(length(client.state.guilds))"
@info "Channels: $(length(client.state.channels))"
@info "Users:    $(length(client.state.users))"

# Look up a specific guild
guild = get(client.state.guilds, Snowflake(123456789))
guild.name

# List cached roles for a guild
roles = get(client.state.roles, Snowflake(123456789), nothing)
if !isnothing(roles)
    for role in values(roles)
        println("  $(role.name): $(role.id)")
    end
end
```

## 9. Custom Application-Level Caching

For external API data, build your own TTL cache:

```julia
mutable struct TTLCache{K, V}
    data::Dict{K, Tuple{V, Float64}}
    ttl::Float64
end

TTLCache{K, V}(ttl::Float64) where {K, V} = TTLCache{K, V}(Dict{K, Tuple{V, Float64}}(), ttl)

function Base.get(cache::TTLCache{K, V}, key::K, default=nothing) where {K, V}
    if haskey(cache.data, key)
        val, ts = cache.data[key]
        if time() - ts <= cache.ttl
            return val
        end
        delete!(cache.data, key)
    end
    return default
end

function Base.setindex!(cache::TTLCache{K, V}, value::V, key::K) where {K, V}
    cache.data[key] = (value, time())
end

# Usage: cache weather API responses for 5 minutes
const weather_cache = TTLCache{String, Dict}(300.0)
```

---

**Next steps:** [Recipe 08 — Sharding](08-sharding.md) if your bot is in 2,500+ guilds.
