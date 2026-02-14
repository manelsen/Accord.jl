# Accord.jl 🎹

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia Version](https://img.shields.io/badge/julia-1.10+-blue.svg)](https://julialang.org)
[![Discord API](https://img.shields.io/badge/Discord%20API-v10-5865F2.svg)](https://discord.com/developers/docs/intro)

**Accord.jl** is a high-performance, ergonomic Discord API library for Julia. Built for speed and developer happiness, it leverages Julia's multiple dispatch and concurrency model to make bot development intuitive and powerful.

---

## ✨ Features

- **Full v10 Support:** Compatible with the latest Discord API features.
- **Ergonomic UI Macros:** Decorators for Slash Commands, Buttons, Modals, and Select Menus.
- **`@check` Guards:** Declarative pre-execution checks for permissions, ownership, and custom conditions.
- **`wait_for` Conversations:** Lightweight state machines using Julia Channels — no manual state management.
- **State Injection:** Pass your database, config, or services via `ctx.state` — zero globals.
- **High-Performance Voice:** Built-in support for Opus encoding and encryption for music/voice bots.
- **Efficient Caching:** Automatic state management with customizable LRU/TTL strategies.
- **Type Safety:** Leveraging Julia's type system to catch bugs before they happen.
- **Async First:** Built on top of Julia's Tasks and Channels for non-blocking I/O.

---

## 📦 Installation

```julia
using Pkg
Pkg.add("Accord")
```

---

## 🚀 Quick Start

Creating a bot is simple and expressive:

```julia
using Accord

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

## 📚 Documentation

The documentation is organized into two main parts:

- **[API Reference](docs/API.md)**: Exhaustive list of types, functions, and events.
- **[Cookbook](docs/cookbook/index.md)**: Step-by-step recipes for everything from basic bots to AI agents and voice transcription.

### Popular Recipes:
- [Your First Bot](docs/cookbook/01-basic-bot.md)
- [Rich Embeds & Files](docs/cookbook/02-messages-and-embeds.md)
- [Slash Commands & Autocomplete](docs/cookbook/03-slash-commands.md)
- [Interactive Buttons & Modals](docs/cookbook/04-buttons-selects-modals.md)
- [Voice Playback & Whisper AI](docs/cookbook/05-voice.md)
- [LLM-Powered AI Agent](docs/cookbook/16-ai-agent.md)

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
Generate a local HTML coverage report using `LocalCoverage.jl`:
```bash
julia --project=. test/coverage.jl
```
The report will be generated in the `coverage/` directory. Open `coverage/index.html` in your browser to view results.

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
