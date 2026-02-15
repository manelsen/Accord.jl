# State management and caching

using LRUCache

"""Cache strategy for a resource type."""
abstract type CacheStrategy end

struct CacheForever <: CacheStrategy end
struct CacheNever <: CacheStrategy end

struct CacheLRU <: CacheStrategy
    maxsize::Int
end

struct CacheTTL <: CacheStrategy
    ttl_seconds::Float64
end

"""
    Store{T}

A cache store for a specific resource type, keyed by Snowflake.
Uses LRUCache.LRU for O(1) LRU eviction, plain Dict for other strategies.
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

Holds all cached Discord state.
"""
mutable struct State
    guilds::Store{Guild}
    channels::Store{DiscordChannel}
    users::Store{User}
    members::Dict{Snowflake, Store{Member}}  # guild_id → Store{Member}
    roles::Dict{Snowflake, Store{Role}}      # guild_id → Store{Role}
    emojis::Dict{Snowflake, Store{Emoji}}    # guild_id → Store{Emoji}
    presences::Store{Presence}
    voice_states::Dict{Snowflake, Dict{Snowflake, VoiceState}}  # guild_id → user_id → VoiceState
    me::Nullable{User}
end

function State(;
    guild_strategy::CacheStrategy=CacheForever(),
    channel_strategy::CacheStrategy=CacheForever(),
    user_strategy::CacheStrategy=CacheLRU(10_000),
    member_strategy::CacheStrategy=CacheLRU(10_000),
    presence_strategy::CacheStrategy=CacheNever(),
)
    State(
        Store{Guild}(guild_strategy),
        Store{DiscordChannel}(channel_strategy),
        Store{User}(user_strategy),
        Dict{Snowflake, Store{Member}}(),
        Dict{Snowflake, Store{Role}}(),
        Dict{Snowflake, Store{Emoji}}(),
        Store{Presence}(presence_strategy),
        Dict{Snowflake, Dict{Snowflake, VoiceState}}(),
        nothing,
    )
end

# --- State update methods ---

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
        store = get!(state.roles, g.id, Store{Role}())
        for role in roles
            store[role.id] = role
        end
    end

    # Cache emojis
    emojis = g.emojis
    if !ismissing(emojis)
        store = get!(state.emojis, g.id, Store{Emoji}())
        for emoji in emojis
            eid = emoji.id
            !isnothing(eid) && (store[eid] = emoji)
        end
    end

    # Cache members
    members = g.members
    if !ismissing(members)
        store = get!(state.members, g.id, Store{Member}())
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
    delete!(state.guilds, event.guild.id)
    delete!(state.members, event.guild.id)
    delete!(state.roles, event.guild.id)
    delete!(state.emojis, event.guild.id)
    delete!(state.voice_states, event.guild.id)
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
    store = get!(state.members, event.guild_id, Store{Member}())
    user = event.member.user
    if !ismissing(user)
        state.users[user.id] = user
        store[user.id] = event.member
    end
end

function update_state!(state::State, event::GuildMemberRemove)
    store = get(state.members, event.guild_id, nothing)
    !isnothing(store) && delete!(store, event.user.id)
end

function update_state!(state::State, event::GuildMemberUpdate)
    store = get!(state.members, event.guild_id, Store{Member}())
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
    store = get!(state.roles, event.guild_id, Store{Role}())
    store[event.role.id] = event.role
end
function update_state!(state::State, event::GuildRoleUpdate)
    store = get!(state.roles, event.guild_id, Store{Role}())
    store[event.role.id] = event.role
end
function update_state!(state::State, event::GuildRoleDelete)
    store = get(state.roles, event.guild_id, nothing)
    !isnothing(store) && delete!(store, event.role_id)
end

function update_state!(state::State, event::GuildEmojisUpdate)
    store = get!(state.emojis, event.guild_id, Store{Emoji}())
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
        guild_vs = get!(state.voice_states, gid, Dict{Snowflake, VoiceState}())
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
