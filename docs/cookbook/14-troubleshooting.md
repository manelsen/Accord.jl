# Recipe 14 — Troubleshooting

**Difficulty:** All levels
**What you will build:** A reference for diagnosing common errors, gateway issues, and interaction failures.

**Prerequisites:** [Recipe 01](01-basic-bot.md)

---

## 1. Common Error Table

| Error | Cause | Fix |
|-------|-------|-----|
| Gateway close 4004 | Authentication failed | Check your token; ensure `Bot ` prefix |
| Gateway close 4014 | Disallowed intent(s) | Enable privileged intents in Developer Portal |
| HTTP 401 | Invalid token | Regenerate token in Developer Portal |
| HTTP 403 | Missing permissions | Check bot's role permissions in server |
| HTTP 429 | Rate limited | Reduce request rate; Accord.jl handles this automatically |
| HTTP 400 | Bad request body | Check payload format; log the body before sending |
| `content` is empty | Missing `IntentMessageContent` | Enable Message Content intent |
| No message events | Missing `IntentGuildMessages` | Add `IntentGuildMessages` to intents |
| No member events | Missing `IntentGuildMembers` | Enable privileged intent + add to intents |
| Interaction failed | Response took >3 seconds | Use `defer(ctx)` before slow operations |
| "Unknown interaction" | Double response or expired | Don't respond twice; respond within 15 minutes |
| "Interaction already acknowledged" | Called `respond` after `defer` + `respond` | Use `edit_response` after `defer`, not `respond` (note: Accord.jl handles this — `respond` auto-detects deferred state) |

## 2. Debug Logging

Enable debug output from Accord.jl:

```julia
# Before starting the client
ENV["JULIA_DEBUG"] = "Accord"

# Or for everything:
ENV["JULIA_DEBUG"] = "all"
```

### Custom Logging

```julia
using Logging

# Log to file with timestamps
io = open("bot.log", "a")
logger = SimpleLogger(io, Logging.Debug)
global_logger(logger)

# Log all events
on(client, AbstractEvent) do c, event
    @debug "Event received" type=typeof(event) time=time()
end
```

## 3. Gateway Issues

### Gateway Opcodes

| Opcode | Name | Direction |
|--------|------|-----------|
| 0 | Dispatch | Receive |
| 1 | Heartbeat | Send/Receive |
| 2 | Identify | Send |
| 6 | Resume | Send |
| 7 | Reconnect | Receive |
| 9 | Invalid Session | Receive |
| 10 | Hello | Receive |
| 11 | Heartbeat ACK | Receive |

### Gateway Close Codes

| Code | Meaning | Can Resume? |
|------|---------|-------------|
| 4000 | Unknown error | Yes |
| 4001 | Unknown opcode | Yes |
| 4002 | Decode error | Yes |
| 4003 | Not authenticated | No |
| 4004 | Authentication failed | No — check token |
| 4005 | Already authenticated | Yes |
| 4007 | Invalid seq | No — new session |
| 4008 | Rate limited | Yes |
| 4009 | Session timed out | No — new session |
| 4010 | Invalid shard | No — check shard config |
| 4011 | Sharding required | No — enable sharding |
| 4012 | Invalid API version | No — update library |
| 4013 | Invalid intents | No — check intent value |
| 4014 | Disallowed intents | No — enable in portal |

### Resume vs New Session

Accord.jl handles reconnection automatically. If you see frequent reconnects:

```julia
on(client, ResumedEvent) do c, event
    @info "Gateway connection resumed"
end

on(client, ReadyEvent) do c, event
    @info "New gateway session established" guilds=length(event.guilds)
end
```

If you see many `ReadyEvent`s but few `ResumedEvent`s, the bot may be losing its session (network issues, too slow to heartbeat).

## 4. Interaction Failures

### The 3-Second Rule

Discord requires an initial response within 3 seconds. If your handler is slow:

```julia
# BAD: will fail if database is slow
@slash_command client "lookup" "Look up data" function(ctx)
    result = slow_database_query()  # might take 5 seconds
    respond(ctx; content=result)     # TOO LATE — interaction expired
end

# GOOD: defer first
@slash_command client "lookup" "Look up data" function(ctx)
    defer(ctx)                       # immediate acknowledgment
    result = slow_database_query()   # take as long as needed (up to 15 min)
    respond(ctx; content=result)     # edits the deferred response
end
```

### Double Response Errors

```julia
# BAD: responding twice
@slash_command client "test" "Test" function(ctx)
    respond(ctx; content="First")
    respond(ctx; content="Second")   # ERROR: already responded
end

# GOOD: use followup for additional messages
@slash_command client "test" "Test" function(ctx)
    respond(ctx; content="First")
    followup(ctx; content="Second")  # followup works after initial response
end
```


### Component Interaction Response Types

When handling button/select interactions, `respond` auto-selects `UPDATE_MESSAGE` (updates the original message). If you want a new message instead:

```julia
register_component!(tree, "my_btn", function(ctx)
    # This updates the message the button is on:
    respond(ctx; content="Updated!")

    # For a separate ephemeral reply, use followup:
    # defer(ctx)  # acknowledge first
    # followup(ctx; content="Separate reply!", ephemeral=true)
end)
```

## 5. Rate Limit Debugging

Accord.jl handles rate limits automatically, but you can monitor them:

```julia
# Check if you're hitting rate limits frequently
register_middleware!(client.event_handler) do client, event
    if event isa InteractionCreate
        @debug "Interaction received" id=event.interaction.id type=event.interaction.type
    end
    return event
end
```

### Common Rate Limit Scenarios

| Action | Rate Limit | Notes |
|--------|-----------|-------|
| Send messages | 5/5s per channel | Spread across channels |
| Edit messages | 5/5s per channel | Same bucket as send |
| Create reactions | 1/0.25s | Very tight |
| Bulk delete | 1/1s | Max 100 messages |
| Global commands | 200/day | Use guild commands for dev |
| Gateway identify | 1/5s | Respect shard startup delay |

## 6. Voice Connection Debugging

```julia
# Verbose voice connection logging
ENV["JULIA_DEBUG"] = "Accord"

# Check voice states
function debug_voice(client, guild_id)
    vs = get(client.state.voice_states, guild_id, nothing)
    if isnothing(vs)
        @info "No voice states for guild"
        return
    end
    for (uid, state) in vs
        @info "Voice state" user=uid channel=state.channel_id session=state.session_id
    end
end
```

### Common Voice Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `connect!` hangs | Missing `IntentGuildVoiceStates` | Add intent |
| No audio output | Missing ffmpeg | Install ffmpeg |
| "No encryption key" | Session not fully established | Wait longer after connect |
| Audio cuts out | Network jitter | Check server connection |
| Opus encode errors | Wrong PCM format | Ensure 48kHz, 16-bit, stereo |

## 7. REPL-Driven Debugging

Use non-blocking mode to inspect live state:

```julia
start(client; blocking=false)
wait_until_ready(client)

# Inspect client state
client.state.me                          # bot user
client.state.me.username                 # bot username
length(client.state.guilds)              # cached guild count
length(client.state.channels)            # cached channel count

# Check a specific guild
guild = get(client.state.guilds, Snowflake(123456789))
guild.name
guild.owner_id

# Check shard status
for shard in client.shards
    @info "Shard" id=shard.id connected=shard.session.connected
end

# Send a test message
create_message(client, Snowflake(123456789); content="Test from REPL")

# Test an embed
e = embed(title="Debug", description="Testing", color=0xFEE75C)
create_message(client, Snowflake(123456789); embeds=[e])
```

## 8. Checklist for New Bots

1. Token starts with `Bot ` (Accord.jl adds this automatically)
2. Bot is invited with correct permissions (use OAuth2 URL generator)
3. Required intents are enabled in Developer Portal
4. Required intents are passed to `Client()`
5. `IntentMessageContent` is enabled if reading message content
6. `InteractionCreate` handler calls `dispatch_interaction!`
7. `ReadyEvent` handler calls `sync_commands!`
8. Command responses happen within 3 seconds (or use `defer`)
9. `.env` file is in `.gitignore`
10. Error handler is registered with `on_error`

---

**Next steps:** [Recipe 15 — Why Julia?](15-why-julia.md) for the case for building Discord bots in Julia.
