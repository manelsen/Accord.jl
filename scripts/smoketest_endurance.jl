#=
Accord.jl Endurance Smoke Test

Keeps a bot online for an extended period, monitoring lifecycle events.
Logs reconnects, heartbeat health, errors, and memory usage.

Usage:
    DISCORD_TOKEN="Bot ..." TEST_CHANNEL_ID="..." \
        julia --project=. scripts/smoketest_endurance.jl

Optional env vars:
    ENDURANCE_HOURS  — how long to run (default: 24)

The bot will:
  1. Connect and stay online
  2. Log every event type received (with counts)
  3. Monitor heartbeat ACK timing
  4. Detect and log reconnections
  5. Periodically report health status to the test channel
  6. Write a final report on exit
=#

using Accord
using Accord: JSON3, HeartbeatState,
    GuildUpdate, ChannelUpdate, MessageUpdate, MessageDelete,
    GuildRoleCreate, GuildRoleUpdate, GuildRoleDelete,
    GuildEmojisUpdate, GuildStickersUpdate
using Dates

# ─── Config ──────────────────────────────────────────────────────────────────

const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const CHANNEL_ID = get(ENV, "TEST_CHANNEL_ID", "")
const HOURS = parse(Float64, get(ENV, "ENDURANCE_HOURS", "24"))

isempty(TOKEN) && error("Set DISCORD_TOKEN")

const REPORT_INTERVAL = 3600  # seconds between health reports
const LOGFILE = joinpath(@__DIR__, "endurance_$(Dates.format(now(), "yyyymmdd_HHMMss")).log")

# ─── Metrics ─────────────────────────────────────────────────────────────────

mutable struct Metrics
    start_time::DateTime
    event_counts::Dict{String, Int}
    ready_count::Int
    reconnect_count::Int
    errors::Vector{Tuple{DateTime, String}}
    last_heartbeat_ack::DateTime
    heartbeat_gaps::Vector{Float64}  # seconds between consecutive ACKs
    peak_memory_mb::Float64
    lock::ReentrantLock
end

function Metrics()
    Metrics(
        now(), Dict{String, Int}(),
        0, 0, Tuple{DateTime, String}[],
        now(), Float64[],
        0.0, ReentrantLock(),
    )
end

const metrics = Metrics()

function count_event!(name::String)
    lock(metrics.lock) do
        metrics.event_counts[name] = get(metrics.event_counts, name, 0) + 1
    end
end

function record_error!(msg::String)
    lock(metrics.lock) do
        push!(metrics.errors, (now(), msg))
    end
end

function record_heartbeat_ack!()
    lock(metrics.lock) do
        prev = metrics.last_heartbeat_ack
        metrics.last_heartbeat_ack = now()
        gap = Dates.value(metrics.last_heartbeat_ack - prev) / 1000.0
        # Only record if gap is reasonable (not the first one)
        if gap < 300  # less than 5 min
            push!(metrics.heartbeat_gaps, gap)
        end
    end
end

function update_memory!()
    mb = Sys.maxrss() / 1024 / 1024
    lock(metrics.lock) do
        metrics.peak_memory_mb = max(metrics.peak_memory_mb, mb)
    end
end

# ─── Logging ─────────────────────────────────────────────────────────────────

const logfile_io = open(LOGFILE, "w")

function logboth(level::String, msg::String)
    ts = Dates.format(now(), "HH:MM:SS")
    line = "[$ts][$level] $msg"
    println(logfile_io, line)
    flush(logfile_io)
    if level == "ERROR"
        @error msg
    elseif level == "WARN"
        @warn msg
    else
        @info msg
    end
end

# ─── Health Report ───────────────────────────────────────────────────────────

function health_report()
    uptime = now() - metrics.start_time
    hours = Dates.value(uptime) / (1000 * 3600)
    total_events = lock(metrics.lock) do
        sum(values(metrics.event_counts); init=0)
    end

    avg_hb = if !isempty(metrics.heartbeat_gaps)
        round(sum(metrics.heartbeat_gaps) / length(metrics.heartbeat_gaps); digits=1)
    else
        0.0
    end

    max_hb = isempty(metrics.heartbeat_gaps) ? 0.0 : round(maximum(metrics.heartbeat_gaps); digits=1)

    update_memory!()

    report = """Endurance Report @ $(Dates.format(now(), "HH:MM"))
    Uptime: $(round(hours; digits=1))h
    Events: $total_events total, $(length(keys(metrics.event_counts))) types
    Ready: $(metrics.ready_count)x | Reconnects: $(metrics.reconnect_count)x
    Heartbeat: avg=$(avg_hb)s, max=$(max_hb)s ($(length(metrics.heartbeat_gaps)) samples)
    Errors: $(length(metrics.errors))
    Memory: $(round(metrics.peak_memory_mb; digits=1)) MB peak"""

    logboth("INFO", replace(report, "\n" => " | "))
    return report
end

function final_report()
    update_memory!()
    uptime = now() - metrics.start_time
    hours = Dates.value(uptime) / (1000 * 3600)

    lines = String[]
    push!(lines, "="^60)
    push!(lines, "ENDURANCE TEST FINAL REPORT")
    push!(lines, "="^60)
    push!(lines, "Duration: $(round(hours; digits=2)) hours")
    push!(lines, "Ready events: $(metrics.ready_count)")
    push!(lines, "Reconnects: $(metrics.reconnect_count)")
    push!(lines, "Total errors: $(length(metrics.errors))")
    push!(lines, "Peak memory: $(round(metrics.peak_memory_mb; digits=1)) MB")
    push!(lines, "")
    push!(lines, "Event counts:")
    for (name, count) in sort(collect(metrics.event_counts); by=last, rev=true)
        push!(lines, "  $name: $count")
    end

    if !isempty(metrics.heartbeat_gaps)
        avg = round(sum(metrics.heartbeat_gaps) / length(metrics.heartbeat_gaps); digits=2)
        mx = round(maximum(metrics.heartbeat_gaps); digits=2)
        mn = round(minimum(metrics.heartbeat_gaps); digits=2)
        push!(lines, "")
        push!(lines, "Heartbeat ACK gaps: avg=$(avg)s, min=$(mn)s, max=$(mx)s (n=$(length(metrics.heartbeat_gaps)))")
    end

    if !isempty(metrics.errors)
        push!(lines, "")
        push!(lines, "Errors (last 20):")
        for (ts, err) in metrics.errors[max(1, end-19):end]
            push!(lines, "  [$(Dates.format(ts, "HH:MM:SS"))] $err")
        end
    end

    push!(lines, "="^60)

    report = join(lines, "\n")
    println(report)
    println(logfile_io, report)
    flush(logfile_io)

    # Also write to a separate report file
    report_path = joinpath(@__DIR__, "endurance_report_$(Dates.format(now(), "yyyymmdd_HHMMss")).txt")
    open(report_path, "w") do io
        println(io, report)
    end
    @info "Report saved to $report_path"
end

# ─── Main ────────────────────────────────────────────────────────────────────

function main()
    @info "Accord.jl Endurance Test — running for $(HOURS)h"
    @info "Log file: $LOGFILE"

    client = Client(TOKEN;
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent |
                  IntentGuildPresences | IntentGuildMembers,
    )

    deadline = now() + Dates.Millisecond(round(Int, HOURS * 3600 * 1000))

    # ── Track READY (counts reconnections) ────────────────────────────────
    on(client, ReadyEvent) do c, event
        metrics.ready_count += 1
        if metrics.ready_count > 1
            metrics.reconnect_count += 1
            logboth("WARN", "Reconnected! (ready #$(metrics.ready_count), reconnect #$(metrics.reconnect_count))")
        else
            logboth("INFO", "Connected as $(event.user.username) ($(length(event.guilds)) guilds)")
        end
        count_event!("READY")
    end

    # ── Track ALL events ──────────────────────────────────────────────────
    for EventType in [
        GuildCreate, GuildUpdate, GuildDelete,
        ChannelCreate, ChannelUpdate, ChannelDelete,
        MessageCreate, MessageUpdate, MessageDelete,
        GuildMemberAdd, GuildMemberRemove, GuildMemberUpdate,
        GuildRoleCreate, GuildRoleUpdate, GuildRoleDelete,
        PresenceUpdate, TypingStart,
        GuildEmojisUpdate, GuildStickersUpdate,
    ]
        on(client, EventType) do c, event
            count_event!(string(nameof(typeof(event))))
        end
    end

    # ── Error handler ─────────────────────────────────────────────────────
    on_error(client) do c, event, err
        msg = "Handler error on $(typeof(event)): $(sprint(showerror, err))"
        logboth("ERROR", msg)
        record_error!(msg)
    end

    # ── Start ─────────────────────────────────────────────────────────────
    start(client; blocking=false)
    wait_until_ready(client)
    logboth("INFO", "Bot is ready. Endurance test running until $(Dates.format(deadline, "yyyy-mm-dd HH:MM"))")

    # Send start message to channel
    if !isempty(CHANNEL_ID)
        try
            create_message(client, Snowflake(CHANNEL_ID);
                content="[Endurance Test] Started at $(Dates.format(now(), "HH:MM:SS")). Running for $(HOURS)h.")
        catch; end
    end

    # ── Main loop ─────────────────────────────────────────────────────────
    last_report = time()
    last_hb_check = time()

    try
        while now() < deadline
            sleep(10.0)

            # Check heartbeat health every 60s
            if time() - last_hb_check >= 60
                last_hb_check = time()
                for shard in client.shards
                    hb = shard.session.heartbeat_state
                    if !isnothing(hb) && hb.ack_received
                        record_heartbeat_ack!()
                    end
                end
                update_memory!()
            end

            # Periodic health report
            if time() - last_report >= REPORT_INTERVAL
                last_report = time()
                report = health_report()

                # Post to channel
                if !isempty(CHANNEL_ID)
                    try
                        create_message(client, Snowflake(CHANNEL_ID);
                            content="```\n$report\n```")
                    catch e
                        logboth("WARN", "Failed to post health report: $(sprint(showerror, e))")
                    end
                end
            end
        end
    catch e
        if e isa InterruptException
            logboth("INFO", "Interrupted by user (Ctrl+C)")
        else
            logboth("ERROR", "Unexpected error: $(sprint(showerror, e))")
        end
    end

    # ── Shutdown ──────────────────────────────────────────────────────────
    logboth("INFO", "Endurance test ending...")

    # Send final message
    if !isempty(CHANNEL_ID)
        try
            create_message(client, Snowflake(CHANNEL_ID);
                content="[Endurance Test] Completed after $(round(Dates.value(now() - metrics.start_time) / 3600000; digits=1))h.")
        catch; end
    end

    stop(client)
    close(logfile_io)

    final_report()
end

main()
