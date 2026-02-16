# Recipe 01 — Your First Bot

**Difficulty:** Beginner
**What you will build:** A Discord bot that responds to messages, measures latency, and runs interactively in the REPL.

---

## 1. Project Setup

```bash
# Create a new project
mkdir MyBot && cd MyBot
julia --project=. -e 'using Pkg; Pkg.add("Accord")'
```

Your `Project.toml` now tracks Accord.jl as a dependency.

## 2. Token Management

!!! tip "Token Security"
    Never commit your Discord token to version control. Create a `.env` file and add it to `.gitignore` immediately.

```env
# .env
DISCORD_TOKEN=Bot MTIzNDU2Nzg5MDEyMzQ1Njc4OQ.XXXXXX.XXXXXXXXXXXXXXXXXXXXXXXX
```

```gitignore
# .gitignore
.env
Manifest.toml
```

Load it in your bot:

```julia
# Load token from environment
function load_env(path=".env")
    isfile(path) || return
    for line in eachline(path)
        stripped = strip(line)
        (isempty(stripped) || startswith(stripped, '#')) && continue
        key, value = split(stripped, '='; limit=2)
        ENV[strip(key)] = strip(value)
    end
end

load_env()
token = ENV["DISCORD_TOKEN"]
```

## 3. Hello World Bot

```julia
using Accord

load_env()  # from above
token = ENV["DISCORD_TOKEN"]

# Create client with specific intents
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)

!!! note "Intents"
    Gateway intents control which events your bot receives. You must declare both [`IntentGuildMessages`](@ref) (for message events) and [`IntentMessageContent`](@ref) (to read actual message text). Without these, your bot won't see message content!

# Log when connected
on(client, [`ReadyEvent`](@ref)) do c, event
    @info "Bot online!" user=event.user.username guilds=length(event.guilds)
end

# Respond to messages
on(client, [`MessageCreate`](@ref)) do c, event
    msg = event.message
    ismissing(msg.author) && return
    ismissing(msg.content) && return
    !ismissing(msg.author.bot) && msg.author.bot == true && return

    if msg.content == "!hello"
        create_message(c, msg.channel_id; content="Hello from Accord.jl!")
    end
end

start(client)
```

Run it:

```bash
julia --project=. bot.jl
```

## 4. Ping/Pong with Latency

```julia
on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.author) && return
    ismissing(msg.content) && return
    !ismissing(msg.author.bot) && msg.author.bot == true && return

    if msg.content == "!ping"
        t_start = time()
        sent = create_message(c, msg.channel_id; content="Pong!")
        latency_ms = round(Int, (time() - t_start) * 1000)

        e = embed(
            title="Pong!",
            description="Round-trip latency: **$(latency_ms) ms**",
            color=0x57F287  # green
        )
        edit_message(c, msg.channel_id, sent.id; embeds=[e])
    end
end
```

## 5. Understanding Intents

Intents control which events your bot receives. Combine them with `|`:

```julia
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)
```

### Intent Reference

| Intent | Bit | Privileged | Events |
|--------|-----|------------|--------|
| [`IntentGuilds`](@ref) | 0 | No | GuildCreate, GuildUpdate, GuildDelete, channels, roles |
| [`IntentGuildMembers`](@ref) | 1 | **Yes** | GuildMemberAdd/Remove/Update |
| [`IntentGuildModeration`](@ref) | 2 | No | GuildBanAdd/Remove, GuildAuditLogEntryCreate |
| [`IntentGuildExpressions`](@ref) | 3 | No | GuildEmojisUpdate, GuildStickersUpdate |
| [`IntentGuildIntegrations`](@ref) | 4 | No | IntegrationCreate/Update/Delete |
| [`IntentGuildWebhooks`](@ref) | 5 | No | WebhooksUpdate |
| [`IntentGuildInvites`](@ref) | 6 | No | InviteCreate/Delete |
| [`IntentGuildVoiceStates`](@ref) | 7 | No | VoiceStateUpdateEvent |
| [`IntentGuildPresences`](@ref) | 8 | **Yes** | PresenceUpdate |
| [`IntentGuildMessages`](@ref) | 9 | No | MessageCreate/Update/Delete in guilds |
| [`IntentGuildMessageReactions`](@ref) | 10 | No | MessageReactionAdd/Remove |
| [`IntentGuildMessageTyping`](@ref) | 11 | No | TypingStart |
| [`IntentDirectMessages`](@ref) | 12 | No | MessageCreate/Update/Delete in DMs |
| [`IntentDirectMessageReactions`](@ref) | 13 | No | MessageReactionAdd/Remove in DMs |
| [`IntentDirectMessageTyping`](@ref) | 14 | No | TypingStart in DMs |
| [`IntentMessageContent`](@ref) | 15 | **Yes** | Populates `message.content`, `embeds`, `attachments` |
| [`IntentGuildScheduledEvents`](@ref) | 16 | No | ScheduledEvent events |
| [`IntentAutoModerationConfiguration`](@ref) | 20 | No | AutoModerationRuleCreate/Update/Delete |
| [`IntentAutoModerationExecution`](@ref) | 21 | No | AutoModerationActionExecution |
| [`IntentGuildMessagePolls`](@ref) | 24 | No | MessagePollVoteAdd/Remove |
| [`IntentDirectMessagePolls`](@ref) | 25 | No | MessagePollVoteAdd/Remove in DMs |

Privileged intents must be enabled in the Discord Developer Portal under **Bot > Privileged Gateway Intents**.

!!! warning "MESSAGE_CONTENT Intent Required"
    As of 2022, Discord requires the privileged [`IntentMessageContent`](@ref) intent to receive message content. Without this intent, `message.content` will be empty or missing. You must enable this in the Developer Portal AND pass it in the [`Client`](@ref) constructor.

Shortcuts:

[`IntentAllNonPrivileged`](@ref) and [`IntentAll`](@ref):

```julia
IntentAllNonPrivileged  # all non-privileged intents (default)
IntentAll               # all intents including privileged
```

## 6. Non-Blocking Mode (REPL Development)

Start the bot without blocking your REPL:

```julia
start(client; blocking=false)

# Now you can interact with the client live:
wait_until_ready(client)
@info "Bot user: $(client.state.me.username)"

# Send a message from the REPL
create_message(client, [`Snowflake`](@ref)(123456789); content="Hello from the REPL!")

# Inspect cached state
@info "Guilds cached: $(length(client.state.guilds))"
```

This is extremely useful during development — you get a live REPL connected to Discord.

## 7. Graceful Shutdown

```julia
# Stop the client cleanly
stop(client)
```

In blocking mode, pressing `Ctrl+C` triggers a graceful shutdown automatically.

## 8. Handling Multiple Events

You can register multiple handlers for the same event:

```julia
# Analytics handler
on(client, [`MessageCreate`](@ref)) do c, event
    @debug "Message received" channel=event.message.channel_id
end

# Command handler (both run independently)
on(client, [`MessageCreate`](@ref)) do c, event
    msg = event.message
    ismissing(msg.content) && return
    msg.content == "!ping" && create_message(c, msg.channel_id; content="Pong!")
end

# Catch-all: log every event type
on(client, [`AbstractEvent`](@ref)) do c, event
    @debug "Event" type=typeof(event)
end
```

## 9. Logging Guild Activity

```julia
on(client, [`GuildCreate`](@ref)) do c, event
    @info "Guild available" name=event.guild.name id=event.guild.id
end

on(client, [`GuildMemberAdd`](@ref)) do c, event
    @info "Member joined" guild_id=event.guild_id
    # Note: requires IntentGuildMembers (privileged)
end
```

---

## Complete Example

```julia
using Accord

# Load token
token = get(ENV, "DISCORD_TOKEN", "")
isempty(token) && error("Set DISCORD_TOKEN environment variable")

client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)

on(client, ReadyEvent) do c, event
    @info "Bot online!" user=event.user.username guilds=length(event.guilds)
end

on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.author) && return
    ismissing(msg.content) && return
    !ismissing(msg.author.bot) && msg.author.bot == true && return

    if msg.content == "!ping"
        t = time()
        sent = create_message(c, msg.channel_id; content="Pinging...")
        ms = round(Int, (time() - t) * 1000)
        edit_message(c, msg.channel_id, sent.id;
            content="Pong! Latency: **$(ms) ms**")
    elseif msg.content == "!info"
        e = embed(
            title="Bot Info",
            color=0x5865F2,
            fields=[
                Dict("name" => "Library", "value" => "Accord.jl", "inline" => true),
                Dict("name" => "Julia", "value" => string(VERSION), "inline" => true),
            ]
        )
        create_message(c, msg.channel_id; embeds=[e])
    end
end

on(client, GuildCreate) do c, event
    @info "Guild available" name=event.guild.name id=event.guild.id
end

@info "Starting bot..."
start(client)
```

---

**Next steps:** [Recipe 02 — Rich Messages](02-messages-and-embeds.md) to learn about embeds, reactions, and file attachments.
