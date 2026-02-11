# Recipe 11 — Architectural Patterns

**Difficulty:** Intermediate
**What you will build:** Production project structure with modular commands, middleware, error handling, config management, and database integration.

**Prerequisites:** [Recipe 03](03-slash-commands.md), [Recipe 04](04-buttons-selects-modals.md)

---

## 1. Production Project Structure

```text
MyBot/
├── Project.toml
├── Manifest.toml
├── .env                    # tokens (never commit)
├── .gitignore
├── config.toml             # bot configuration
├── src/
│   ├── MyBot.jl            # main module
│   ├── commands/
│   │   ├── general.jl      # /ping, /help, /info
│   │   ├── moderation.jl   # /ban, /kick, /warn
│   │   └── fun.jl          # /poll, /roll, /quote
│   ├── handlers/
│   │   ├── messages.jl     # MessageCreate handlers
│   │   └── members.jl      # GuildMemberAdd/Remove handlers
│   ├── services/
│   │   ├── database.jl     # database access layer
│   │   └── api.jl          # external API clients
│   └── utils/
│       ├── config.jl       # config loading
│       ├── embeds.jl       # embed templates
│       └── checks.jl       # permission checks
├── bin/
│   └── run.jl              # entry point
└── test/
    └── runtests.jl
```

## 2. Main Module Pattern

```julia
# src/MyBot.jl
module MyBot

using Accord
using Dates

# Configuration
include("utils/config.jl")

# Utilities
include("utils/embeds.jl")
include("utils/checks.jl")

# Services
include("services/database.jl")

# Commands
include("commands/general.jl")
include("commands/moderation.jl")
include("commands/fun.jl")

# Event handlers
include("handlers/messages.jl")
include("handlers/members.jl")

# Bot setup
function create_bot(config)
    client = Client(config["token"];
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent | IntentGuildMembers,
        user_strategy = CacheLRU(config["cache"]["max_users"]),
    )

    # Register all commands (macros will register them to client.command_tree)
    register_general_commands!(client, config)
    register_moderation_commands!(client, config)
    register_fun_commands!(client, config)

    # Register event handlers
    register_message_handlers!(client, config)
    register_member_handlers!(client, config)

    # Sync commands on ready
    on(client, ReadyEvent) do c, event
        sync_commands!(c, c.command_tree; guild_id=get(config, "dev_guild_id", nothing))
        @info "Bot ready!" user=event.user.username
    end

    # Note: Client automatically routes interactions to c.command_tree

    return client
end

end # module
```

## 3. Modular Command Registration

```julia
# src/commands/general.jl

function register_general_commands!(client, config)

    @slash_command client "ping" "Check bot latency" function(ctx)
        t = time()
        defer(ctx)
        ms = round(Int, (time() - t) * 1000)
        e = embed(title="Pong!", description="Latency: **$(ms) ms**", color=0x57F287)
        respond(ctx; embeds=[e])
    end

    @slash_command client "info" "Bot information" function(ctx)
        guilds = length(ctx.client.state.guilds)
        e = embed(
            title="Bot Info",
            color=0x5865F2,
            fields=[
                Dict("name" => "Guilds", "value" => string(guilds), "inline" => true),
                Dict("name" => "Julia", "value" => string(VERSION), "inline" => true),
                Dict("name" => "Accord.jl", "value" => string(Accord.ACCORD_VERSION), "inline" => true),
            ]
        )
        respond(ctx; embeds=[e])
    end

end
```

```julia
# src/commands/moderation.jl

function register_moderation_commands!(client, config)

    options = [
        command_option(type=ApplicationCommandOptionTypes.USER, name="user", description="User to kick", required=true),
        command_option(type=ApplicationCommandOptionTypes.STRING, name="reason", description="Reason for kick"),
    ]

    @slash_command client "kick" "Kick a member" options function(ctx)
        require_mod(ctx) || return

        target = Snowflake(get_option(ctx, "user", ""))
        reason = get_option(ctx, "reason", "No reason")

        remove_guild_member(ctx.client.ratelimiter, ctx.interaction.guild_id, target;
            token=ctx.client.token, reason=reason)

        respond(ctx; content="Kicked <@$(target)>. Reason: $reason")
    end

end
```

## 4. Error Handling

### Global Error Handler

```julia
on_error(client) do c, event, error
    # Log the error with full context
    @error "Handler error" event_type=typeof(event) exception=(error, catch_backtrace())

    # Optionally notify a channel
    ERROR_CHANNEL = Snowflake(config["error_channel_id"])
    try
        e = embed(
            title="Bot Error",
            description="```\n$(sprint(showerror, error))\n```",
            color=0xED4245,
            fields=[
                Dict("name" => "Event", "value" => string(typeof(event))),
            ],
            footer=Dict("text" => string(now())),
        )
        create_message(c, ERROR_CHANNEL; embeds=[e])
    catch
        # Don't let error reporting errors crash the bot
    end
end
```

### Per-Handler Try-Catch

```julia
@slash_command client "risky" "A command that might fail" function(ctx)
    try
        result = some_external_api_call()
        respond(ctx; content="Result: $result")
    catch e
        @error "Command failed" exception=e
        respond(ctx; content="Something went wrong. Please try again later.", ephemeral=true)
    end
end
```

### Structured Logging

```julia
using Logging

# Set up logging with timestamps
logger = ConsoleLogger(stderr, Logging.Info)
global_logger(logger)

# Enable debug logging for Accord
ENV["JULIA_DEBUG"] = "Accord"
```

## 5. Middleware

Middleware runs before every event handler. Return the event to continue, `nothing` to cancel.

```julia
# Logging middleware
register_middleware!(client.event_handler) do client, event
    @debug "Event received" type=typeof(event)
    return event  # pass through
end

# Ignore list middleware
const IGNORED_USERS = Set{Snowflake}()

register_middleware!(client.event_handler) do client, event
    if event isa MessageCreate
        user_id = ismissing(event.message.author) ? nothing : event.message.author.id
        if !isnothing(user_id) && user_id in IGNORED_USERS
            return nothing  # cancel event
        end
    end
    return event
end

# Rate limiting middleware
const user_cooldowns = Dict{Snowflake, Float64}()
const COOLDOWN_SECONDS = 2.0

register_middleware!(client.event_handler) do client, event
    if event isa InteractionCreate
        user_id = event.interaction.member.user.id
        last_use = get(user_cooldowns, user_id, 0.0)
        if time() - last_use < COOLDOWN_SECONDS
            return nothing  # too fast, ignore
        end
        user_cooldowns[user_id] = time()
    end
    return event
end
```

## 6. Configuration with TOML

```toml
# config.toml
[bot]
prefix = "!"
dev_guild_id = "123456789012345678"
error_channel_id = "987654321098765432"

[cache]
max_users = 50000
max_members = 50000

[features]
enable_logging = true
enable_moderation = true
enable_fun = true
```

```julia
# src/utils/config.jl
import TOML

function load_config(path="config.toml")
    config = TOML.parsefile(path)

    # Merge with env vars (env takes precedence)
    config["token"] = ENV["DISCORD_TOKEN"]

    return config
end
```

## 7. Entry Point

```julia
# bin/run.jl
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Load .env
for line in eachline(".env")
    stripped = strip(line)
    (isempty(stripped) || startswith(stripped, '#')) && continue
    key, value = split(stripped, '='; limit=2)
    ENV[strip(key)] = strip(value)
end

using MyBot

config = MyBot.load_config()
client = MyBot.create_bot(config)

@info "Starting bot..."
start(client)
```

## 8. Database Integration Pattern

```julia
# src/services/database.jl
import SQLite

const db = Ref{SQLite.DB}()

function init_db(path="bot.db")
    db[] = SQLite.DB(path)

    SQLite.execute(db[], """
        CREATE TABLE IF NOT EXISTS warnings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            moderator_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
end

function add_warning(guild_id, user_id, moderator_id, reason)
    SQLite.execute(db[], """
        INSERT INTO warnings (guild_id, user_id, moderator_id, reason, created_at)
        VALUES (?, ?, ?, ?, ?)
    """, [string(guild_id), string(user_id), string(moderator_id), reason, string(now())])
end

function get_warnings(guild_id, user_id)
    SQLite.DBInterface.execute(db[], """
        SELECT * FROM warnings WHERE guild_id = ? AND user_id = ? ORDER BY created_at DESC
    """, [string(guild_id), string(user_id)]) |> collect
end
```

## 9. Idiomatic Julia Patterns

### Multiple Dispatch for Event Routing

```julia
# Julia's type system naturally routes events
function handle_event(client, event::GuildMemberAdd)
    @info "Welcome!" user=event.member.user.username
end

function handle_event(client, event::GuildMemberRemove)
    @info "Goodbye!" user=event.user.username
end

function handle_event(client, event::AbstractEvent)
    # fallback — nothing
end
```

### Type-Stable Option Extraction

```julia
# Annotate types when extracting options
function handle_greet(ctx)
    name = get_option(ctx, "name", "World")::String
    times = get_option(ctx, "times", 1)::Int
    respond(ctx; content=join(fill("Hello, $name!", times), "\n"))
end
```

### Avoid Global Mutable State

```julia
# Instead of global Dicts, pass state through closures or structs

struct BotState
    warnings::Dict{Snowflake, Vector{String}}
    config::Dict{String, Any}
end

function register_commands!(client, state::BotState)
    @slash_command client "warn" "Warn a user" function(ctx)
        # state is captured by closure, not global
        warns = get!(state.warnings, ctx.interaction.guild_id, String[])
        push!(warns, "warning")
        respond(ctx; content="Warning recorded ($(length(warns)) total)")
    end
end
```

---

**Next steps:** [Recipe 12 — Performance](12-performance.md) for Julia-specific optimizations.
