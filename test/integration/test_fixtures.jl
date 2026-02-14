#=
Integration tests that validate Accord.jl's type parsing against real Discord payloads.

These tests load JSON fixtures captured from a real Discord connection
(via capture_payloads.jl) and feed them through the same parsing pipeline
that Accord.jl uses in production.

Run:
    julia --project=. -e 'using Pkg; Pkg.test()' -- integration
Or directly:
    julia --project=. test/integration/test_fixtures.jl
=#

using Test
using Accord
using Accord: JSON3, parse_event, AbstractEvent, UnknownEvent,
    GatewaySession, ReadyEvent, GuildCreate, MessageCreate,
    ChannelCreate, PresenceUpdate, TypingStart

const FIXTURES_DIR = joinpath(@__DIR__, "fixtures")

# ─── Helpers ─────────────────────────────────────────────────────────────────

"""Load a fixture file, returning a Vector of payloads (or empty if file missing)."""
function load_fixture(name::String)
    path = joinpath(FIXTURES_DIR, "$(name).json")
    isfile(path) || return Dict{String,Any}[]
    JSON3.read(read(path, String), Vector{Dict{String,Any}})
end

"""Load a single fixture (first element)."""
function load_fixture_one(name::String)
    payloads = load_fixture(name)
    isempty(payloads) ? nothing : first(payloads)
end

"""Check if a fixture category exists and has data."""
has_fixture(name::String) = isfile(joinpath(FIXTURES_DIR, "$(name).json"))

"""Extract the 'd' (data) field from a gateway payload."""
get_data(payload::Dict) = payload["d"]

"""Redact sensitive fields for safe logging."""
function redact!(d::Dict)
    for key in ("token", "session_id", "email")
        haskey(d, key) && (d[key] = "<redacted>")
    end
    d
end

# ─── Preflight ───────────────────────────────────────────────────────────────

if !isdir(FIXTURES_DIR) || !has_fixture("_manifest")
    @warn """
    No fixtures found at $FIXTURES_DIR
    Run capture_payloads.jl first to capture real Discord payloads:

        DISCORD_TOKEN="Bot ..." julia test/integration/capture_payloads.jl
    """
    @testset "Integration Tests (skipped — no fixtures)" begin
        @test_skip true
    end
    exit(0)
end

manifest = JSON3.read(read(joinpath(FIXTURES_DIR, "_manifest.json"), String), Dict{String,Any})
@info "Loading fixtures" captured_at=manifest["captured_at"] categories=manifest["categories"]

# ═══════════════════════════════════════════════════════════════════════════════
# GATEWAY EVENT PARSING
# ═══════════════════════════════════════════════════════════════════════════════

@testset "Gateway Event Parsing (real payloads)" begin

    # ── READY ──────────────────────────────────────────────────────────────
    @testset "READY" begin
        if has_fixture("gateway_ready")
            payload = load_fixture_one("gateway_ready")
            data = get_data(payload)

            event = parse_event("READY", data)
            @test event isa ReadyEvent
            @test event.v == 10
            @test event.user isa User
            @test !isempty(event.user.username)
            @test event.user.id isa Snowflake
            @test event.session_id isa String
            @test !isempty(event.session_id)
            @test event.resume_gateway_url isa String
            @test startswith(event.resume_gateway_url, "wss://")
            @test event.guilds isa Vector{UnavailableGuild}

            # Verify user round-trips cleanly
            user_json = JSON3.write(event.user)
            user2 = JSON3.read(user_json, User)
            @test user2.id == event.user.id
            @test user2.username == event.user.username
        else
            @test_skip "no READY fixture"
        end
    end

    # ── GUILD_CREATE ───────────────────────────────────────────────────────
    @testset "GUILD_CREATE" begin
        if has_fixture("gateway_guild_create")
            payloads = load_fixture("gateway_guild_create")
            @test length(payloads) >= 1

            for (i, payload) in enumerate(payloads)
                data = get_data(payload)
                event = parse_event("GUILD_CREATE", data)
                @test event isa GuildCreate

                guild = event.guild
                @test guild isa Guild
                @test guild.id isa Snowflake
                @test guild.name isa String
                @test !isempty(guild.name)

                # Roles — every guild has at least @everyone
                if !ismissing(guild.roles)
                    @test length(guild.roles) >= 1
                    everyone = first(guild.roles)
                    @test everyone isa Role
                    @test everyone.id isa Snowflake
                end

                # Channels
                if !ismissing(guild.channels)
                    @test all(ch -> ch isa DiscordChannel, guild.channels)
                    for ch in guild.channels
                        @test ch.id isa Snowflake
                        @test ch.type isa Int
                    end
                end

                # Members (if present in GUILD_CREATE)
                if !ismissing(guild.members)
                    @test all(m -> m isa Member, guild.members)
                end

                # Emojis
                if !ismissing(guild.emojis)
                    @test all(e -> e isa Emoji, guild.emojis)
                end

                # Round-trip: Guild → JSON → Guild
                guild_json = JSON3.write(guild)
                guild2 = JSON3.read(guild_json, Guild)
                @test guild2.id == guild.id
                @test guild2.name == guild.name

                i >= 3 && break  # Don't test all guilds, just a few
            end
        else
            @test_skip "no GUILD_CREATE fixture"
        end
    end

    # ── MESSAGE_CREATE ─────────────────────────────────────────────────────
    @testset "MESSAGE_CREATE" begin
        if has_fixture("gateway_message_create")
            payloads = load_fixture("gateway_message_create")

            for (i, payload) in enumerate(payloads)
                data = get_data(payload)
                event = parse_event("MESSAGE_CREATE", data)
                @test event isa MessageCreate

                msg = event.message
                @test msg isa Message
                @test msg.id isa Snowflake
                @test msg.channel_id isa Snowflake
                @test msg.type isa Int

                # Author (may be missing for webhook messages)
                if !ismissing(msg.author)
                    @test msg.author isa User
                    @test msg.author.id isa Snowflake
                end

                # Content (may be missing if no MESSAGE_CONTENT intent for others' messages)
                if !ismissing(msg.content)
                    @test msg.content isa String
                end

                # Embeds
                if !ismissing(msg.embeds) && !isempty(msg.embeds)
                    @test all(e -> e isa Embed, msg.embeds)
                end

                # Components
                if !ismissing(msg.components) && !isempty(msg.components)
                    @test all(c -> c isa Component, msg.components)
                end

                # Attachments
                if !ismissing(msg.attachments) && !isempty(msg.attachments)
                    @test all(a -> a isa Attachment, msg.attachments)
                end

                # Round-trip
                msg_json = JSON3.write(msg)
                msg2 = JSON3.read(msg_json, Message)
                @test msg2.id == msg.id
                @test msg2.channel_id == msg.channel_id

                # Components V2 validation
                if !ismissing(msg.components)
                    for row in msg.components
                        !ismissing(row.components) && for comp in row.components
                            if comp.type >= 9 # Section, TextDisplay, etc.
                                @test comp.type in (9, 10, 11, 12, 13, 14, 17)
                            end
                        end
                    end
                end

                i >= 5 && break
            end
        else
            @test_skip "no MESSAGE_CREATE fixture"
        end
    end

    # ── INTERACTION_CREATE ─────────────────────────────────────────────────
    @testset "INTERACTION_CREATE" begin
        if has_fixture("gateway_interaction_create")
            payloads = load_fixture("gateway_interaction_create")
            for (i, payload) in enumerate(payloads)
                data = get_data(payload)
                event = parse_event("INTERACTION_CREATE", data)
                @test event isa InteractionCreate
                
                int = event.interaction
                @test int.id isa Snowflake
                @test int.application_id isa Snowflake
                @test int.type in (1, 2, 3, 4, 5)

                # Context Menu specific validation
                if int.type == 2 && !ismissing(int.data)
                    data = int.data
                    if !ismissing(data.type) && data.type in (2, 3) # USER or MESSAGE
                        @test !ismissing(data.target_id)
                        @test !ismissing(data.resolved)
                    end
                end

                # Modal Submit validation
                if int.type == 5 && !ismissing(int.data)
                    @test !ismissing(int.data.components)
                end

                i >= 10 && break
            end
        else
            @test_skip "no INTERACTION_CREATE fixture"
        end
    end

    # ── AUTO_MODERATION_ACTION_EXECUTION ───────────────────────────────────
    @testset "AUTO_MODERATION_ACTION_EXECUTION" begin
        if has_fixture("gateway_auto_moderation_action_execution")
            payload = load_fixture_one("gateway_auto_moderation_action_execution")
            data = get_data(payload)
            event = parse_event("AUTO_MODERATION_ACTION_EXECUTION", data)
            
            @test event isa AutoModActionExecution
            @test event.guild_id isa Snowflake
            @test event.rule_id isa Snowflake
            @test event.action isa AutoModAction
        else
            @test_skip "no AUTO_MODERATION_ACTION_EXECUTION fixture"
        end
    end

    # ── Generic: parse every captured gateway event ────────────────────────
    @testset "All gateway events parse without error" begin
        categories = [c for c in manifest["categories"] if startswith(c, "gateway_")]
        skipped = Set(["gateway_hello", "gateway_heartbeat_ack"])

        for category in categories
            category in skipped && continue
            event_name = uppercase(replace(category, "gateway_" => ""))

            payloads = load_fixture(category)
            isempty(payloads) && continue

            @testset "$event_name ($(length(payloads)) payloads)" begin
                for (i, payload) in enumerate(payloads)
                    d = get(payload, "d", nothing)
                    isnothing(d) && continue

                    event = parse_event(event_name, d)

                    # Should parse to SOMETHING — not crash
                    @test event isa AbstractEvent

                    # Ideally not UnknownEvent (means we have a handler)
                    if event isa UnknownEvent
                        @warn "Parsed as UnknownEvent" event_name
                    end

                    i >= 5 && break
                end
            end
        end
    end

end

# ═══════════════════════════════════════════════════════════════════════════════
# REST TYPE PARSING
# ═══════════════════════════════════════════════════════════════════════════════

@testset "REST Type Parsing (real payloads)" begin

    # ── User (@me) ─────────────────────────────────────────────────────────
    @testset "GET /users/@me → User" begin
        if has_fixture("rest_get_me")
            payload = load_fixture_one("rest_get_me")
            user = JSON3.read(JSON3.write(payload), User)
            @test user isa User
            @test user.id isa Snowflake
            @test !isempty(user.username)

            # Bot user should have bot=true
            if !ismissing(user.bot)
                @test user.bot == true
            end

            # Round-trip
            json = JSON3.write(user)
            user2 = JSON3.read(json, User)
            @test user2.id == user.id
        else
            @test_skip "no rest_get_me fixture"
        end
    end

    # ── Guild ──────────────────────────────────────────────────────────────
    @testset "GET /guilds/:id → Guild" begin
        if has_fixture("rest_get_guild")
            payload = load_fixture_one("rest_get_guild")
            guild = JSON3.read(JSON3.write(payload), Guild)
            @test guild isa Guild
            @test guild.id isa Snowflake
            @test !isempty(guild.name)

            # Round-trip
            json = JSON3.write(guild)
            guild2 = JSON3.read(json, Guild)
            @test guild2.id == guild.id
            @test guild2.name == guild.name
        else
            @test_skip "no rest_get_guild fixture"
        end
    end

    # ── Channels ───────────────────────────────────────────────────────────
    @testset "GET /guilds/:id/channels → Vector{DiscordChannel}" begin
        if has_fixture("rest_get_channels")
            payload = load_fixture_one("rest_get_channels")
            items = payload["items"]  # wrapped array
            channels = JSON3.read(JSON3.write(items), Vector{DiscordChannel})
            @test length(channels) >= 1

            for ch in channels
                @test ch isa DiscordChannel
                @test ch.id isa Snowflake
                @test ch.type isa Int
            end

            # Round-trip each channel
            for ch in channels[1:min(3, length(channels))]
                json = JSON3.write(ch)
                ch2 = JSON3.read(json, DiscordChannel)
                @test ch2.id == ch.id
                @test ch2.type == ch.type
            end
        else
            @test_skip "no rest_get_channels fixture"
        end
    end

    # ── Roles ──────────────────────────────────────────────────────────────
    @testset "GET /guilds/:id/roles → Vector{Role}" begin
        if has_fixture("rest_get_roles")
            payload = load_fixture_one("rest_get_roles")
            items = payload["items"]
            roles = JSON3.read(JSON3.write(items), Vector{Role})
            @test length(roles) >= 1  # at least @everyone

            for role in roles
                @test role isa Role
                @test role.id isa Snowflake
                @test !isempty(role.name)
            end
        else
            @test_skip "no rest_get_roles fixture"
        end
    end

    # ── Members ────────────────────────────────────────────────────────────
    @testset "GET /guilds/:id/members → Vector{Member}" begin
        if has_fixture("rest_get_members")
            payload = load_fixture_one("rest_get_members")
            items = payload["items"]
            members = JSON3.read(JSON3.write(items), Vector{Member})
            @test length(members) >= 1

            for m in members
                @test m isa Member
                if !ismissing(m.user)
                    @test m.user isa User
                    @test m.user.id isa Snowflake
                end
            end
        else
            @test_skip "no rest_get_members fixture"
        end
    end

    # ── Channel ────────────────────────────────────────────────────────────
    @testset "GET /channels/:id → DiscordChannel" begin
        if has_fixture("rest_get_channel")
            payload = load_fixture_one("rest_get_channel")
            ch = JSON3.read(JSON3.write(payload), DiscordChannel)
            @test ch isa DiscordChannel
            @test ch.id isa Snowflake
        else
            @test_skip "no rest_get_channel fixture"
        end
    end

    # ── Message ────────────────────────────────────────────────────────────
    @testset "POST /channels/:id/messages → Message" begin
        if has_fixture("rest_create_message")
            payload = load_fixture_one("rest_create_message")
            msg = JSON3.read(JSON3.write(payload), Message)
            @test msg isa Message
            @test msg.id isa Snowflake
            @test msg.channel_id isa Snowflake

            if !ismissing(msg.author)
                @test msg.author isa User
            end
            if !ismissing(msg.content)
                @test msg.content isa String
            end

            # Round-trip
            json = JSON3.write(msg)
            msg2 = JSON3.read(json, Message)
            @test msg2.id == msg.id
        else
            @test_skip "no rest_create_message fixture"
        end
    end

    # ── Gateway Bot ────────────────────────────────────────────────────────
    @testset "GET /gateway/bot response" begin
        if has_fixture("rest_get_gateway_bot")
            payload = load_fixture_one("rest_get_gateway_bot")
            @test haskey(payload, "url")
            @test haskey(payload, "shards")
            @test haskey(payload, "session_start_limit")
            @test startswith(payload["url"], "wss://")
            @test payload["shards"] >= 1

            ssl = payload["session_start_limit"]
            @test haskey(ssl, "total")
            @test haskey(ssl, "remaining")
            @test ssl["total"] >= 1
        else
            @test_skip "no rest_get_gateway_bot fixture"
        end
    end

end

# ═══════════════════════════════════════════════════════════════════════════════
# STRUCTURAL INTEGRITY
# ═══════════════════════════════════════════════════════════════════════════════

@testset "Structural Integrity" begin

    # Verify HELLO payload has expected shape
    @testset "HELLO structure" begin
        if has_fixture("gateway_hello")
            payload = load_fixture_one("gateway_hello")
            @test payload["op"] == 10
            @test haskey(payload, "d")
            @test haskey(payload["d"], "heartbeat_interval")
            @test payload["d"]["heartbeat_interval"] isa Number
            @test payload["d"]["heartbeat_interval"] > 0
        else
            @test_skip "no HELLO fixture"
        end
    end

    # Verify heartbeat ACKs have correct opcode
    @testset "HEARTBEAT_ACK structure" begin
        if has_fixture("gateway_heartbeat_ack")
            payloads = load_fixture("gateway_heartbeat_ack")
            @test length(payloads) >= 1
            for p in payloads
                @test p["op"] == 11
            end
        else
            @test_skip "no HEARTBEAT_ACK fixture"
        end
    end

    # Verify all DISPATCH payloads have required fields
    @testset "DISPATCH payloads have op/s/t/d" begin
        categories = [c for c in manifest["categories"] if startswith(c, "gateway_")]
        skip = Set(["gateway_hello", "gateway_heartbeat_ack", "gateway_reconnect", "gateway_invalid_session"])

        for category in categories
            category in skip && continue
            payloads = load_fixture(category)
            for p in payloads
                @test p["op"] == 0
                @test haskey(p, "s")
                @test haskey(p, "t")
                @test haskey(p, "d")
            end
        end
    end

end
