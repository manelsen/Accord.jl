# Accord.jl 🎹

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia Version](https://img.shields.io/badge/julia-1.11+-blue.svg)](https://julialang.org)
[![Discord API](https://img.shields.io/badge/Discord%20API-v10-5865F2.svg)](https://docs.discord.com/developers/intro)

**Accord.jl** is a high-performance, ergonomic Discord API library for Julia. Built for speed and developer happiness, it leverages Julia's multiple dispatch and concurrency model to make bot development intuitive and powerful.

---

## ✨ Features

- **Full v10 Support:** Compatible with the latest Discord API features.
- **Ergonomic UI Macros:** Decorators for Slash Commands, Buttons, Modals, and Select Menus.
- **`@check` Guards:** Declarative pre-execution checks for permissions, ownership, and custom conditions.
- **`wait_for` Conversations:** Lightweight state machines using Julia Channels — no manual state management.
- **State Injection:** Pass your database, config, or services via `ctx.state` — zero globals.
- **Voice playback with DAVE:** Opus encoding, AEAD transport encryption and the DAVE end-to-end encryption protocol Discord requires since March 2026. DAVE runs on Discord's [libdave](https://github.com/discord/libdave), which you build yourself for now and point to with `ACCORD_LIBDAVE` (see the [voice recipe](docs/src/cookbook/05-voice.md)). Receiving audio is not implemented.
- **Efficient Caching:** Automatic state management with customizable LRU/TTL strategies.
- **Type Safety:** Leveraging Julia's type system to catch bugs before they happen.
- **Async First:** Built on top of Julia's Tasks and Channels for non-blocking I/O.

---

## 📦 Installation

```julia
using Pkg
Pkg.add("Accord")
```

### Project generator (optional)

The `accord` command-line tool, which scaffolds new bot projects and checks your environment, lives in the separate [`AccordCLI`](AccordCLI/) package so the library itself stays lean:

```julia
using Pkg
Pkg.add(url="https://github.com/manelsen/Accord.jl", subdir="AccordCLI")
using AccordCLI
AccordCLI.onboard_impl("MyBot"; modules="moderation,utils")
```

---

## 🚀 Quick Start

Creating a bot is simple and expressive:

```julia
using Accord
using Accord: on, start, respond, followup, has_permissions

# 1. Initialize the client with optional state injection
client = Client(ENV["DISCORD_TOKEN"];
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
    state = (db=my_database, config=my_config)  # accessible via ctx.state
)

# 2. Register basic events
on(client, ReadyEvent) do c, event
    @info "Bot is online as $(event.user.username)!"
end

# 3. Use @check guards for clean permission control
@check has_permissions(:MANAGE_GUILD)
@slash_command client "config" "Server settings" function(ctx)
    respond(ctx; content="Config panel for guild $(ctx.guild_id)", ephemeral=true)
end

# 4. Conversational flows with wait_for
@slash_command client "quiz" "Start a quiz" function(ctx)
    respond(ctx; content="What color is the sky?")

    event = wait_for(client, MessageCreate; timeout=30) do evt
        evt.message.author.id == ctx.user.id
    end

    if isnothing(event)
        followup(ctx; content="⏰ Time's up!")
    elseif lowercase(event.message.content) == "blue"
        followup(ctx; content="✅ Correct!")
    else
        followup(ctx; content="❌ Wrong!")
    end
end

# 5. Simple slash command
@slash_command client "ping" "Check latency" function(ctx)
    respond(ctx; content="Pong! 🏓")
end

# 6. Sync commands and start
on(client, ReadyEvent) do c, event
    sync_commands!(c, c.command_tree)
end

start(client)
```

---

## 🧵 Threads

Start Julia with several threads and one interactive thread:

```bash
julia -t auto,1 --project bot.jl     # or: JULIA_NUM_THREADS=auto,1
```

Accord runs its time-critical loops — gateway, heartbeat, rate limiter, voice — on the interactive thread, and your event handlers on the default threads, in parallel (up to `handler_concurrency`, default 16). A handler that crunches numbers for a minute cannot delay a heartbeat or a voice packet.

Because handlers run in parallel, **state you share between handlers must be thread-safe**: guard it with a `ReentrantLock`, or use `Threads.Atomic` for counters. Accord's own state (`client.state`, the rate limiter, the gateway) is already safe to use from any handler. Register commands and event handlers before calling `start`.

With a single thread (Julia's default), everything still works, but a slow handler shares the thread with the heartbeat.

---

## 🏷️ Names and imports

`using Accord` brings in the types, the event types, the `@slash_command` family of macros and the Discord-specific functions (`create_message`, `wait_for`, `sync_commands!`, …). Short generic verbs and builders — `start`, `on`, `respond`, `defer`, `button`, `embed`, `section` — are part of the public API but not exported, so they never clash with other packages. Import the ones you use, as in the Quick Start, or call them qualified: `Accord.respond(ctx; content="hi")`.

Every REST endpoint takes the client as its first argument and is called qualified:

```julia
rules = Accord.list_auto_moderation_rules(client, guild_id)
Accord.add_guild_member_role(client, guild_id, user_id, role_id; reason="verified")
```

---

## 📚 Documentation

The documentation is organized into two main parts:

- **[API Reference](docs/API.md)**: Exhaustive list of types, functions, and events.
- **[Cookbook](docs/src/cookbook/index.md)**: Step-by-step recipes for everything from basic bots to AI agents and voice transcription.

### Popular Recipes:
- [Your First Bot](docs/src/cookbook/01-basic-bot.md)
- [Rich Embeds & Files](docs/src/cookbook/02-messages-and-embeds.md)
- [Slash Commands & Autocomplete](docs/src/cookbook/03-slash-commands.md)
- [Interactive Buttons & Modals](docs/src/cookbook/04-buttons-selects-modals.md)
- [Voice Playback & Whisper AI](docs/src/cookbook/05-voice.md)
- [LLM-Powered AI Agent](docs/src/cookbook/16-ai-agent.md)

---

## 🛠 Why Julia for Discord?

Julia isn't just a language for math; its concurrency model (no GIL!) and multiple dispatch make it a compelling alternative to Python for real-time applications:

| Feature | Python (discord.py) | Accord.jl |
| :--- | :--- | :--- |
| **Concurrency** | Cooperative (asyncio) | Parallel (Multi-threading) |
| **Dispatch** | String-based/Decorators | Multiple Dispatch (Type-based) |
| **Performance** | Interpreter overhead | JIT Compiled (C speed) |
| **Integration** | Subprocess for ML/Data | Native (Flux.jl, Makie.jl, etc.) |
| **Permission Guards** | `@commands.has_permissions()` | `@check has_permissions()` |
| **Conversations** | `bot.wait_for()` | `wait_for(client, Event)` |
| **State Injection** | `bot.state` / cog attrs | `ctx.state` (any user struct) |

---

## 🤝 Credits & Inspiration

Accord.jl is built on the shoulders of giants:
- [discord.py](https://github.com/Rapptz/discord.py) for the API design philosophy.
- [Discord.jl](https://github.com/Xh4H/Discord.jl) and [Ekztazy.jl](https://github.com/Humans-of-Julia/Ekztazy.jl) for early Julia implementations.

## 🛠 Development

### Testing
Run the full suite of unit tests:
```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

### Coverage
Generate a local HTML coverage report using `Coverage.jl`:
```bash
julia scripts/coverage.jl
```
The report will be generated in the `coverage/` directory (if configured) or summarized in the terminal.

### Offline Integration Tests (Mocking)
Accord.jl uses `Mocking.jl` to simulate Discord API responses using local JSON fixtures. This allows for fast, reliable, and offline testing.

To add a new mocked test:
1. Place the Discord API response JSON in `test/integration/fixtures/`.
2. Add a test case in `test/integration/test_rest_mock.jl` using the `@patch` and `apply()` pattern.

Run integration tests:
```bash
ACCORD_INTEGRATION_TESTS=1 julia --project=. -e 'using Pkg; Pkg.test()'
```

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
