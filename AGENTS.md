# AGENTS.md — Accord.jl

> Codebase orientation for humans and AI agents working on this project.

## Overview

**Accord.jl** is a Discord API v10 library for Julia 1.10+. It provides a complete bot framework: typed Discord structs, gateway WebSocket with zlib-stream compression, REST with per-bucket rate limiting, slash commands with macro-based DSL, interactive components (buttons, selects, modals), voice with Opus/libsodium encryption, and pluggable caching.

- **Version**: 0.1.0
- **License**: MIT
- **Min Julia**: 1.10
- **Discord API**: v10

---

## Project Structure

```
Accord.jl/
├── src/
│   ├── Accord.jl              # Module entry point, constants, includes, exports
│   ├── types/                  # Discord API data structures (27 files)
│   │   ├── macros.jl           #   @discord_struct, @discord_flags macros
│   │   ├── snowflake.jl        #   Snowflake ID type (UInt64 wrapper)
│   │   ├── enums.jl            #   Module-based enum constants (~25 groups)
│   │   ├── flags.jl            #   Bitfield types: Intents, Permissions, MessageFlags
│   │   ├── user.jl             #   User struct
│   │   ├── guild.jl            #   Guild, UnavailableGuild
│   │   ├── channel.jl          #   DiscordChannel, ThreadMetadata
│   │   ├── message.jl          #   Message, MessageReference
│   │   ├── member.jl           #   Member (guild member)
│   │   ├── role.jl             #   Role
│   │   ├── embed.jl            #   Embed, EmbedField, EmbedFooter, EmbedAuthor, etc.
│   │   ├── interaction.jl      #   Interaction, InteractionData, ApplicationCommand
│   │   ├── component.jl        #   Component, SelectOption
│   │   └── ...                 #   attachment, reaction, sticker, emoji, invite,
│   │                           #   webhook, audit_log, automod, poll, voice,
│   │                           #   presence, scheduled_event, ban, overwrite,
│   │                           #   connection, integration, stage_instance,
│   │                           #   soundboard, sku, onboarding
│   ├── gateway/                # WebSocket connection to Discord gateway
│   │   ├── opcodes.jl          #   GatewayOpcodes, GatewayCloseCodes, VoiceOpcodes
│   │   ├── events.jl           #   ~50 event types (AbstractEvent hierarchy)
│   │   ├── dispatch.jl         #   parse_event(), _construct_event() per type
│   │   ├── connection.jl       #   GatewaySession, gateway_connect() main loop
│   │   ├── heartbeat.jl        #   HeartbeatState, start_heartbeat!()
│   │   └── shard.jl            #   ShardInfo, multi-shard support
│   ├── rest/                   # HTTP client for Discord REST API
│   │   ├── route.jl            #   Route struct, bucket key generation, url()
│   │   ├── ratelimiter.jl      #   BucketState, RateLimiter actor (async Task)
│   │   ├── http_client.jl      #   discord_request(), discord_get/post/put/patch/delete
│   │   └── endpoints/          #   16 files, one per resource type
│   │       ├── guild.jl        #     ~25 guild operations
│   │       ├── channel.jl      #     channel CRUD, threads, typing
│   │       ├── message.jl      #     message CRUD, reactions, polls
│   │       ├── interaction.jl  #     interaction responses, followups
│   │       ├── user.jl         #     user endpoints, DM creation
│   │       └── ...             #     webhook, emoji, sticker, invite, audit_log,
│   │                           #     automod, scheduled_event, stage_instance,
│   │                           #     soundboard, sku, voice, onboarding
│   ├── client/                 # High-level bot client
│   │   ├── state.jl            #   CacheStrategy (Forever/Never/LRU/TTL), Store{T}, State
│   │   ├── event_handler.jl    #   EventHandler, middleware, dispatch_event!()
│   │   └── client.jl           #   Client struct, on(), start(), stop(), wait_for()
│   ├── interactions/           # Slash commands, components, modals
│   │   ├── command_tree.jl     #   CommandTree, CommandDefinition, sync_commands!()
│   │   ├── context.jl          #   InteractionContext, respond(), defer(), followup()
│   │   ├── checks.jl           #   @check, has_permissions(), is_owner(), run_checks()
│   │   ├── decorators.jl       #   @slash_command, @button_handler, @select_handler,
│   │   │                       #   @modal_handler, @autocomplete, @on_message, @option
│   │   └── components.jl       #   Builder functions: action_row(), button(), embed(), etc.
│   ├── voice/                  # Voice channel support
│   │   ├── client.jl           #   VoiceClient, connect!(), disconnect!()
│   │   ├── connection.jl       #   Voice gateway WebSocket, IP discovery
│   │   ├── player.jl           #   AudioPlayer, play!(), stop!(), pause!(), resume!()
│   │   ├── sources.jl          #   PCMSource, FileSource, FFmpegSource, SilenceSource
│   │   ├── opus.jl             #   OpusEncoder/Decoder (via Opus_jll)
│   │   ├── encryption.jl       #   XChaCha20-Poly1305, XSalsa20-Poly1305 (via libsodium)
│   │   └── udp.jl              #   UDP socket, RTP packet framing
│   └── utils/
│       └── permissions.jl      #   compute_base_permissions(), compute_channel_permissions()
├── test/
│   ├── runtests.jl             # Test runner (includes all unit test files)
│   └── unit/                   # 8 test files
│       ├── test_snowflake.jl
│       ├── test_flags.jl
│       ├── test_types.jl
│       ├── test_permissions.jl
│       ├── test_ratelimiter.jl
│       ├── test_components.jl
│       ├── test_macros.jl
│       └── test_checks_waitfor.jl
├── docs/
│   ├── API.md                  # Full API reference (~40 sections)
│   └── cookbook/                # 17 practical guides (01-basic-bot through 16-ai-agent)
│       └── index.md
├── Project.toml                # Package metadata, dependencies, compat
├── KANBAN.md                   # Development progress tracker
├── README.md                   # Project overview and quick start
└── .github/workflows/ci.yml   # CI: Julia 1.10 + latest, ubuntu-latest
```

---

## Architecture

### Include Order Matters

`src/Accord.jl` includes files in strict dependency order. The sequence is:

1. **Types**: macros → snowflake → enums → flags → base types → dependent types → complex types
2. **Gateway**: opcodes → events → heartbeat → dispatch → connection → shard
3. **REST**: route → ratelimiter → http_client → endpoints/*
4. **Interactions (partial)**: command_tree (needed by Client)
5. **Client**: state → event_handler → client
6. **Interactions (rest)**: context → checks → decorators → components
7. **Voice**: encryption → opus → udp → player → sources → connection → client
8. **Utils**: permissions

When adding new files, respect this order. Types referenced in a file must already be defined by a prior `include()`.

### Key Patterns

**`@discord_struct` macro** (`src/types/macros.jl`): Generates mutable structs with `Base.@kwdef`, automatic defaults for `Optional{T}` (→ `missing`), `Nullable{T}` (→ `nothing`), `Vector{T}` (→ empty), and primitive types. All structs get `StructTypes.Mutable()` and `StructTypes.omitempties` for JSON3 serialization.

**`@discord_flags` macro** (`src/types/flags.jl`): Generates bitfield types with `|`, `&`, `~`, `xor` operators and `has_flag()` predicate.

**Module-based enums** (`src/types/enums.jl`): Discord enums are implemented as modules with `const` integer values (not Julia `@enum`). Access as `ChannelTypes.GUILD_TEXT`, `InteractionTypes.APPLICATION_COMMAND`, etc.

**Actor-model rate limiter** (`src/rest/ratelimiter.jl`): A standalone async `Task` that processes queued `RestJob`s, respecting per-bucket and global rate limits. REST calls go through `submit_rest()` → queue → rate limiter processes and returns via `Channel`.

**Pluggable cache** (`src/client/state.jl`): `CacheStrategy` subtypes — `CacheForever`, `CacheNever`, `CacheLRU(maxsize)`, `CacheTTL(ttl)`. The `State` struct holds typed `Store{T}` caches for guilds, channels, users, members, presences, roles.

**Multiple dispatch for events**: All gateway events inherit from `AbstractEvent`. Register handlers with `on(client, EventType) do ... end`. The `dispatch.jl` file maps raw JSON event names to typed structs.

**Macro DSL for interactions** (`src/interactions/decorators.jl`): `@slash_command`, `@button_handler`, `@select_handler`, `@modal_handler`, `@autocomplete`, `@on_message`, `@option`, `@check`. These are the primary user-facing API for bot development.

**Check system** (`src/interactions/checks.jl`): `@check` macros accumulate in a thread-safe `_PENDING_CHECKS` vector and are drained by the next `@slash_command` invocation. Built-in checks: `has_permissions(perms...)`, `is_owner()`, `is_in_guild()`.

**State injection**: Users pass custom state via `Client(token; state=(db=conn, config=cfg))`. Handlers access it through `ctx.state` (backed by a custom `getproperty` on `InteractionContext`).

**`wait_for`**: Wait for the next matching event with timeout and predicate, using Julia `Channel`s internally. Useful for conversational command flows.

---

## Type System Conventions

- `Optional{T}` = `Union{T, Missing}` — field may be absent in API response. Default: `missing`. Check with `ismissing()`.
- `Nullable{T}` = `Union{T, Nothing}` — field is present but may be null. Default: `nothing`. Check with `isnothing()`.
- `Snowflake` = `UInt64` wrapper for Discord IDs. Construct from string or integer: `Snowflake("123456")`, `Snowflake(123456)`.
- All Discord struct fields use snake_case matching the Discord API JSON keys.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `HTTP.jl` | HTTP client for REST API |
| `JSON3.jl` | JSON serialization with StructTypes |
| `StructTypes.jl` | Type metadata for JSON3 (Mutable strategy) |
| `CodecZlib.jl` | zlib-stream decompression for gateway payloads |
| `LRUCache.jl` | LRU eviction policy for state caching |
| `Opus_jll` | Opus audio codec (voice encoding/decoding) |
| `libsodium_jll` | Cryptographic functions (voice encryption) |
| `Dates` (stdlib) | Timestamp handling |
| `Logging` (stdlib) | Structured logging |
| `Sockets` (stdlib) | UDP for voice RTP |

---

## Building and Testing

### Setup

```bash
cd Accord.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Run Tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Or from the Julia REPL:

```julia
] test
```

Tests are all unit tests — no Discord token or network required. The test suite covers: Snowflake IDs, bitfield flags, type construction and serialization, permission computation, rate limiter logic, component builders, macro code generation, and the checks/waitfor system.

### CI

GitHub Actions (`.github/workflows/ci.yml`) runs on push/PR to `main`:
- Matrix: Julia 1.10 and latest stable
- OS: ubuntu-latest
- Steps: checkout → setup Julia → cache → build → test

---

## Test Files

| File | Covers |
|------|--------|
| `test_snowflake.jl` | Snowflake construction, conversion, timestamp extraction |
| `test_flags.jl` | Bitwise flag operations, `has_flag()`, Intents/Permissions |
| `test_types.jl` | Struct construction, JSON roundtrip, Optional/Nullable defaults |
| `test_permissions.jl` | `compute_base_permissions()`, `compute_channel_permissions()` |
| `test_ratelimiter.jl` | Rate limiter queuing, bucket state, header parsing |
| `test_components.jl` | Component builder output: buttons, selects, embeds, action rows |
| `test_macros.jl` | `@discord_struct` and `@discord_flags` macro generation |
| `test_checks_waitfor.jl` | Permission checks, check stacking, `run_checks()`, EventWaiter |

When adding a new test file, add the corresponding `include("unit/test_<name>.jl")` to `test/runtests.jl` inside the `@testset "Accord.jl"` block.

---

## Exports

The module exports ~200 symbols organized by category. All exports are declared in `src/Accord.jl` lines 124-291. Categories:

- **Types**: All Discord structs (User, Guild, Message, etc.)
- **Enums**: Module-scoped enums (ChannelTypes, MessageTypes, etc.)
- **Flags**: Bitfield types and named constants (Intents, Permissions, MessageFlags)
- **Events**: All ~50 gateway event types
- **Gateway**: Opcodes, close codes, GatewayCommand
- **REST**: RateLimiter, Route, discord_get/post/put/patch/delete, and ~40 endpoint functions
- **Client**: Client, start, stop, on, wait_for, etc.
- **State**: CacheStrategy subtypes, Store, State
- **Interactions**: InteractionContext, macros, component builders, check guards
- **Voice**: VoiceClient, AudioPlayer, audio sources, Opus encoder/decoder

---

## How to Add New Features

### Adding a New Discord Type

1. Create `src/types/<name>.jl`
2. Use the `@discord_struct` macro:
   ```julia
   @discord_struct MyType begin
       id::Snowflake
       name::String
       description::Optional{String}
       data::Nullable{Dict{String, Any}}
       items::Vector{String}
   end
   ```
3. Add `include("types/<name>.jl")` in `src/Accord.jl` at the appropriate position (after all types it depends on)
4. Add `export MyType` in the exports section

### Adding a New REST Endpoint

1. Add function(s) in the appropriate `src/rest/endpoints/<resource>.jl` file (or create a new one)
2. Use `Route` for URL construction and `submit_rest()` to go through rate limiting:
   ```julia
   function get_my_resource(ratelimiter, resource_id; token)
       route = Route(:GET, "/my-resource/$resource_id")
       submit_rest(ratelimiter, route; token)
   end
   ```
3. Add `export get_my_resource` in `src/Accord.jl`

### Adding a New Gateway Event

1. Define the event struct in `src/gateway/events.jl`:
   ```julia
   struct MyEvent <: AbstractEvent
       # fields
   end
   ```
2. Add `_construct_event` method in `src/gateway/dispatch.jl`
3. Add mapping in the `EVENT_TYPES` dict (dispatch.jl)
4. Add `export MyEvent` in `src/Accord.jl`

### Adding a New Check

Create a factory function in `src/interactions/checks.jl` that returns a closure `(ctx::InteractionContext) -> Bool`:

```julia
function my_check(args...)
    return function(ctx::InteractionContext)
        # return true to pass, false to deny
    end
end
```

Usage: `@check my_check(args...)` before `@slash_command`.

---

## Module Initialization

On `__init__()` (module load), Accord.jl runs:

1. `init_sodium()` — initializes libsodium for voice encryption
2. `_init_perm_map!()` — populates the permission symbol-to-constant map used by `has_permissions(:MANAGE_GUILD)` style checks

---

## Code Style and Conventions

- **Language**: Source code, comments, and variable names in English. Documentation may contain Portuguese (pt-BR).
- **Naming**: snake_case for functions and variables, PascalCase for types and modules.
- **Type annotations**: Use `::Type` in struct fields. Function arguments are typically untyped (relying on multiple dispatch) unless disambiguation is needed.
- **Macros**: Heavy use of macros for DSL. Macro hygiene uses `$(@__MODULE__)` to reference module-level symbols.
- **Error handling**: Logging via `@warn`, `@error`. Gateway reconnects automatically on most close codes.
- **Concurrency**: Julia `Task`s for async operations (heartbeat, rate limiter, gateway event loop). `Channel`s for inter-task communication. `ReentrantLock` for thread safety (e.g., `_CHECKS_LOCK`).
- **JSON serialization**: All types use `JSON3.read(data, Type)` and `JSON3.write(obj)`. StructTypes `Mutable()` strategy  with `omitempties`.

---

## Common Gotchas

1. **Include order in Accord.jl matters**: If you reference a type that hasn't been included yet, you'll get an `UndefVarError` at precompile time.
2. **`Optional` vs `Nullable`**: `Optional{T}` (Union with `Missing`) is for fields the API may omit entirely. `Nullable{T}` (Union with `Nothing`) is for fields that are present but may be JSON `null`. Don't mix them up.
3. **Enums are not Julia `@enum`**: They're modules with `const` values. You can't use `instances()` or pattern match on them. Compare with `==`.
4. **Flags are custom structs**: They support `|` for combining and `has_flag()` for checking, but they're not integers. Don't use bitwise ops on raw integers — wrap in the flag type first.
5. **`@check` is positional**: Checks accumulate globally and are drained by the next `@slash_command`. If you use `@check` without a following `@slash_command`, the checks will leak to the next command definition. The accumulator is thread-safe via `_CHECKS_LOCK`.
6. **Rate limiter is an actor**: REST calls are asynchronous. `submit_rest()` returns a future-like `Channel` result, not an immediate HTTP response.
7. **Voice requires system libraries**: Opus and libsodium are provided via JLL packages but require compatible system architectures.

---

## Documentation Map

- `README.md` — Quick start, feature overview, installation
- `docs/API.md` — Complete API reference (all types, functions, macros, with signatures and examples)
- `docs/cookbook/` — 17 practical guides:
  - `01-basic-bot.md` — Hello world, event handlers
  - `02-messages-and-embeds.md` — Rich embeds, attachments
  - `03-slash-commands.md` — Command registration, options, autocomplete
  - `04-buttons-selects-modals.md` — Interactive components
  - `05-voice.md` — Voice connection, audio playback
  - `06-permissions.md` — Permission checks, guards
  - `07-caching.md` — Cache strategies (LRU, TTL)
  - `08-sharding.md` — Multi-shard bots
  - `09-automod.md` — Auto-moderation
  - `10-polls.md` — Discord polls
  - `11-architectural-patterns.md` — MVC, state injection
  - `12-performance.md` — Optimization, profiling
  - `13-deploy.md` — Docker, systemd, production
  - `14-troubleshooting.md` — Common issues
  - `15-why-julia.md` — Performance comparison
  - `16-ai-agent.md` — LLM-powered bot example
- `KANBAN.md` — Development roadmap and progress

---

## Quick Reference: Macro Signatures

```julia
# Define a Discord struct
@discord_struct Name begin
    field::Type
end

# Define bitfield flags
@discord_flags Name Type begin
    FLAG_A = 1 << 0
    FLAG_B = 1 << 1
end

# Register a slash command
@slash_command client "name" "description" function(ctx)
    respond(ctx; content="Hello!")
end

# With options
@slash_command client "name" "description" [
    @option String "arg" "description" required=true
] function(ctx)
    val = get_option(ctx, "arg", "")
    respond(ctx; content=val)
end

# Guild-specific command
@slash_command client guild_id "name" "description" handler

# Pre-execution checks (stack before @slash_command)
@check has_permissions(:MANAGE_GUILD)
@check is_owner()
@slash_command client "admin" "Admin only" handler

# Message handler (auto-filters bots)
@on_message client (c, msg) -> begin
    msg.content == "!ping" && reply(c, msg; content="Pong!")
end

# Component handlers
@button_handler client "custom_id" handler
@select_handler client "custom_id" handler
@modal_handler client "custom_id" handler
@autocomplete client "command_name" handler

# Command option (used inside option arrays)
@option Type "name" "description" required=true
```

---

## Quick Reference: Client Lifecycle

```julia
using Accord

client = Client(ENV["DISCORD_TOKEN"],
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent;
    state = (db = my_db_connection,))

on(client, ReadyEvent) do c, event
    @info "Bot online as $(event.user.username)"
end

@slash_command client "ping" "Pong!" function(ctx)
    respond(ctx; content="Pong!")
end

start(client)       # Blocks — connects gateway, starts event loop
# stop(client)      # Graceful shutdown
```
