# Accord.jl

**Accord.jl** is a high-performance, ergonomic Discord API library for Julia. Built for speed and developer happiness, it leverages Julia's multiple dispatch and concurrency model to make bot development intuitive and powerful.

## Features

- **Full v10 Support:** Compatible with the latest Discord API features.
- **Ergonomic UI Macros:** Decorators for Slash Commands, Buttons, Modals, and Select Menus.
- **`@check` Guards:** Declarative pre-execution checks for permissions, ownership, and custom conditions.
- **`wait_for` Conversations:** Lightweight state machines using Julia Channels — no manual state management.
- **State Injection:** Pass your database, config, or services via `ctx.state` — zero globals.
- **High-Performance Voice:** Built-in support for Opus encoding and encryption for music/voice bots.
- **Efficient Caching:** Automatic state management with customizable LRU/TTL strategies.
- **Type Safety:** Leveraging Julia's type system to catch bugs before they happen.
- **Async First:** Built on top of Julia's Tasks and Channels for non-blocking I/O.

## Installation

```julia
using Pkg
Pkg.add("Accord")
```

## Quick Start

```julia
using Accord

client = Client(ENV["DISCORD_TOKEN"];
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)

on(client, ReadyEvent) do c, event
    @info "Bot is online as $(event.user.username)!"
end

@slash_command client "ping" "Check latency" function(ctx)
    respond(ctx; content="Pong!")
end

on(client, ReadyEvent) do c, event
    sync_commands!(c, c.command_tree)
end

start(client)
```

## Next Steps

- Browse the [Cookbook](@ref cookbook-index) for step-by-step recipes
- Check the [API Reference](@ref api-reference) for detailed documentation
