#=
Slash Command Timing Diagnostic

Tests interaction response timing to diagnose "The application did not respond" errors.
Discord requires a response within 3 seconds.

This script:
  1. Registers multiple slash commands with different response patterns
  2. Measures time from InteractionCreate event to HTTP response
  3. Logs the full pipeline timing
  4. Tests: immediate respond, defer+followup, ephemeral, embed response

Usage:
    DISCORD_TOKEN="Bot ..." TEST_GUILD_ID="..." TEST_CHANNEL_ID="..." \
        julia --project=. scripts/smoketest_slash.jl

    Then invoke each command in Discord:
      /ping          — immediate text response
      /pingdefer     — defer then edit (for slow handlers)
      /pingembed     — respond with embed
      /pingephemeral — ephemeral response
      /pingtime      — responds with measured latency
=#

using Accord
using Accord: JSON3, InteractionCreate, InteractionTypes, InteractionCallbackTypes,
    bulk_overwrite_guild_application_commands, create_interaction_response
using Dates

const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const GUILD_ID = get(ENV, "TEST_GUILD_ID", "")
const CHANNEL_ID = get(ENV, "TEST_CHANNEL_ID", "")
const SMOKE_WINDOW_SECONDS = parse(Float64, get(ENV, "SMOKE_WINDOW_SECONDS", "60"))

isempty(TOKEN) && error("Set DISCORD_TOKEN")
isempty(GUILD_ID) && error("Set TEST_GUILD_ID")

const guild_sf = Snowflake(GUILD_ID)

# ─── Timing infrastructure ───────────────────────────────────────────────────

mutable struct InteractionTiming
    command::String
    event_received::Float64     # time() when InteractionCreate arrived in event loop
    handler_start::Float64      # time() when handler function began
    response_sent::Float64      # time() when HTTP response completed
    response_status::Int
end

const timings = InteractionTiming[]
const timings_lock = ReentrantLock()

function record_timing!(t::InteractionTiming)
    lock(timings_lock) do
        push!(timings, t)
    end
    dispatch_ms = round((t.handler_start - t.event_received) * 1000; digits=1)
    handler_ms = round((t.response_sent - t.handler_start) * 1000; digits=1)
    total_ms = round((t.response_sent - t.event_received) * 1000; digits=1)
    status_str = t.response_status < 300 ? "OK" : "FAIL($(t.response_status))"

    @info "  /$(t.command) timing" dispatch_ms handler_ms total_ms status=status_str

    if total_ms > 2500
        @warn "  ⚠ SLOW: /$(t.command) took $(total_ms)ms (Discord timeout is 3000ms)"
    end
end

# ─── Direct response with timing ─────────────────────────────────────────────
# Use the library interaction endpoint helper directly so behavior matches Accord.

function timed_respond(ctx, content::String; ephemeral=false, embeds=[], command_name="unknown", event_time=time())
    handler_start = time()

    data = Dict{String, Any}()
    !isempty(content) && (data["content"] = content)
    !isempty(embeds) && (data["embeds"] = embeds)
    ephemeral && (data["flags"] = 64)

    body = Dict(
        "type" => InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE,
        "data" => data,
    )

    resp = create_interaction_response(
        ctx.client.ratelimiter,
        ctx.interaction.id,
        ctx.interaction.token;
        token=ctx.client.token,
        body=body,
    )
    response_time = time()

    record_timing!(InteractionTiming(
        command_name, event_time, handler_start, response_time, resp.status,
    ))

    if resp.status >= 300
        @warn "  Response failed" status=resp.status body=String(resp.body)
    end

    if resp.status < 300
        ctx.responded[] = true
    end
    return resp
end

function timed_defer(ctx; command_name="unknown", event_time=time())
    handler_start = time()

    body = Dict(
        "type" => InteractionCallbackTypes.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE,
        "data" => Dict{String,Any}(),
    )

    resp = create_interaction_response(
        ctx.client.ratelimiter,
        ctx.interaction.id,
        ctx.interaction.token;
        token=ctx.client.token,
        body=body,
    )
    response_time = time()

    record_timing!(InteractionTiming(
        "$(command_name) [defer]", event_time, handler_start, response_time, resp.status,
    ))

    if resp.status < 300
        ctx.deferred[] = true
    end
    return resp
end

# ─── Main ────────────────────────────────────────────────────────────────────

function main()
    @info "Slash Command Timing Diagnostic"
    @info "Discord timeout: 3000ms. We measure: dispatch (event→handler) + handler (handler→response)"

    client = Client(TOKEN;
        intents = IntentGuilds | IntentGuildMessages,
    )

    # We inject event_time by wrapping the InteractionCreate handler
    interaction_times = Dict{String, Float64}()  # interaction_id → time received
    interaction_times_lock = ReentrantLock()
    seen_interactions = Set{String}()
    seen_interactions_lock = ReentrantLock()

    function claim_interaction!(interaction_id::String)
        lock(seen_interactions_lock) do
            interaction_id in seen_interactions && return false
            push!(seen_interactions, interaction_id)
            return true
        end
    end

    # Hook into raw InteractionCreate to record event arrival time
    on(client, InteractionCreate) do c, event
        lock(interaction_times_lock) do
            interaction_times[string(event.interaction.id)] = time()
        end
    end

    # ── /ping — immediate response ────────────────────────────────────────
    @slash_command client guild_sf "ping" "Immediate text response" function(ctx)
        interaction_id = string(ctx.interaction.id)
        if !claim_interaction!(interaction_id)
            @warn "Duplicate interaction ignored" command="ping" interaction_id=interaction_id
            return
        end
        event_time = lock(interaction_times_lock) do
            get(interaction_times, interaction_id, time())
        end
        timed_respond(ctx, "Pong!"; command_name="ping", event_time)
    end

    # ── /pingdefer — defer then edit ──────────────────────────────────────
    @slash_command client guild_sf "pingdefer" "Defer then edit response" function(ctx)
        interaction_id = string(ctx.interaction.id)
        if !claim_interaction!(interaction_id)
            @warn "Duplicate interaction ignored" command="pingdefer" interaction_id=interaction_id
            return
        end
        event_time = lock(interaction_times_lock) do
            get(interaction_times, interaction_id, time())
        end
        defer_resp = timed_defer(ctx; command_name="pingdefer", event_time)
        if defer_resp.status >= 300
            @warn "Skipping deferred edit due failed defer callback" status=defer_resp.status body=String(defer_resp.body)
            return
        end

        # Simulate some work
        sleep(1.0)

        # Edit the deferred response
        edit_start = time()
        respond(ctx; content="Deferred pong! (after 1s of work)")
        edit_end = time()
        @info "  /pingdefer edit" edit_ms=round((edit_end - edit_start) * 1000; digits=1)
    end

    # ── /pingembed — embed response ───────────────────────────────────────
    @slash_command client guild_sf "pingembed" "Respond with embed" function(ctx)
        interaction_id = string(ctx.interaction.id)
        if !claim_interaction!(interaction_id)
            @warn "Duplicate interaction ignored" command="pingembed" interaction_id=interaction_id
            return
        end
        event_time = lock(interaction_times_lock) do
            get(interaction_times, interaction_id, time())
        end
        embed = Dict{String,Any}(
            "title" => "Pong!",
            "description" => "Embed response test",
            "color" => 0x5865F2,
            "timestamp" => string(Dates.now()) * "Z",
        )
        timed_respond(ctx, ""; embeds=[embed], command_name="pingembed", event_time)
    end

    # ── /pingephemeral — ephemeral response ───────────────────────────────
    @slash_command client guild_sf "pingephemeral" "Ephemeral response" function(ctx)
        interaction_id = string(ctx.interaction.id)
        if !claim_interaction!(interaction_id)
            @warn "Duplicate interaction ignored" command="pingephemeral" interaction_id=interaction_id
            return
        end
        event_time = lock(interaction_times_lock) do
            get(interaction_times, interaction_id, time())
        end
        timed_respond(ctx, "Ephemeral pong! Only you can see this.";
            ephemeral=true, command_name="pingephemeral", event_time)
    end

    # ── /pingtime — responds with its own latency ─────────────────────────
    @slash_command client guild_sf "pingtime" "Shows measured latency" function(ctx)
        interaction_id = string(ctx.interaction.id)
        if !claim_interaction!(interaction_id)
            @warn "Duplicate interaction ignored" command="pingtime" interaction_id=interaction_id
            return
        end
        event_time = lock(interaction_times_lock) do
            get(interaction_times, interaction_id, time())
        end
        handler_start = time()
        dispatch_ms = round((handler_start - event_time) * 1000; digits=1)

        timed_respond(ctx, "Dispatch latency: $(dispatch_ms)ms\nHandler will measure total after response.";
            command_name="pingtime", event_time)
    end

    # ── Start ─────────────────────────────────────────────────────────────
    start(client; blocking=false)
    wait_until_ready(client)

    @info "Syncing commands to guild..."
    sync_commands!(client, client.command_tree; guild_id=guild_sf)
    @info "Commands registered. Invoke them in Discord:"
    @info "  /ping          — immediate text"
    @info "  /pingdefer     — defer + edit"
    @info "  /pingembed     — embed response"
    @info "  /pingephemeral — ephemeral"
    @info "  /pingtime      — shows latency in response"
    @info ""
    @info "Running for $(round(SMOKE_WINDOW_SECONDS; digits=1))s before auto-stop and summary."
    deadline = time() + SMOKE_WINDOW_SECONDS
    while time() < deadline
        sleep(1.0)
    end

    # ── Report ────────────────────────────────────────────────────────────
    println("\n" * "="^70)
    println("SLASH COMMAND TIMING REPORT")
    println("="^70)
    println("  Discord timeout: 3000ms")
    println()

    if isempty(timings)
        println("  No commands were invoked.")
    else
        println("  Command                  Dispatch   Handler   Total    Status")
        println("  " * "-"^64)
        for t in timings
            dispatch_ms = round((t.handler_start - t.event_received) * 1000; digits=1)
            handler_ms = round((t.response_sent - t.handler_start) * 1000; digits=1)
            total_ms = round((t.response_sent - t.event_received) * 1000; digits=1)
            status = t.response_status < 300 ? "OK" : "FAIL($(t.response_status))"
            warn = total_ms > 2500 ? " ⚠" : ""
            name = rpad(t.command, 24)
            println("  $name $(lpad(string(dispatch_ms), 7))ms $(lpad(string(handler_ms), 7))ms $(lpad(string(total_ms), 7))ms  $status$warn")
        end

        totals = [t.response_sent - t.event_received for t in timings]
        dispatches = [t.handler_start - t.event_received for t in timings]
        println()
        println("  Dispatch: avg=$(round(sum(dispatches)/length(dispatches)*1000; digits=1))ms, max=$(round(maximum(dispatches)*1000; digits=1))ms")
        println("  Total:    avg=$(round(sum(totals)/length(totals)*1000; digits=1))ms, max=$(round(maximum(totals)*1000; digits=1))ms")
        slow = count(t -> t > 2.5, totals)
        println("  Slow (>2.5s): $slow / $(length(totals))")
    end

    println("="^70)

    # Cleanup commands
    @info "Cleaning up slash commands..."
    try
        bulk_overwrite_guild_application_commands(client.ratelimiter, client.application_id, guild_sf;
            token=client.token, body=Dict{String,Any}[])
        @info "Commands removed."
    catch e
        @warn "Failed to remove commands" exception=e
    end

    stop(client)
end

main()
