# Accord.jl Cookbook

Practical, copy-paste-ready recipes for building Discord bots in Julia with [Accord.jl](https://github.com/your-org/Accord.jl).

## Prerequisites

- **Julia 1.10+** ([download](https://julialang.org/downloads/))
- **Discord bot token** — create one at the [Discord Developer Portal](https://discord.com/developers/applications)
- **Accord.jl** installed: `] add Accord`

---

## Getting Started

| # | Recipe | What you'll build |
|---|--------|-------------------|
| 01 | [Your First Bot](01-basic-bot.md) | Hello world, ping/pong, intents, REPL mode |
| 02 | [Rich Messages](02-messages-and-embeds.md) | Embeds, reactions, attachments, bulk operations |

## Interactions

| # | Recipe | What you'll build |
|---|--------|-------------------|
| 03 | [Slash Commands](03-slash-commands.md) | Commands with options, autocomplete, subcommands |
| 04 | [Buttons, Selects & Modals](04-buttons-selects-modals.md) | Interactive components, ticket system workflow |
| 10 | [Polls](10-polls.md) | Creating polls, listening for votes, ending early |

## Advanced Features

| # | Recipe | What you'll build |
|---|--------|-------------------|
| 05 | [Voice](05-voice.md) | Playback, recording, transcription |
| 06 | [Permissions](06-permissions.md) | Computing permissions, `@check` guards, private channels |
| 07 | [Caching](07-caching.md) | Cache strategies, per-resource config, memory tips |
| 08 | [Sharding](08-sharding.md) | Multi-shard bots for 2,500+ guilds |
| 09 | [Auto-Moderation](09-automod.md) | Keyword filters, spam protection, alert channels |

## Production

| # | Recipe | What you'll build |
|---|--------|-------------------|
| 11 | [Architectural Patterns](11-architectural-patterns.md) | Project structure, middleware, `@check` guards, `wait_for`, state injection |
| 12 | [Performance](12-performance.md) | Type stability, precompilation, async patterns |
| 13 | [Deployment](13-deploy.md) | Systemd, Docker, sysimages, health checks |
| 14 | [Troubleshooting](14-troubleshooting.md) | Common errors, debug logging, gateway issues |

## Advocacy & Capstone

| # | Recipe | What you'll build |
|---|--------|-------------------|
| 15 | [Why Julia for Discord Bots?](15-why-julia.md) | Performance, multiple dispatch, scientific computing |
| 16 | [AI Agent Bot](16-ai-agent.md) | LLM integration, streaming, tool use, memory |
