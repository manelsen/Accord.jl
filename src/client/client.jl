# Client — orchestrates Gateway, REST, and Cache

"""
    Client

The main Discord client that orchestrates gateway connections, REST API calls, and state caching.

# Constructor
    Client(token::String; intents=IntentAllNonPrivileged, num_shards=1, state_options...)

# Example
```julia
client = Client("Bot YOUR_TOKEN_HERE"; intents=IntentGuilds | IntentGuildMessages)
on(client, MessageCreate) do c, event
    event.message.content == "ping" && create_message(c, event.message.channel_id; content="pong")
end
start(client)
```
"""
mutable struct Client
    token::String
    application_id::Nullable{Snowflake}
    intents::UInt32
    state::State
    event_handler::EventHandler
    command_tree::CommandTree
    ratelimiter::RateLimiter
    shards::Vector{ShardInfo}
    num_shards::Int
    ready::Base.Event
    running::Bool
    _event_loop_task::Nullable{Task}
    _supervisor_task::Nullable{Task}
end

function Client(token::String;
    intents::Union{Intents, UInt32, Integer} = IntentAllNonPrivileged,
    num_shards::Int = 1,
    guild_strategy::CacheStrategy = CacheForever(),
    channel_strategy::CacheStrategy = CacheForever(),
    user_strategy::CacheStrategy = CacheLRU(10_000),
    member_strategy::CacheStrategy = CacheLRU(10_000),
    presence_strategy::CacheStrategy = CacheNever(),
)
    # Ensure token has Bot prefix
    actual_token = startswith(token, "Bot ") ? token : "Bot $token"

    intents_val = intents isa Intents ? UInt32(intents.value) : UInt32(intents)

    state = State(;
        guild_strategy, channel_strategy, user_strategy,
        member_strategy, presence_strategy,
    )

    events_channel = Channel{AbstractEvent}(1024)

    shards = [ShardInfo(i, num_shards, events_channel) for i in 0:(num_shards-1)]

    tree = CommandTree()

    client = Client(
        actual_token,
        nothing,
        intents_val,
        state,
        EventHandler(),
        tree,
        RateLimiter(),
        shards,
        num_shards,
        Base.Event(),
        false,
        nothing,
        nothing,
    )

    # Register interaction dispatcher
    on(client, InteractionCreate) do c, event
        dispatch_interaction!(c.command_tree, c, event.interaction)
    end

    return client
end

"""
    on(handler, client, EventType)

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

Set a custom error handler. Receives (client, event, error).
"""
function on_error(handler::Function, client::Client)
    client.event_handler.error_handler = handler
end

"""
    start(client::Client; blocking=true)

Connect to Discord and start processing events.
If `blocking=true` (default), this blocks until the client is stopped.
"""
function start(client::Client; blocking::Bool=true)
    client.running = true

    # Start rate limiter
    start_ratelimiter!(client.ratelimiter)

    # Start shards (with 5s delay between shards as Discord requires)
    for (i, shard) in enumerate(client.shards)
        if i > 1
            sleep(5.0)
        end
        start_shard(shard, client.token, client.intents)
    end

    # Start event processing loop
    client._event_loop_task = @async _event_loop(client)

    # Start supervisor task to monitor and restart shards
    client._supervisor_task = @async _supervisor_loop(client)

    if blocking
        # Wait for first shard to be ready
        wait(client.shards[1].ready)
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
        @async begin
            wait(client.shards[1].ready)
            notify(client.ready)
        end
    end
end

"""
    stop(client::Client)

Disconnect from Discord and stop processing events.
"""
function stop(client::Client)
    client.running = false

    # Stop shards
    for shard in client.shards
        stop_shard(shard)
    end

    # Stop rate limiter
    stop_ratelimiter!(client.ratelimiter)

    @info "Client stopped"
end

"""
    wait_until_ready(client::Client)

Block until the client receives the READY event.
"""
function wait_until_ready(client::Client)
    wait(client.ready)
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

        # Dispatch to handlers
        dispatch_event!(client.event_handler, client, event)
    end
end

function _supervisor_loop(client::Client)
    @debug "Supervisor task started"
    
    while client.running
        # Check every 5 seconds
        sleep(5.0)
        
        for shard in client.shards
            # If the task is finished but we didn't stop the bot, restart it
            if !isnothing(shard.task) && istaskdone(shard.task) && client.running
                # Check if it was an intentional stop (connected would be false)
                # shard.session.connected is managed by gateway_connect and stop_shard
                if shard.session.connected
                    @error "Shard $(shard.id) died unexpectedly! Restarting..."
                    start_shard(shard, client.token, client.intents)
                end
            end
        end
    end
    
    @debug "Supervisor task stopped"
end

# --- Convenience REST methods on Client ---

"""Send a message to a channel."""
function create_message(client::Client, channel_id::Snowflake; content::String="", embeds::Vector{Dict}=Dict[], components::Vector{Dict}=Dict[], files=nothing, tts::Bool=false, message_reference=nothing)
    body = Dict{String, Any}()
    !isempty(content) && (body["content"] = content)
    !isempty(embeds) && (body["embeds"] = embeds)
    !isempty(components) && (body["components"] = components)
    tts && (body["tts"] = true)
    !isnothing(message_reference) && (body["message_reference"] = message_reference)
    create_message(client.ratelimiter, channel_id; token=client.token, body, files)
end

"""Edit a message."""
function edit_message(client::Client, channel_id::Snowflake, message_id::Snowflake; kwargs...)
    body = Dict{String, Any}()
    for (k, v) in kwargs
        body[string(k)] = v
    end
    edit_message(client.ratelimiter, channel_id, message_id; token=client.token, body)
end

"""Delete a message."""
function delete_message(client::Client, channel_id::Snowflake, message_id::Snowflake; reason=nothing)
    delete_message(client.ratelimiter, channel_id, message_id; token=client.token, reason)
end

"""Create a reaction on a message."""
function create_reaction(client::Client, channel_id::Snowflake, message_id::Snowflake, emoji::String)
    create_reaction(client.ratelimiter, channel_id, message_id, emoji; token=client.token)
end

"""Get a channel by ID."""
function get_channel(client::Client, channel_id::Snowflake)
    # Check cache first
    cached = get(client.state.channels, channel_id)
    !isnothing(cached) && return cached

    get_channel(client.ratelimiter, channel_id; token=client.token)
end

"""Get a guild by ID."""
function get_guild(client::Client, guild_id::Snowflake)
    cached = get(client.state.guilds, guild_id)
    !isnothing(cached) && return cached

    get_guild(client.ratelimiter, guild_id; token=client.token)
end

"""Get a user by ID."""
function get_user(client::Client, user_id::Snowflake)
    cached = get(client.state.users, user_id)
    !isnothing(cached) && return cached

    get_user(client.ratelimiter, user_id; token=client.token)
end

"""Send a gateway command to update voice state (join/leave/move voice channels)."""
function update_voice_state(client::Client, guild_id::Snowflake; channel_id=nothing, self_mute::Bool=false, self_deaf::Bool=false)
    shard_id = shard_for_guild(guild_id, client.num_shards)
    shard = client.shards[shard_id + 1]
    cmd = GatewayCommand(GatewayOpcodes.VOICE_STATE_UPDATE, Dict(
        "guild_id" => string(guild_id),
        "channel_id" => isnothing(channel_id) ? nothing : string(channel_id),
        "self_mute" => self_mute,
        "self_deaf" => self_deaf,
    ))
    send_to_shard(shard, cmd)
end

"""Send a gateway command to update the bot's presence/status."""
function update_presence(client::Client; status::String="online", activities::Vector{Dict}=Dict[], afk::Bool=false, since=nothing)
    for shard in client.shards
        cmd = GatewayCommand(GatewayOpcodes.PRESENCE_UPDATE, Dict(
            "since" => since,
            "activities" => activities,
            "status" => status,
            "afk" => afk,
        ))
        send_to_shard(shard, cmd)
    end
end

"""Request guild members via the gateway."""
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
