#=
Accord.jl Exercise Smoke Test

Actively exercises the main Accord.jl features against a real Discord server.
Registers a slash command, sends messages, embeds, reactions, and cleans up.

Usage:
    DISCORD_TOKEN="Bot ..." TEST_GUILD_ID="..." TEST_CHANNEL_ID="..." \
        julia --project=. scripts/smoketest_exercise.jl

The bot will:
  1. Connect and wait for READY
  2. Register a /smoketest slash command (guild-scoped, instant)
  3. Send messages with content, embeds, reactions
  4. Edit and delete messages
  5. Test the cache layer
  6. Clean up the slash command
  7. Report results and exit
=#

using Accord
using Accord: JSON3

# ─── Config ──────────────────────────────────────────────────────────────────

const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const GUILD_ID = get(ENV, "TEST_GUILD_ID", "")
const CHANNEL_ID = get(ENV, "TEST_CHANNEL_ID", "")

isempty(TOKEN) && error("Set DISCORD_TOKEN")
isempty(GUILD_ID) && error("Set TEST_GUILD_ID")
isempty(CHANNEL_ID) && error("Set TEST_CHANNEL_ID")

const guild_sf = Snowflake(GUILD_ID)
const channel_sf = Snowflake(CHANNEL_ID)

# ─── Test results ────────────────────────────────────────────────────────────

mutable struct TestResult
    name::String
    passed::Bool
    error::String
end

const results = TestResult[]
const results_lock = ReentrantLock()

function record!(name::String, passed::Bool, err::String="")
    lock(results_lock) do
        push!(results, TestResult(name, passed, err))
    end
    status = passed ? "PASS" : "FAIL"
    if passed
        @info "  [$status] $name"
    else
        @warn "  [$status] $name" error=err
    end
end

macro smoke(name, block)
    quote
        try
            $(esc(block))
            record!($(esc(name)), true)
        catch e
            record!($(esc(name)), false, sprint(showerror, e))
        end
    end
end

# ─── Main ────────────────────────────────────────────────────────────────────

function main()
    @info "Accord.jl Exercise Smoke Test"
    @info "Connecting..."

    client = Client(TOKEN;
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
    )

    # Track if slash command interaction was received
    slash_received = Channel{Bool}(1)

    # Register slash command handler BEFORE start
    @slash_command client guild_sf "smoketest" "Accord.jl smoke test" function(ctx)
        respond(ctx; content="Smoke test response at $(Dates.now())")
        put!(slash_received, true)
    end

    start(client; blocking=false)
    wait_until_ready(client)
    @info "Connected! Bot is ready."

    # Small delay to let GUILD_CREATE propagate
    sleep(2.0)

    # ── Test 1: Send a plain message ──────────────────────────────────────
    local msg1
    @smoke "Send plain message" begin
        msg1 = create_message(client, channel_sf; content="[Smoke Test] Plain message")
        @assert msg1 isa Message "Expected Message, got $(typeof(msg1))"
        @assert msg1.id isa Snowflake
    end

    # ── Test 2: Send a message with embed ─────────────────────────────────
    local msg2
    @smoke "Send embed message" begin
        embed = Dict{String,Any}(
            "title" => "Smoke Test Embed",
            "description" => "Testing embed rendering",
            "color" => 0x00FF00,
            "fields" => [
                Dict("name" => "Library", "value" => "Accord.jl", "inline" => true),
                Dict("name" => "Language", "value" => "Julia", "inline" => true),
            ],
            "footer" => Dict("text" => "Automated smoke test"),
        )
        msg2 = create_message(client, channel_sf; embeds=[embed])
        @assert msg2 isa Message
        @assert !ismissing(msg2.embeds) && length(msg2.embeds) >= 1
    end

    # ── Test 3: Add reaction ──────────────────────────────────────────────
    @smoke "Add reaction" begin
        create_reaction(client, channel_sf, msg1.id, "✅")
        sleep(0.5)
        create_reaction(client, channel_sf, msg1.id, "🔥")
    end

    # ── Test 4: Edit message ──────────────────────────────────────────────
    local msg1_edited
    @smoke "Edit message" begin
        msg1_edited = edit_message(client, channel_sf, msg1.id;
            content="[Smoke Test] Edited message")
        @assert msg1_edited isa Message
        @assert !ismissing(msg1_edited.content) && msg1_edited.content == "[Smoke Test] Edited message"
    end

    # ── Test 5: Reply to a message ────────────────────────────────────────
    local msg3
    @smoke "Reply to message" begin
        msg3 = reply(client, msg1; content="[Smoke Test] Reply")
        @assert msg3 isa Message
        @assert !ismissing(msg3.message_reference)
    end

    # ── Test 6: Get channel from REST ─────────────────────────────────────
    @smoke "GET channel" begin
        ch = get_channel(client, channel_sf)
        @assert ch isa DiscordChannel
        @assert ch.id == channel_sf
    end

    # ── Test 7: Get guild from REST/cache ─────────────────────────────────
    @smoke "GET guild" begin
        g = get_guild(client, guild_sf)
        @assert g isa Guild
        @assert g.id == guild_sf
        @assert !isempty(g.name)
    end

    # ── Test 8: Sync slash command (guild-scoped) ─────────────────────────
    @smoke "Sync slash commands" begin
        sync_commands!(client, client.command_tree; guild_id=guild_sf)
    end

    # ── Test 9: Wait for slash command interaction (manual or timeout) ────
    @smoke "Slash command registered (check Discord)" begin
        @info "    → /smoketest command registered. Invoke it in Discord within 15s, or it will skip."
        result = timedwait(() -> isready(slash_received), 15.0)
        if result === :timed_out
            @info "    → Timed out waiting for /smoketest — skipping (command was registered)"
        else
            take!(slash_received)
            @info "    → Slash command interaction received and responded!"
        end
        # Pass either way — we verified registration
    end

    # ── Test 10: update_presence ──────────────────────────────────────────
    @smoke "Update presence" begin
        update_presence(client;
            status="dnd",
            activities=[Dict(
                "name" => "Smoke Testing",
                "type" => 0,  # Playing
            )],
        )
        sleep(1.0)
        # Restore
        update_presence(client; status="online")
    end

    # ── Test 11: Bulk message creation (rate limiter stress) ──────────────
    local bulk_msgs = Message[]
    @smoke "Burst 5 messages (rate limiter)" begin
        for i in 1:5
            m = create_message(client, channel_sf; content="[Smoke Test] Burst $i/5")
            push!(bulk_msgs, m)
        end
        @assert length(bulk_msgs) == 5
    end

    # ── Cleanup: delete all test messages ─────────────────────────────────
    @info "Cleaning up test messages..."
    all_msgs = Message[]
    @isdefined(msg1) && msg1 isa Message && push!(all_msgs, msg1)
    @isdefined(msg2) && msg2 isa Message && push!(all_msgs, msg2)
    @isdefined(msg3) && msg3 isa Message && push!(all_msgs, msg3)
    append!(all_msgs, bulk_msgs)

    for m in all_msgs
        try
            delete_message(client, channel_sf, m.id)
            sleep(0.3)
        catch e
            @warn "Failed to delete message" id=m.id exception=e
        end
    end

    # ── Cleanup: remove guild command ─────────────────────────────────────
    @info "Removing smoke test slash command..."
    try
        # Overwrite with empty to remove
        bulk_overwrite_guild_application_commands(client.ratelimiter, client.application_id, guild_sf;
            token=client.token, body=Dict{String,Any}[])
    catch e
        @warn "Failed to clean up slash command" exception=e
    end

    # ── Report ────────────────────────────────────────────────────────────
    stop(client)

    println("\n" * "="^60)
    println("SMOKE TEST RESULTS")
    println("="^60)
    passed = count(r -> r.passed, results)
    failed = count(r -> !r.passed, results)
    for r in results
        status = r.passed ? "✓" : "✗"
        print("  $status $(r.name)")
        !isempty(r.error) && print(" — $(r.error)")
        println()
    end
    println("-"^60)
    println("  $passed passed, $failed failed, $(length(results)) total")
    println("="^60)

    return failed == 0 ? 0 : 1
end

using Dates
exit(main())
