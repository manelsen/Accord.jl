#=
Discord Gateway & REST Payload Capture Script

Connects to Discord, captures real payloads, and saves them as JSON fixtures
for integration testing. No Accord.jl dependency — uses raw HTTP + JSON3.

Usage:
    DISCORD_TOKEN="Bot YOUR_TOKEN" julia scripts/capture_payloads.jl

Optional env vars:
    CAPTURE_DURATION   — seconds to stay connected (default: 30)
    TEST_CHANNEL_ID    — channel to send a test message to (enables REST capture)
    TEST_GUILD_ID      — guild for REST endpoint tests
    SANITIZE_FIXTURES  — sanitize payloads before writing fixtures (default: true)
=#

using HTTP
using JSON3
using Dates
include(joinpath(@__DIR__, "sanitize_fixtures.jl"))

# ─── Config ──────────────────────────────────────────────────────────────────

const _raw_token = get(ENV, "DISCORD_TOKEN", "")
const TOKEN = startswith(_raw_token, "Bot ") ? _raw_token : "Bot $_raw_token"
const DURATION = parse(Int, get(ENV, "CAPTURE_DURATION", "30"))
const TEST_CHANNEL = get(ENV, "TEST_CHANNEL_ID", "")
const TEST_GUILD = get(ENV, "TEST_GUILD_ID", "")
const SANITIZE_FIXTURES = lowercase(get(ENV, "SANITIZE_FIXTURES", "true")) in ("1", "true", "yes", "on")

const API_BASE = "https://discord.com/api/v10"
const GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"
const FIXTURES_DIR = joinpath(@__DIR__, "..", "test", "integration", "fixtures")

# Intents: guilds + members + voice + guild messages + reactions + content + auto mod
const INTENTS = UInt32(1 << 0 | 1 << 1 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 15 | 1 << 20 | 1 << 21)

isempty(TOKEN) && error("Set DISCORD_TOKEN env var (e.g. 'Bot your_token_here')")

# ─── Fixtures storage ────────────────────────────────────────────────────────

mkpath(FIXTURES_DIR)

const captured = Dict{String, Vector{Dict{String,Any}}}()
const capture_lock = ReentrantLock()

function save_payload!(category::String, payload::Dict{String,Any})
    lock(capture_lock) do
        payloads = get!(captured, category, Dict{String,Any}[])
        push!(payloads, payload)
    end
end

function flush_fixtures()
    sanitizer_state = SANITIZE_FIXTURES ? SanitizerState() : nothing

    lock(capture_lock) do
        for (category, payloads) in captured
            payloads_to_write = payloads
            if SANITIZE_FIXTURES
                # Deep copy before sanitizing, so in-memory captured payloads remain untouched.
                payloads_to_write = sanitize_any!(sanitizer_state, JSON3.read(JSON3.write(payloads), Any))
            end
            path = joinpath(FIXTURES_DIR, "$(category).json")
            open(path, "w") do io
                JSON3.pretty(io, payloads_to_write)
            end
            @info "Saved $(length(payloads)) payload(s)" category path
        end
    end

    # Write a manifest
    manifest = Dict(
        "captured_at" => string(now()),
        "duration_seconds" => DURATION,
        "sanitized" => SANITIZE_FIXTURES,
        "categories" => sort(collect(keys(captured))),
        "counts" => Dict(k => length(v) for (k, v) in captured),
    )
    if SANITIZE_FIXTURES
        manifest["sanitized_at"] = Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS")
    end
    open(joinpath(FIXTURES_DIR, "_manifest.json"), "w") do io
        JSON3.pretty(io, manifest)
    end
end

# ─── REST capture ────────────────────────────────────────────────────────────

const REST_HEADERS = [
    "Authorization" => TOKEN,
    "User-Agent" => "Accord.jl PayloadCapture",
    "Content-Type" => "application/json",
]

function rest_get(path::String)
    resp = HTTP.get("$(API_BASE)$(path)", REST_HEADERS; status_exception=false)
    body = String(resp.body)
    # Some endpoints return arrays, others return objects
    payload = if startswith(lstrip(body), '[')
        JSON3.read(body, Vector{Any})
    else
        JSON3.read(body, Dict{String,Any})
    end
    return resp.status, payload
end

function rest_post(path::String, body::Dict)
    resp = HTTP.post("$(API_BASE)$(path)", REST_HEADERS, JSON3.write(body); status_exception=false)
    payload = JSON3.read(resp.body, Dict{String,Any})
    return resp.status, payload
end

function rest_delete(path::String)
    resp = HTTP.delete("$(API_BASE)$(path)", REST_HEADERS; status_exception=false)
    if !isempty(resp.body)
        return resp.status, JSON3.read(resp.body, Dict{String,Any})
    end
    return resp.status, Dict{String,Any}()
end

function capture_rest_payloads()
    @info "Capturing REST payloads..."

    # GET /users/@me — always works
    status, payload = rest_get("/users/@me")
    if status == 200
        save_payload!("rest_get_me", payload)
        @info "  GET /users/@me" status
    else
        @warn "  GET /users/@me failed" status
    end

    # GET /gateway/bot
    status, payload = rest_get("/gateway/bot")
    if status == 200
        save_payload!("rest_get_gateway_bot", payload)
        @info "  GET /gateway/bot" status
    else
        @warn "  GET /gateway/bot failed" status
    end

    # Guild-specific endpoints
    if !isempty(TEST_GUILD)
        gid = TEST_GUILD

        for (name, path) in [
            ("rest_get_guild",    "/guilds/$gid"),
            ("rest_get_channels", "/guilds/$gid/channels"),
            ("rest_get_roles",    "/guilds/$gid/roles"),
            ("rest_get_emojis",   "/guilds/$gid/emojis"),
            ("rest_get_members",  "/guilds/$gid/members?limit=10"),
        ]
            status, payload = rest_get(path)
            if status == 200
                if payload isa Vector || payload isa AbstractVector
                    # Array response — wrap it
                    save_payload!(name, Dict{String,Any}("items" => payload))
                else
                    save_payload!(name, payload)
                end
                @info "  GET $path" status
            else
                @warn "  GET $path failed" status
            end
        end
    end

    # Channel-specific: send and delete a test message
    if !isempty(TEST_CHANNEL)
        cid = TEST_CHANNEL

        # GET channel
        status, payload = rest_get("/channels/$cid")
        if status == 200
            save_payload!("rest_get_channel", payload)
            @info "  GET /channels/$cid" status
        end

        # POST message
        body = Dict("content" => "[Accord.jl integration test — this message will be deleted]")
        status, payload = rest_post("/channels/$cid/messages", body)
        if status == 200
            save_payload!("rest_create_message", payload)
            msg_id = payload["id"]
            @info "  POST /channels/$cid/messages" status msg_id

            # Small delay then delete
            sleep(1.0)
            del_status, _ = rest_delete("/channels/$cid/messages/$msg_id")
            @info "  DELETE message" del_status msg_id
        else
            @warn "  POST message failed" status
        end
    end
end

# ─── Gateway capture ─────────────────────────────────────────────────────────

const OPCODE_NAMES = Dict(
    0 => "DISPATCH", 1 => "HEARTBEAT", 2 => "IDENTIFY",
    7 => "RECONNECT", 9 => "INVALID_SESSION", 10 => "HELLO",
    11 => "HEARTBEAT_ACK",
)

function capture_gateway_payloads()
    @info "Connecting to gateway for $(DURATION)s..."
    seq = Ref{Union{Int,Nothing}}(nothing)
    deadline = time() + DURATION

    HTTP.WebSockets.open(GATEWAY_URL; readtimeout=0) do ws
        heartbeat_task = nothing

        while time() < deadline
            data = try
                HTTP.WebSockets.receive(ws)
            catch e
                @warn "WebSocket receive error" exception=e
                break
            end
            isnothing(data) && break

            msg = JSON3.read(data isa Vector{UInt8} ? String(data) : data, Dict{String,Any})

            op = msg["op"]
            d = get(msg, "d", nothing)
            s = get(msg, "s", nothing)
            t = get(msg, "t", nothing)
            opname = get(OPCODE_NAMES, op, "UNKNOWN($op)")

            # Update sequence
            if !isnothing(s)
                seq[] = s
            end

            # ── HELLO: start heartbeat + identify ──
            if op == 10
                interval_ms = d["heartbeat_interval"]
                save_payload!("gateway_hello", msg)
                @info "  HELLO" interval_ms

                # Heartbeat task
                heartbeat_task = @async begin
                    sleep(interval_ms / 1000.0 * rand())  # jitter
                    while time() < deadline
                        hb = isnothing(seq[]) ? """{"op":1,"d":null}""" : """{"op":1,"d":$(seq[])}"""
                        try
                            HTTP.WebSockets.send(ws, hb)
                        catch
                            break
                        end
                        sleep(interval_ms / 1000.0)
                    end
                end

                # Identify
                identify = Dict(
                    "op" => 2,
                    "d" => Dict(
                        "token" => TOKEN,
                        "intents" => INTENTS,
                        "properties" => Dict(
                            "os" => string(Sys.KERNEL),
                            "browser" => "Accord.jl",
                            "device" => "Accord.jl",
                        ),
                        "shard" => [0, 1],
                    )
                )
                HTTP.WebSockets.send(ws, JSON3.write(identify))

            # ── DISPATCH: the main payloads we want ──
            elseif op == 0
                event_name = something(t, "UNKNOWN")
                category = "gateway_$(lowercase(event_name))"
                save_payload!(category, msg)
                @info "  DISPATCH" event=event_name seq=s

            # ── HEARTBEAT_ACK ──
            elseif op == 11
                save_payload!("gateway_heartbeat_ack", msg)

            # ── HEARTBEAT request from server ──
            elseif op == 1
                hb = isnothing(seq[]) ? """{"op":1,"d":null}""" : """{"op":1,"d":$(seq[])}"""
                HTTP.WebSockets.send(ws, hb)

            # ── RECONNECT / INVALID_SESSION ──
            elseif op == 7 || op == 9
                save_payload!("gateway_$(lowercase(opname))", msg)
                @warn "  $opname — ending capture"
                break
            end
        end

        @info "Capture window ended, closing WebSocket"
        # Graceful close — send close frame
        try
            HTTP.WebSockets.send(ws, HTTP.WebSockets.CloseFrameBody(1000, ""))
        catch; end
    end
end

# ─── Main ────────────────────────────────────────────────────────────────────

function main()
    @info "Accord.jl Payload Capture" token_prefix=TOKEN[1:min(10,length(TOKEN))]*"..." duration=DURATION sanitize=SANITIZE_FIXTURES
    !SANITIZE_FIXTURES && @warn "Fixture sanitization is disabled; captured payloads may contain sensitive data."

    # REST first (doesn't need WebSocket)
    capture_rest_payloads()

    # Gateway
    capture_gateway_payloads()

    # Flush everything
    flush_fixtures()

    @info "Done! Fixtures saved to $FIXTURES_DIR"
    @info "Categories captured: $(sort(collect(keys(captured))))"
end

main()
