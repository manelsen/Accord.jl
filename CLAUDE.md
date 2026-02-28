# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing

```bash
# Run default tests (unit + integration, no Aqua/JET)
julia --project test/runtests.jl

# Run specific test category
julia --project test/runtests.jl unit
julia --project test/runtests.jl integration
julia --project test/runtests.jl quality   # Aqua + JET
julia --project test/runtests.jl all

# Control parallelism (default: 6 workers)
ACCORD_TEST_WORKERS=1 julia --project test/runtests.jl unit

# Via Pkg
julia --project -e 'using Pkg; Pkg.test()'
julia --project -e 'using Pkg; Pkg.test(test_args=["unit"])'
julia --project -e 'using Pkg; Pkg.test(test_args=["quality"])'
```

### Documentation

```bash
julia --project=docs docs/make.jl
```

### REPL / Interactive Development

```julia
julia --project
using Accord
```

## Architecture

**Accord.jl** is a Discord API v10 library (v0.3.0). The include order in `src/Accord.jl` is authoritative for understanding dependencies between subsystems.

### Module Load Order (dependency chain)

1. **`types/`** — All Discord data structures. Load order within this directory matters: base types (`user`, `role`, `emoji`, `member`) come before composite types (`channel`, `message`, `guild`), which come before complex types (`interaction`, `automod`, etc.).

2. **`gateway/`** — WebSocket connection to Discord. Files: `opcodes.jl` → `events.jl` → `heartbeat.jl` → `dispatch.jl` → `connection.jl` → `shard.jl`. The gateway dispatches `AbstractEvent` subtypes onto a `Channel{AbstractEvent}`.

3. **`rest/`** — HTTP client with rate limiting. `route.jl` → `ratelimiter.jl` → `http_client.jl` → `endpoints/*.jl`. Each endpoint file groups related REST calls (e.g., `guild.jl`, `message.jl`).

4. **`interactions/context.jl` and `interactions/checks.jl`** — Must be loaded before `Client` because `Client` depends on `InteractionContext`. The `interactions/decorators.jl` and `interactions/components.jl` are loaded *after* `Client`.

5. **`client/`** — `state.jl` → `event_handler.jl` → `client.jl`. `Client` is the central struct that holds the event channel, command tree, state cache, and rate limiter.

6. **`voice/`** — Separate subsystem: `encryption.jl` (libsodium XSalsa20/XChaCha20) → `opus.jl` → `udp.jl` → `player.jl` → `sources.jl` → `connection.jl` → `client.jl`.

7. **`utils/`** and **`diagnostics/`** — Loaded last; no dependents within the library.

### Key Type Conventions

- **`Optional{T}`** = `Union{T, Missing}` — for Discord fields that may be absent from the payload (JSON omission). Defaults to `missing`.
- **`Nullable{T}`** = `Union{T, Nothing}` — for fields explicitly set to `null` in JSON. Defaults to `nothing`.
- **`Snowflake`** — wraps `UInt64`; Discord's ID type. All entity IDs use this.
- **`@discord_struct Name begin ... end`** — macro in `types/macros.jl` that generates a mutable struct with keyword constructor, `Optional`/`Nullable` defaults, and `JSON3`/`StructTypes` integration. Use this for all new Discord API structs.
- **`@discord_flags`** — generates `Integer`-backed bitfield types (e.g., `Permissions`, `MessageFlags`).

### Event-Driven Data Flow

```
Discord WS → Shard → dispatch.jl → AbstractEvent → Channel{AbstractEvent}
                                                          ↓
                                                    event_handler.jl
                                                          ↓
                                          on(client, EventType) handlers
                                                          ↓
                                              InteractionContext (for interactions)
                                                   ctx.state / REST calls
```

All user event handlers are registered with `on(client, EventType) do ctx ... end`. The `@on` macro is syntactic sugar for this.

### Interaction Macros

User-facing DX macros in `interactions/decorators.jl`:
- `@slash_command` — registers a slash command with automatic type coercion
- `@button_handler` / `@select_handler` / `@modal_handler` — component callbacks
- `@check` — guard decorator applied before a handler runs
- `@on` — event handler decorator
- `@embed` — builds `Embed` structs declaratively
- `@group` — groups subcommands under a parent command

### State & Caching

`client/state.jl` implements pluggable cache strategies per resource type:
- `ForeverStrategy` — keep all entries
- `LRUStrategy(n)` — LRU eviction at `n` entries
- `TTLStrategy(seconds)` — time-based expiry
- `NeverStrategy` — no caching

User application state is injected via `Client(...; state=my_config)` and accessed as `ctx.state` in handlers.

### Testing Patterns

Tests use **ReTestItems** — each `@testitem` is tagged with `:unit` or `:integration`. Integration tests use JSON fixtures (in `test/fixtures/`) to mock Discord API responses. Aqua and JET tests are tagged `:aqua` / `:jet` and run separately (they are slow and CI-only by convention).
