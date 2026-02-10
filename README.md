# Accord.jl

A modern Discord API v10 library for Julia.

## Features

- Full Discord API v10 support
- Dispatch-Driven Actor architecture (Tasks + Channels)
- Gateway with zlib-stream compression, sharding, and auto-reconnect
- REST client with per-bucket rate limiting
- Slash commands, buttons, select menus, modals, Components V2
- Voice support with Opus encoding and libsodium encryption
- Efficient caching with LRU/TTL strategies
- Event dispatch via Julia's multiple dispatch

## Installation

```julia
using Pkg
Pkg.add("Accord")
```

## Quick Start

```julia
using Accord

client = Client("Bot YOUR_TOKEN_HERE";
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
)

on_event(client, ::Ready) = @info "Bot is ready!"

function on_event(client, event::MessageCreate)
    event.message.content == "ping" && create_message(client, event.message.channel_id; content="pong")
end

start(client)
```

## Credits

Inspired by [Ekztazy.jl](https://github.com/Humans-of-Julia/Ekztazy.jl),
[Discord.jl](https://github.com/Xh4H/Discord.jl), and
[Discord.py](https://github.com/Rapptz/discord.py).

## License

MIT
