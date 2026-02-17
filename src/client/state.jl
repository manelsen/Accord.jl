# State management and caching

using LRUCache

"""Use this abstract type to define how Discord objects are cached in memory.

Cache strategy for a resource type.

# Subtypes
- `CacheForever()`: Keep entries indefinitely.
- `CacheNever()`: Do not cache entries.
- `CacheLRU(maxsize)`: Keep only the most recently used entries.
- `CacheTTL(ttl_seconds)`: Expire entries after a certain time.

# Example
```julia
client = Client(token; user_strategy=CacheLRU(1000))
```
"""
abstract type CacheStrategy end

"""Keep entries indefinitely in memory."""
struct CacheForever <: CacheStrategy end

"""Do not cache entries (REST fallback on every access)."""
struct CacheNever <: CacheStrategy end

"""Keep only the `maxsize` most recently used entries."""
struct CacheLRU <: CacheStrategy
    maxsize::Int
end

"""Expire entries after `ttl_seconds` have passed."""
struct CacheTTL <: CacheStrategy
    ttl_seconds::Float64
end

"""
    Store{T}

Use this to cache Discord objects like guilds, channels, and users with configurable eviction policies.

A cache store for a specific resource type, keyed by Snowflake.
Uses LRUCache.LRU for O(1) LRU eviction, plain Dict for other strategies.

# Example
```julia
store = Store{User}(CacheLRU(1000))
store[id] = user
user = store[id]
```
"""
mutable struct Store{T}
    strategy::CacheStrategy
    data::Union{Dict{Snowflake, T}, LRU{Snowflake, T}}
    timestamps::Dict{Snowflake, Float64}  # for TTL only
end

function Store{T}(strategy::CacheStrategy=CacheForever()) where T
    data = if strategy isa CacheLRU
        LRU{Snowflake, T}(maxsize=strategy.maxsize)
    else
        Dict{Snowflake, T}()
    end
    Store{T}(strategy, data, Dict{Snowflake, Float64}())
end

"""
    ShardedStore{T}

A thread-safe version of [`Store`](@ref) that uses multiple shards (buckets) to reduce
lock contention. Ideal for global resources accessed by many shards/tasks.
"""
struct ShardedStore{T}
    shards::Vector{Store{T}}
    locks::Vector{ReentrantLock}
    num_shards::Int
end

function ShardedStore{T}(strategy::CacheStrategy=CacheForever(), num_shards::Int=16) where T
    shards = [Store{T}(strategy) for _ in 1:num_shards]
    locks = [ReentrantLock() for _ in 1:num_shards]
    ShardedStore{T}(shards, locks, num_shards)
end

function _get_shard(store::ShardedStore, id::Snowflake)
    idx = (id.value % store.num_shards) + 1
    return store.shards[idx], store.locks[idx]
end

function Base.get(store::ShardedStore{T}, id::Snowflake, default=nothing) where T
    s, l = _get_shard(store, id)
    lock(l) do
        return get(s, id, default)
    end
end

function Base.getindex(store::ShardedStore{T}, id::Snowflake) where T
    val = get(store, id)
    isnothing(val) && throw(KeyError(id))
    return val
end

function Base.setindex!(store::ShardedStore{T}, value::T, id::Snowflake) where T
    s, l = _get_shard(store, id)
    lock(l) do
        s.data[id] = value
        if s.strategy isa CacheTTL
            s.timestamps[id] = time()
        end
    end
    return value
end

function Base.delete!(store::ShardedStore, id::Snowflake)
    s, l = _get_shard(store, id)
    lock(l) do
        delete!(s, id)
    end
end

function Base.length(store::ShardedStore)
    total = 0
    for i in 1:store.num_shards
        lock(store.locks[i]) do
            total += length(store.shards[i])
        end
    end
    return total
end

Base.haskey(store::ShardedStore, id::Snowflake) = let (s, l) = _get_shard(store, id); lock(() -> haskey(s, id), l) end
Base.empty!(store::ShardedStore) = begin for (s, l) in zip(store.shards, store.locks) lock(() -> empty!(s), l) end; store end


function Base.get(store::Store{T}, id::Snowflake, default=nothing) where T
    store.strategy isa CacheNever && return default

    if haskey(store.data, id)
        # Check TTL
        if store.strategy isa CacheTTL
            if time() - get(store.timestamps, id, 0.0) > store.strategy.ttl_seconds
                delete!(store, id)
                return default
            end
        end

        return store.data[id]
    end
    return default
end

function Base.getindex(store::Store{T}, id::Snowflake) where T
    val = get(store, id)
    isnothing(val) && throw(KeyError(id))
    return val
end

function Base.setindex!(store::Store{T}, value::T, id::Snowflake) where T
    store.strategy isa CacheNever && return value

    store.data[id] = value

    if store.strategy isa CacheTTL
        store.timestamps[id] = time()
    end

    return value
end

function Base.delete!(store::Store, id::Snowflake)
    delete!(store.data, id)
    delete!(store.timestamps, id)
end

Base.haskey(store::Store, id::Snowflake) = haskey(store.data, id)
Base.empty!(store::Store) = (empty!(store.data); empty!(store.timestamps); store)
Base.values(store::Store) = values(store.data)
Base.length(store::Store) = length(store.data)
Base.keys(store::Store) = keys(store.data)

"""
    State

Use this to access and manage cached Discord objects for your bot.

Holds all cached Discord state. Global resources (guilds, channels, users) use
a [`ShardedStore`](@ref) for thread-safe concurrent access.

# Example
```julia
client.state.guilds[id]
client.state.me.username
```
"""
mutable struct State
    guilds::ShardedStore{Guild}
    channels::ShardedStore{DiscordChannel}
    users::ShardedStore{User}
    members::Dict{Snowflake, Store{Member}}  # guild_id → Store{Member}
    roles::Dict{Snowflake, Store{Role}}      # guild_id → Store{Role}
    emojis::Dict{Snowflake, Store{Emoji}}    # guild_id → Store{Emoji}
    presences::ShardedStore{Presence}
    voice_states::Dict{Snowflake, Dict{Snowflake, VoiceState}}  # guild_id → user_id → VoiceState
    me::Nullable{User}
    _lock::ReentrantLock # for the dicts themselves
end

function State(;
    guild_strategy::CacheStrategy=CacheForever(),
    channel_strategy::CacheStrategy=CacheForever(),
    user_strategy::CacheStrategy=CacheLRU(10_000),
    member_strategy::CacheStrategy=CacheLRU(10_000),
    presence_strategy::CacheStrategy=CacheNever(),
)
    State(
        ShardedStore{Guild}(guild_strategy),
        ShardedStore{DiscordChannel}(channel_strategy),
        ShardedStore{User}(user_strategy),
        Dict{Snowflake, Store{Member}}(),
        Dict{Snowflake, Store{Role}}(),
        Dict{Snowflake, Store{Emoji}}(),
        ShardedStore{Presence}(presence_strategy),
        Dict{Snowflake, Dict{Snowflake, VoiceState}}(),
        nothing,
        ReentrantLock()
    )
end

# --- State update methods ---

"""
    update_state!(state::State, event::AbstractEvent)

Update the internal cache based on the incoming gateway event.
Accord.jl handles this automatically for you.
"""
function update_state! end

function update_state!(state::State, event::ReadyEvent)
    state.me = event.user
    for ug in event.guilds
        state.guilds[ug.id] = Guild(id=ug.id, name="", icon=nothing, splash=nothing, discovery_splash=nothing, unavailable=true)
    end
end

function update_state!(state::State, event::GuildCreate)
    g = event.guild
    state.guilds[g.id] = g

    # Cache channels
    channels = g.channels
    if !ismissing(channels)
        for ch in channels
            state.channels[ch.id] = ch
        end
    end

    # Cache threads
    threads = g.threads
    if !ismissing(threads)
        for th in threads
            state.channels[th.id] = th
        end
    end

    # Cache roles
    roles = g.roles
    if !ismissing(roles)
        store = lock(state._lock) do
            get!(state.roles, g.id, Store{Role}())
        end
        for role in roles
            store[role.id] = role
        end
    end

    # Cache emojis
    emojis = g.emojis
    if !ismissing(emojis)
        store = lock(state._lock) do
            get!(state.emojis, g.id, Store{Emoji}())
        end
        for emoji in emojis
            eid = emoji.id
            !isnothing(eid) && (store[eid] = emoji)
        end
    end

    # Cache members
    members = g.members
    if !ismissing(members)
        store = lock(state._lock) do
            get!(state.members, g.id, Store{Member}())
        end
        for member in members
            user = member.user
            if !ismissing(user)
                state.users[user.id] = user
                store[user.id] = member
            end
        end
    end
end

function update_state!(state::State, event::GuildUpdate)
    state.guilds[event.guild.id] = event.guild
end

function update_state!(state::State, event::GuildDelete)
    lock(state._lock) do
        delete!(state.guilds, event.guild.id)
        delete!(state.members, event.guild.id)
        delete!(state.roles, event.guild.id)
        delete!(state.emojis, event.guild.id)
        delete!(state.voice_states, event.guild.id)
    end
end

function update_state!(state::State, event::ChannelCreate)
    state.channels[event.channel.id] = event.channel
end
function update_state!(state::State, event::ChannelUpdate)
    state.channels[event.channel.id] = event.channel
end
function update_state!(state::State, event::ChannelDelete)
    delete!(state.channels, event.channel.id)
end

function update_state!(state::State, event::ThreadCreate)
    state.channels[event.channel.id] = event.channel
end
function update_state!(state::State, event::ThreadUpdate)
    state.channels[event.channel.id] = event.channel
end
function update_state!(state::State, event::ThreadDelete)
    delete!(state.channels, event.id)
end

function update_state!(state::State, event::GuildMemberAdd)
    store = lock(state._lock) do
        get!(state.members, event.guild_id, Store{Member}())
    end
    user = event.member.user
    if !ismissing(user)
        state.users[user.id] = user
        store[user.id] = event.member
    end
end

function update_state!(state::State, event::GuildMemberRemove)
    store = lock(state._lock) do
        get(state.members, event.guild_id, nothing)
    end
    !isnothing(store) && delete!(store, event.user.id)
end

function update_state!(state::State, event::GuildMemberUpdate)
    store = lock(state._lock) do
        get!(state.members, event.guild_id, Store{Member}())
    end
    existing = get(store, event.user.id)
    if !isnothing(existing)
        existing.roles = event.roles
        !ismissing(event.nick) && (existing.nick = event.nick)
        !ismissing(event.avatar) && (existing.avatar = event.avatar)
        !ismissing(event.pending) && (existing.pending = event.pending)
        !ismissing(event.communication_disabled_until) && (existing.communication_disabled_until = event.communication_disabled_until)
    end
    state.users[event.user.id] = event.user
end

function update_state!(state::State, event::GuildRoleCreate)
    store = lock(state._lock) do
        get!(state.roles, event.guild_id, Store{Role}())
    end
    store[event.role.id] = event.role
end
function update_state!(state::State, event::GuildRoleUpdate)
    store = lock(state._lock) do
        get!(state.roles, event.guild_id, Store{Role}())
    end
    store[event.role.id] = event.role
end
function update_state!(state::State, event::GuildRoleDelete)
    store = lock(state._lock) do
        get(state.roles, event.guild_id, nothing)
    end
    !isnothing(store) && delete!(store, event.role_id)
end

function update_state!(state::State, event::GuildEmojisUpdate)
    store = lock(state._lock) do
        get!(state.emojis, event.guild_id, Store{Emoji}())
    end
    # Replace all emojis for this guild
    empty!(store)
    for emoji in event.emojis
        eid = emoji.id
        !isnothing(eid) && (store[eid] = emoji)
    end
end

function update_state!(state::State, event::UserUpdate)
    state.me = event.user
    state.users[event.user.id] = event.user
end

function update_state!(state::State, event::VoiceStateUpdateEvent)
    vs = event.state
    gid = vs.guild_id
    if !ismissing(gid)
        guild_vs = lock(state._lock) do
            get!(state.voice_states, gid, Dict{Snowflake, VoiceState}())
        end
        if isnothing(vs.channel_id)
            # User left voice
            delete!(guild_vs, vs.user_id)
        else
            guild_vs[vs.user_id] = vs
        end
    end
end

function update_state!(state::State, event::MessageCreate)
    msg = event.message
    author = msg.author
    if !ismissing(author)
        state.users[author.id] = author
    end
end

# Fallback — no state update needed
function update_state!(state::State, event::AbstractEvent)
    # No-op for events that don't affect cached state
end
