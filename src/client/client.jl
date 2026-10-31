# Client — orchestrates Gateway, REST, and Cache

"""
    EventWaiter

Use this internal struct to wait for specific gateway events matching a predicate.

Internal struct for [`wait_for`](@ref). Holds the event type filter, predicate,
and a `Channel` that receives the matching event.
"""
struct EventWaiter
    event_type::Type{<:AbstractEvent}
    check::Function
    channel::Channel
end

"""
    Client

Use this as the main entry point for your Discord bot to manage connections, events, and API calls.

The main Discord client that orchestrates gateway connections, REST API calls, and state caching.

!!! compat "Accord 0.1.0"
    `Client` and the full event-driven API are available since Accord 0.1.0.

# Constructor
    Client(token::String; intents=IntentAllNonPrivileged, num_shards=1, state=nothing, state_options...)

    - `state_data` — custom user state, accessible from handlers via `ctx.state`.
    - `max_concurrency` — how many shards may identify every 5 seconds, from the
      `session_start_limit` of `GET /gateway/bot`. Left unset, `start` fetches it when
      there is more than one shard. Large bots (150k+ guilds) have more than 1.
    - `handler_concurrency` — controls the number of concurrently executing handlers so slow workflows
      (e.g. `wait_for`) can't starve the main loop. Increase the value only if you know your handlers
      are fast and you need extra throughput; keeping the default `16` is enough for most bots.
    Handlers run on Julia's default threadpool, in parallel when Julia has more than
    one thread: state shared between handlers must be protected (`ReentrantLock`,
    `Threads.Atomic`). Accord's I/O loops run on the `:interactive` threadpool when
    one exists (`julia -t auto,1`), so handlers can't delay heartbeats.
    - `handler_backlog` — maximum number of handler tasks alive at once (running plus queued,
      default `64 * handler_concurrency`). When it is reached the event loop waits, which applies
      back-pressure to the gateway instead of growing memory without bound.

# Example
```julia
# Inject custom state for database, config, etc.
my_state = (db=my_database, config=my_config)
client = Client("Bot YOUR_TOKEN_HERE";
    intents=IntentGuilds | IntentGuildMessages,
    state=my_state
)

on(client, MessageCreate) do c, event
    event.message.content == "ping" && create_message(c, event.message.channel_id; content="pong")
end
start(client)
```
"""
mutable struct Client{S} <: AbstractClient
    token::String
    application_id::Nullable{Snowflake}
    intents::UInt32
    state::State
    state_data::S
    event_handler::EventHandler
    command_tree::CommandTree
    ratelimiter::RateLimiter
    shards::Vector{ShardInfo}
    num_shards::Int
    ready::Base.Event
    running::Bool
    _event_loop_task::Nullable{Task}
    _supervisor_task::Nullable{Task}
    _waiters::Vector{EventWaiter}
    _waiters_lock::ReentrantLock
    _handler_tasks::Set{Task}
    _handler_tasks_lock::ReentrantLock
    _handler_sem::Base.Semaphore
    _handler_backlog::Base.Semaphore
end

function Client(token::String;
    intents::Union{Intents, UInt32, Integer} = IntentAllNonPrivileged,
    num_shards::Int = 1,
    max_concurrency::Union{Int, Nothing} = nothing,
    state = nothing,
    safety_buffer::Float64 = 0.1,
    guild_strategy::CacheStrategy = CacheForever(),
    channel_strategy::CacheStrategy = CacheForever(),
    user_strategy::CacheStrategy = CacheLRU(10_000),
    member_strategy::CacheStrategy = CacheLRU(10_000),
    presence_strategy::CacheStrategy = CacheNever(),
    handler_concurrency::Int = 16,
    handler_backlog::Int = 64 * handler_concurrency,
)
    handler_concurrency < 1 && throw(ArgumentError("handler_concurrency must be >= 1"))
    handler_backlog < handler_concurrency &&
        throw(ArgumentError("handler_backlog must be >= handler_concurrency"))

    # Ensure token has Bot prefix
    actual_token = startswith(token, "Bot ") ? token : "Bot $token"

    intents_val = intents isa Intents ? UInt32(intents.value) : UInt32(intents)

    cache_state = State(;
        guild_strategy, channel_strategy, user_strategy,
        member_strategy, presence_strategy,
    )

    events_channel = Channel{AbstractEvent}(1024)

    identify_limiter = IdentifyLimiter(max_concurrency)
    shards = [ShardInfo(i, num_shards, events_channel, identify_limiter) for i in 0:(num_shards-1)]

    tree = CommandTree()

    client = Client{typeof(state)}(
        actual_token,
        nothing,
        intents_val,
        cache_state,
        state,
        EventHandler(),
        tree,
        RateLimiter(; safety_buffer=safety_buffer),
        shards,
        num_shards,
        Base.Event(),
        false,
        nothing,
        nothing,
        EventWaiter[],
        ReentrantLock(),
        Set{Task}(),
        ReentrantLock(),
        Base.Semaphore(handler_concurrency),
        Base.Semaphore(handler_backlog),
    )

    # Register interaction dispatcher
    on(client, InteractionCreate) do c, event
        dispatch_interaction!(c.command_tree, c, event.interaction)
    end

    return client
end

"""
    on(handler, client, EventType)

Use this to register callbacks that respond to Discord gateway events like messages or reactions.

Register an event handler. The handler receives (client, event).

# Example
```julia
on(client, MessageCreate) do c, event
    println("Got message: ", event.message.content)
end
```
"""
function on(handler::Function, client::Client, ::Type{T}) where T <: AbstractEvent
    register_handler!(client.event_handler, T, handler)
end

"""
    on_error(handler, client)

Use this to customize how your bot handles errors that occur during event processing.

Set a custom error handler. Receives (client, event, error).

!!! warning
    If your custom error handler itself throws, the error will be silently lost.
    Always wrap your error handler body in a `try-catch`.

# Example
```julia
on_error(client) do c, event, err
    @error "Unhandled error" event_type=typeof(event) exception=err
end
```
"""
function on_error(handler::Function, client::Client)
    client.event_handler.error_handler = handler
end

"""
    start(client::Client; blocking=true)

Use this to connect your bot to Discord and begin processing events.

Connect to Discord and start processing events.
If `blocking=true` (default), this blocks until the client is stopped.

!!! note
    In blocking mode (the default), `start` will not return until [`stop`](@ref) is called
    or the process receives an interrupt (Ctrl-C). Use `blocking=false` for REPL or
    script workflows where you need to run code after the bot is online.

# Example
```julia
# Blocking (default) — blocks until Ctrl-C or stop()
start(client)

# Non-blocking — useful in scripts or REPL
start(client; blocking=false)
wait_until_ready(client)
println("Bot is online!")
```
"""
function start(client::Client; blocking::Bool=true)
    client.running = true

    # Start rate limiter
    start_ratelimiter!(client.ratelimiter)

    # Start the shards in order. Their identify limiter lets `max_concurrency`
    # of them (one per bucket) identify every 5 seconds; wait for each group's
    # turn so later shards don't take an earlier bucket's slot.
    limiter = first(client.shards).identify_limiter
    _configure_identify!(limiter, client)
    for (i, shard) in enumerate(client.shards)
        i > 1 && (i - 1) % limiter.max_concurrency == 0 && sleep(IDENTIFY_INTERVAL)
        start_shard(shard, client.token, client.intents)
    end

    # Start event processing loop
    client._event_loop_task = errormonitor(@_spawn_io _event_loop(client))

    # Start supervisor task to monitor and restart shards
    client._supervisor_task = errormonitor(@_spawn_io _supervisor_loop(client))

    if blocking
        # Ready means every shard has received READY
        foreach(s -> wait(s.ready), client.shards)
        notify(client.ready)

        # Block until stopped
        try
            while client.running
                sleep(1.0)
            end
        catch e
            e isa InterruptException || rethrow()
        end

        stop(client)
    else
        # Non-blocking: wait for ready in background
        errormonitor(@_spawn_io begin
            foreach(s -> wait(s.ready), client.shards)
            notify(client.ready)
        end)
    end
end

# With several shards and no `max_concurrency` given, ask Discord for it.
function _configure_identify!(limiter::IdentifyLimiter, client::Client)
    (limiter.configured || client.num_shards == 1) && return
    try
        mc = Int(get_gateway_bot(client.token).session_start_limit["max_concurrency"])
        set_max_concurrency!(limiter, mc)
    catch e
        @warn "Could not read max_concurrency from /gateway/bot; identifying one shard every 5 seconds" exception=e
        set_max_concurrency!(limiter, 1)
    end
end

"""
    stop(client::Client)

Use this to gracefully shut down your bot and disconnect from Discord.

Disconnect from Discord and stop processing events.

# Example
```julia
@slash_command client "shutdown" "Shut down the bot" function(ctx)
    respond(ctx; content="Shutting down...")
    stop(ctx.client)
end
```
"""
function stop(client::Client)
    client.running = false
    _cancel_waiters!(client)

    # Stop shards
    for shard in client.shards
        stop_shard(shard)
    end

    # Stop rate limiter
    stop_ratelimiter!(client.ratelimiter)

    @info "Client stopped"
end

function _cancel_waiters!(client::Client)
    lock(client._waiters_lock) do
        for waiter in client._waiters
            isopen(waiter.channel) && close(waiter.channel)
        end
        empty!(client._waiters)
    end
end

"""
    wait_until_ready(client::Client)

Use this to pause execution until your bot is fully connected and ready.

Block until the client receives the READY event.
"""
function wait_until_ready(client::Client)
    wait(client.ready)
end

"""
    wait_for(check, client, EventType; timeout=30.0)

Use this to pause execution until a specific event occurs, useful for interactive commands or conversations.

Wait for a specific gateway event that matches a predicate.
Uses Julia's `Channel` and `Timer` for an efficient, non-blocking wait
that suspends only the current `Task`, not the entire bot.

Returns the matching event, or `nothing` on timeout.

# Arguments
- `check::Function` — predicate `(event) -> Bool`. Only matching events are captured.
- `client::Client` — the bot client. See [`Client`](@ref).
- `EventType` — the event type to listen for (e.g., [`MessageCreate`](@ref)).
- `timeout` — seconds to wait before returning `nothing` (default: 30).

# Example
```julia
@slash_command client "quiz" "Start a quiz" function(ctx)
    respond(ctx; content="What color is the sky?")

    event = wait_for(client, MessageCreate; timeout=30) do evt
        evt.message.author.id == ctx.user.id &&
        evt.message.channel_id == ctx.channel_id
    end

    if isnothing(event)
        followup(ctx; content="⏰ Time's up!")
    elseif event.message.content == "blue"
        followup(ctx; content="✅ Correct!")
    else
        followup(ctx; content="❌ Wrong!")
    end
end
```
"""
function wait_for(check::Function, client::Client, ::Type{T}; timeout::Real=30.0) where T <: AbstractEvent
    ch = Channel{T}(1)
    waiter = EventWaiter(T, check, ch)

    lock(client._waiters_lock) do
        push!(client._waiters, waiter)
    end

    # Set up timeout to close the channel and clean up
    timer = Timer(timeout) do _
        lock(client._waiters_lock) do
            filter!(w -> w !== waiter, client._waiters)
        end
        isopen(ch) && close(ch)
    end

    try
        result = take!(ch)
        close(timer)
        return result
    catch e
        # Channel was closed (timeout) or interrupted
        e isa InvalidStateException && return nothing
        rethrow()
    finally
        lock(client._waiters_lock) do
            filter!(w -> w !== waiter, client._waiters)
        end
    end
end

"""
    _notify_waiters!(client::Client, event::AbstractEvent)

Use this internal function to match incoming events against registered waiters for wait_for.

Check registered waiters against an incoming event. If a waiter's predicate
matches, deliver the event through its channel. Called from `_event_loop`.
"""
function _notify_waiters!(client::Client, event::AbstractEvent)
    lock(client._waiters_lock) do
        matched = Int[]
        for (i, waiter) in enumerate(client._waiters)
            if event isa waiter.event_type
                try
                    if Base.invokelatest(waiter.check, event)
                        isopen(waiter.channel) && put!(waiter.channel, event)
                        push!(matched, i)
                    end
                catch e
                    @debug "Waiter check error" exception=e
                end
            end
        end
        deleteat!(client._waiters, sort!(matched))
    end
end

function _untrack_handler_task!(client::Client, task::Task)
    lock(client._handler_tasks_lock) do
        delete!(client._handler_tasks, task)
    end
    nothing
end

# Run the handlers for `event` in a new task on the default threadpool, so
# handlers run in parallel when Julia has several threads. Two limits apply:
# - `_handler_sem` (`handler_concurrency`) caps how many handlers *run* at once.
#   It is acquired inside the task, so a handler blocked in `wait_for` never
#   stops the event loop from delivering the event it is waiting for.
# - `_handler_backlog` (`handler_backlog`) caps how many handler tasks *exist*
#   (running + queued). It is acquired here, before the task is created, so a
#   burst of events applies back-pressure to the gateway instead of spawning an
#   unbounded number of tasks.
function _dispatch_event_async!(client::Client, event::AbstractEvent)
    Base.acquire(client._handler_backlog)
    # Spawn while holding the tracking lock: the task untracks itself under the
    # same lock, so it can never be untracked before it has been tracked.
    lock(client._handler_tasks_lock) do
        task = Threads.@spawn :default begin
            try
                Base.acquire(client._handler_sem)
                try
                    dispatch_event!(client.event_handler, client, event)
                catch e
                    @error "Unhandled async event dispatch error" event_type=typeof(event) exception=e
                finally
                    Base.release(client._handler_sem)
                end
            finally
                _untrack_handler_task!(client, current_task())
                Base.release(client._handler_backlog)
            end
        end
        push!(client._handler_tasks, task)
    end
    nothing
end

function _event_loop(client::Client)
    # All shards share the same events channel
    events = client.shards[1].events

    while client.running
        local event
        try
            event = take!(events)
        catch e
            e isa InvalidStateException && break
            @error "Error taking event from channel" exception=e
            continue
        end

        # Update state cache
        try
            update_state!(client.state, event)
        catch e
            @error "Error updating state" event_type=typeof(event) exception=e
        end

        # Capture application_id from READY
        if event isa ReadyEvent && !isnothing(event.application)
            try
                if event.application isa Dict && haskey(event.application, "id")
                    client.application_id = Snowflake(event.application["id"])
                elseif hasproperty(event.application, :id)
                    client.application_id = Snowflake(event.application.id)
                end
                @debug "Captured application_id" application_id=client.application_id
            catch e
                @error "Failed to extract application_id from READY" application=event.application exception=e
            end
        end

        event isa RateLimited && _warn_rate_limited(event)

        # Notify wait_for waiters first: if the handler backlog is full, the
        # dispatch below blocks, and those handlers may be the ones waiting.
        _notify_waiters!(client, event)

        # Dispatch to handlers concurrently so slow handlers (e.g. wait_for)
        # do not block the main event ingestion loop.
        _dispatch_event_async!(client, event)
    end
end

function _supervisor_loop(client::Client)
    @debug "Supervisor task started"
    
    while client.running
        # Check every 5 seconds
        sleep(5.0)
        
        for shard in client.shards
            # If the task is finished but we didn't stop the bot, restart it
            task = shard.task
            if !isnothing(task) && istaskdone(task) && client.running
                # Intentional stops and fatal close codes (bad token, disallowed
                # intents) must not be retried; anything else is a crash.
                if !shard.session.stopped && !shard.session.fatal
                    @error "Shard $(shard.id) died unexpectedly! Restarting..."
                    start_shard(shard, client.token, client.intents)
                end
            end
        end
    end
    
    @debug "Supervisor task stopped"
end

"""
    create_message(client::Client, channel_id::Snowflake; kwargs...) -> Message

Use this to send messages to any channel your bot has access to.

Send a message to a channel.

# Arguments
- `content::String`: Message text content.
- `embeds::Vector`: Vector of embed dictionaries or objects.
- `components::Vector`: Vector of action rows/components.
- `files`: Optional files to upload.
- `tts::Bool`: Whether to send as a text-to-speech message.
- `message_reference`: Optional dictionary to reply to a specific message.
- `poll`: Optional poll object (see `create_poll` for a shortcut).
- `flags`: Optional [`MessageFlags`](@ref) or integer (e.g. `MsgFlagSuppressEmbeds`).
- `allowed_mentions`: Optional allowed-mentions dictionary.

# Example
```julia
create_message(client, channel_id;
    content="Check this out!",
    embeds=[embed(title="Hello", description="An embed", color=0x5865F2)],
    components=[action_row([button(label="Click", custom_id="btn")])]
)
```
"""
function create_message(client::Client, channel_id::Snowflake; content::String="", embeds::Vector=[], components::Vector=[], files=nothing, tts::Bool=false, message_reference=nothing, poll=nothing, flags=nothing, allowed_mentions=nothing)
    body = _message_body(; content, embeds, components, tts, message_reference, poll, flags, allowed_mentions)
    create_message(client.ratelimiter, channel_id; token=client.token, body, files)
end

"""
    reply(client::Client, message::Message; kwargs...) -> Message

Use this to respond to a specific message, creating a threaded conversation.

Reply to a message. Automatically sets the channel ID and the `message_reference`.

# Example
```julia
on(client, MessageCreate) do c, event
    reply(c, event.message; content="Got it!")
end
```
"""
function reply(client::Client, message::Message; kwargs...)
    ref = Dict{String, Any}("message_id" => string(message.id))
    create_message(client, message.channel_id; message_reference=ref, kwargs...)
end

"""
    forward_message(client::Client, channel_id::Snowflake, message::Message) -> Message

Forward `message` to `channel_id`. The new message carries a snapshot of the
original in `message_snapshots`; Discord does not allow content alongside it.
The bot must be able to read the original message.

# Example
```julia
on(client, MessageCreate) do c, event
    startswith(something(event.message.content, ""), "!archive") &&
        forward_message(c, ARCHIVE_CHANNEL, event.message)
end
```
"""
function forward_message(client::Client, channel_id::Snowflake, message::Message)
    ref = Dict{String, Any}("type" => MessageReferenceTypes.FORWARD,
                            "message_id" => string(message.id),
                            "channel_id" => string(message.channel_id))
    ismissing(message.guild_id) || (ref["guild_id"] = string(message.guild_id))
    create_message(client, channel_id; message_reference=ref)
end

"""
    edit_message(client::Client, channel_id::Snowflake, message_id::Snowflake; kwargs...) -> Message

Use this to modify a message your bot previously sent.

Edit an existing message. `kwargs` correspond to the Discord API fields (content, embeds, etc.).

# Example
```julia
edit_message(client, channel_id, message_id; content="Updated content!")
```
"""
function edit_message(client::Client, channel_id::Snowflake, message_id::Snowflake; files=nothing, kwargs...)
    body = _message_body(; omit_empty=false, kwargs...)
    edit_message(client.ratelimiter, channel_id, message_id; token=client.token, body, files)
end

"""
    delete_message(client::Client, channel_id::Snowflake, message_id::Snowflake; reason=nothing)

Use this to remove a message from a channel.

Delete a message.

# Example
```julia
delete_message(client, channel_id, message_id; reason="Spam")
```
"""
function delete_message(client::Client, channel_id::Snowflake, message_id::Snowflake; reason=nothing)
    delete_message(client.ratelimiter, channel_id, message_id; token=client.token, reason)
end

"""
    create_reaction(client::Client, channel_id::Snowflake, message_id::Snowflake, emoji::String)

Use this to add an emoji reaction to a message on behalf of your bot.

Create a reaction on a message. The `emoji` parameter should be a URL-encoded string: `"👍"` or `"custom_emoji:123456"`.

# Example
```julia
on(client, MessageCreate) do c, event
    if contains(event.message.content, "hello")
        create_reaction(c, event.message.channel_id, event.message.id, "👋")
    end
end
```
"""
function create_reaction(client::Client, channel_id::Snowflake, message_id::Snowflake, emoji::String)
    create_reaction(client.ratelimiter, channel_id, message_id, emoji; token=client.token)
end

"""
    get_channel(client::Client, channel_id::Snowflake) -> DiscordChannel

Use this to retrieve channel information, with automatic caching for performance.

Get a channel by ID. Checks the local state cache first.

# Example
```julia
channel = get_channel(client, channel_id)
println("Channel name: ", channel.name)
```
"""
function get_channel(client::Client, channel_id::Snowflake)
    # Check cache first
    cached = get(client.state.channels, channel_id)
    !isnothing(cached) && return cached

    get_channel(client.ratelimiter, channel_id; token=client.token)
end

"""
    get_guild(client::Client, guild_id::Snowflake) -> Guild

Use this to retrieve server information, with automatic caching for performance.

Get a guild by ID. Checks the local state cache first.

# Example
```julia
guild = get_guild(client, guild_id)
println("Server name: ", guild.name)
```
"""
function get_guild(client::Client, guild_id::Snowflake)
    cached = get(client.state.guilds, guild_id)
    !isnothing(cached) && return cached

    get_guild(client.ratelimiter, guild_id; token=client.token)
end

"""
    get_user(client::Client, user_id::Snowflake) -> User

Use this to retrieve user information, with automatic caching for performance.

Get a user by ID. Checks the local state cache first.

# Example
```julia
user = get_user(client, user_id)
println("User tag: ", user.username, "#", user.discriminator)
```
"""
function get_user(client::Client, user_id::Snowflake)
    cached = get(client.state.users, user_id)
    !isnothing(cached) && return cached

    get_user(client.ratelimiter, user_id; token=client.token)
end

"""
    update_voice_state(client, guild_id; channel_id=nothing, self_mute=false, self_deaf=false)

Use this to make your bot join, leave, or move between voice channels.

Send a gateway command to update voice state (join/leave/move voice channels).

# Example
```julia
# Join a voice channel (unmuted)
update_voice_state(client, guild_id; channel_id=voice_channel_id)

# Self-mute
update_voice_state(client, guild_id; channel_id=voice_channel_id, self_mute=true)

# Leave voice channel
update_voice_state(client, guild_id; channel_id=nothing)
```
"""
function update_voice_state(client::Client, guild_id::Snowflake; channel_id=nothing, self_mute::Bool=false, self_deaf::Bool=false)
    shard_id = shard_for_guild(guild_id, client.num_shards)
    shard = client.shards[shard_id + 1]
    cmd = GatewayCommand(GatewayOpcodes.VOICE_STATE_UPDATE, Dict{String, Any}(
        "guild_id" => string(guild_id),
        "channel_id" => isnothing(channel_id) ? nothing : string(channel_id),
        "self_mute" => self_mute,
        "self_deaf" => self_deaf,
    ))
    send_to_shard(shard, cmd)
end

"""
    update_presence(client; status="online", activities=[], afk=false, since=nothing)

Use this to change your bot's online status and activity display.

Send a gateway command to update the bot's presence/status.

# Example
```julia
# Set "Playing Accord.jl" status
update_presence(client; activities=[activity("Accord.jl", ActivityTypes.GAME)])

# Set "Do Not Disturb" with custom status
update_presence(client; status="dnd", activities=[activity("maintenance", ActivityTypes.WATCHING)])
```
"""
function update_presence(client::Client; status::String="online", activities::Vector=[], afk::Bool=false, since=nothing)
    for shard in client.shards
        cmd = GatewayCommand(GatewayOpcodes.PRESENCE_UPDATE, Dict{String, Any}(
            "since" => since,
            "activities" => activities,
            "status" => status,
            "afk" => afk,
        ))
        send_to_shard(shard, cmd)
    end
end

# A rate-limited gateway request is dropped by Discord; say so, or the caller
# waits forever for a reply (e.g. member chunks) that will never come.
function _warn_rate_limited(e::RateLimited)
    meta = e.meta
    guild_id = (ismissing(meta) || isnothing(meta)) ? nothing : get(meta, :guild_id, get(meta, "guild_id", nothing))
    what = e.opcode == GatewayOpcodes.REQUEST_GUILD_MEMBERS ?
        "request_guild_members (all members: at most once per guild every 30 s)" : "gateway opcode $(e.opcode)"
    @warn "Discord rate-limited $what; the request was dropped" guild_id retry_after=e.retry_after
end

"""
    request_guild_members(client, guild_id; query="", limit=0, presences=false, user_ids=nothing, nonce=nothing)

Use this to fetch member information for a guild through the gateway.

Request guild members via the gateway.

# Example
```julia
# Fetch all members whose name starts with "J"
request_guild_members(client, guild_id; query="J", limit=10)

# Fetch specific users by ID
request_guild_members(client, guild_id; user_ids=[Snowflake("123456789")])
```
"""
function request_guild_members(client::Client, guild_id::Snowflake; query::String="", limit::Int=0, presences::Bool=false, user_ids=nothing, nonce=nothing)
    shard_id = shard_for_guild(guild_id, client.num_shards)
    shard = client.shards[shard_id + 1]

    d = Dict{String, Any}(
        "guild_id" => string(guild_id),
        "limit" => limit,
        "presences" => presences,
    )
    !isnothing(user_ids) ? (d["user_ids"] = user_ids) : (d["query"] = query)
    !isnothing(nonce) && (d["nonce"] = nonce)

    send_to_shard(shard, GatewayCommand(GatewayOpcodes.REQUEST_GUILD_MEMBERS, d))
end

"""
    request_soundboard_sounds(client::Client, guild_ids)

Ask the gateway for the soundboard sounds of `guild_ids`; the answer arrives as
one `SoundboardSounds` event per guild.
"""
function request_soundboard_sounds(client::Client, guild_ids::AbstractVector)
    isempty(guild_ids) && return
    # One request per shard, each listing the guilds it serves.
    by_shard = Dict{Int, Vector{String}}()
    for g in guild_ids
        gid = g isa Snowflake ? g : Snowflake(g)
        push!(get!(by_shard, shard_for_guild(gid, client.num_shards), String[]), string(gid))
    end
    for (shard_id, ids) in by_shard
        send_to_shard(client.shards[shard_id + 1],
            GatewayCommand(GatewayOpcodes.REQUEST_SOUNDBOARD_SOUNDS, Dict("guild_ids" => ids)))
    end
end

"""
    request_channel_info(client::Client, guild_id; fields=["status", "voice_start_time"])

Ask the gateway for the voice status and start time of a guild's channels; the
answer arrives as a [`ChannelInfo`](@ref) event.

# Example
```julia
request_channel_info(client, guild_id)
info = wait_for(e -> e.guild_id == guild_id, client, ChannelInfo; timeout = 10)
```
"""
function request_channel_info(client::Client, guild_id::Snowflake;
                              fields::AbstractVector{<:AbstractString} = ["status", "voice_start_time"])
    shard = client.shards[shard_for_guild(guild_id, client.num_shards) + 1]
    send_to_shard(shard, GatewayCommand(GatewayOpcodes.REQUEST_CHANNEL_INFO,
        Dict("guild_id" => string(guild_id), "fields" => collect(String, fields))))
end
