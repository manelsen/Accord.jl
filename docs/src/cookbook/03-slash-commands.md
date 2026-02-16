# Recipe 03 — Slash Commands

**Difficulty:** Intermediate
**What you will build:** Slash commands with options, autocomplete, subcommands, deferred responses, and followup messages.

**Prerequisites:** [Recipe 01](01-basic-bot.md)

---

## 1. How Slash Commands Work in Accord.jl

The interaction flow:

1. You create a [`CommandTree`](@ref) and register commands on it
2. On [`ReadyEvent`](@ref), call [`sync_commands!`](@ref) to push definitions to Discord
3. On [`InteractionCreate`](@ref), call [`dispatch_interaction!`](@ref) to route to handlers
4. Each handler receives an [`InteractionContext`](@ref) with helper methods

## 2. Basic Slash Command

```julia
using Accord

token = ENV["DISCORD_TOKEN"]
client = Client(token; intents=IntentGuilds)

# Register a simple command using the macro
@slash_command client "hello" "Say hello!" function(ctx)
    respond(ctx; content="Hello, <@$(ctx.interaction.member.user.id)>!")
end

# Sync commands when ready
on(client, ReadyEvent) do c, event
    @info "Bot ready, syncing commands..."
    sync_commands!(c, c.command_tree)
end

start(client)
```

Note that [`Client`](@ref) automatically handles interaction dispatch to its internal `command_tree`.

## 3. Commands with Options

Use [`command_option`](@ref)`()` to define typed parameters:

```julia
options = [
    command_option(
        type=ApplicationCommandOptionTypes.STRING,
        name="name",
        description="Who to greet",
        required=true,
    ),
    command_option(
        type=ApplicationCommandOptionTypes.INTEGER,
        name="times",
        description="How many times to greet",
        required=false,
        min_value=1,
        max_value=5,
    ),
]

@slash_command client "greet" "Greet someone" options function(ctx)
    name = get_option(ctx, "name", "World")
    times = get_option(ctx, "times", 1)
    greeting = join(fill("Hello, $name!", times), "\n")
    respond(ctx; content=greeting)
end
```

### Option Type Reference

| Constant | Value | Julia type returned |
|----------|-------|-------------------|
| [`ApplicationCommandOptionTypes`](@ref)`.STRING` | 3 | `String` |
| [`ApplicationCommandOptionTypes`](@ref)`.INTEGER` | 4 | `Int` |
| [`ApplicationCommandOptionTypes`](@ref)`.BOOLEAN` | 5 | `Bool` |
| [`ApplicationCommandOptionTypes`](@ref)`.USER` | 6 | Snowflake string |
| [`ApplicationCommandOptionTypes`](@ref)`.CHANNEL` | 7 | Snowflake string |
| [`ApplicationCommandOptionTypes`](@ref)`.ROLE` | 8 | Snowflake string |
| [`ApplicationCommandOptionTypes`](@ref)`.MENTIONABLE` | 9 | Snowflake string |
| [`ApplicationCommandOptionTypes`](@ref)`.NUMBER` | 10 | `Float64` |
| [`ApplicationCommandOptionTypes`](@ref)`.ATTACHMENT` | 11 | Attachment ID |

## 4. Static Choices

```julia
options = [
    command_option(
        type=ApplicationCommandOptionTypes.STRING,
        name="color",
        description="Pick a color",
        required=true,
        choices=[
            Dict("name" => "Red", "value" => "red"),
            Dict("name" => "Green", "value" => "green"),
            Dict("name" => "Blue", "value" => "blue"),
        ]
    ),
]

@slash_command client "color" "Pick a color" options function(ctx)
    color = get_option(ctx, "color", "red")
    hex = Dict("red" => 0xED4245, "green" => 0x57F287, "blue" => 0x5865F2)[color]
    e = embed(title="You picked $color!", color=hex)
    respond(ctx; embeds=[e])
end
```

## 5. Autocomplete

For dynamic suggestions, mark an option as `autocomplete=true` and register an autocomplete handler:

```julia
const FRUITS = ["apple", "apricot", "avocado", "banana", "blueberry",
                "cherry", "coconut", "dragonfruit", "fig", "grape",
                "kiwi", "lemon", "mango", "orange", "papaya",
                "peach", "pear", "pineapple", "raspberry", "strawberry"]

options = [
    command_option(
        type=ApplicationCommandOptionTypes.STRING,
        name="fruit",
        description="Pick a fruit",
        required=true,
        autocomplete=true,
    ),
]

@slash_command client "fruit" "Search for a fruit" options function(ctx)
    fruit = get_option(ctx, "fruit", "")
    respond(ctx; content="You picked: **$fruit**")
end

@autocomplete client "fruit" function(ctx)
    query = lowercase(get_option(ctx, "fruit", ""))
    matches = filter(f -> startswith(f, query), FRUITS)
    choices = [Dict("name" => f, "value" => f) for f in first(matches, 25)]

    body = Dict(
        "type" => InteractionCallbackTypes.APPLICATION_COMMAND_AUTOCOMPLETE_RESULT,
        "data" => Dict("choices" => choices)
    )
    create_interaction_response(ctx.client.ratelimiter, ctx.interaction.id, ctx.interaction.token;
        token=ctx.client.token, body)
end
```

## 6. Subcommands and Subcommand Groups

Subcommands are options of type `SUB_COMMAND`:

```julia
options = [
    command_option(
        type=ApplicationCommandOptionTypes.SUB_COMMAND,
        name="add",
        description="Add a tag",
        options=[
            command_option(type=ApplicationCommandOptionTypes.STRING, name="name", description="Tag name", required=true),
            command_option(type=ApplicationCommandOptionTypes.STRING, name="content", description="Tag content", required=true),
        ]
    ),
    command_option(
        type=ApplicationCommandOptionTypes.SUB_COMMAND,
        name="get",
        description="Get a tag",
        options=[
            command_option(type=ApplicationCommandOptionTypes.STRING, name="name", description="Tag name", required=true),
        ]
    ),
]

# In-memory tag storage
const tags = Dict{String, String}()

@slash_command client "tag" "Manage tags" options function(ctx)
    data = ctx.interaction.data
    ismissing(data) && return
    ismissing(data.options) && return

    sub = data.options[1]
    sub_opts = Dict{String, Any}()
    if !ismissing(sub.options)
        for opt in sub.options
            !ismissing(opt.value) && (sub_opts[opt.name] = opt.value)
        end
    end

    if sub.name == "add"
        tags[sub_opts["name"]] = sub_opts["content"]
        respond(ctx; content="Tag **$(sub_opts["name"])** created!", ephemeral=true)
    elseif sub.name == "get"
        name = sub_opts["name"]
        content = get(tags, name, nothing)
        if isnothing(content)
            respond(ctx; content="Tag **$name** not found.", ephemeral=true)
        else
            respond(ctx; content=content)
        end
    end
end
```

## 7. Guild vs Global Commands

!!! note "Command Sync Delay"
    Global commands take up to **1 hour** to propagate across all Discord servers. If you update a global command, users may see the old version for a while.

```julia
# Global commands — available everywhere, up to 1 hour to propagate
@slash_command client "ping" "Check latency" function(ctx)
    respond(ctx; content="Pong!")
end
```

!!! tip "Use Guild Commands During Development"
    Guild commands update instantly (within a few seconds). During development, sync commands to a specific guild for rapid iteration:

```julia
# Guild command — instant, only in one server
GUILD_ID = 123456789012345678
@slash_command client GUILD_ID "debug" "Debug info" function(ctx)
    respond(ctx; content="Debug mode active", ephemeral=true)
end

# Or sync everything to a specific guild for development
on(client, [`ReadyEvent`](@ref)) do c, event
    sync_commands!(c, c.command_tree; guild_id=[`Snowflake`](@ref)(GUILD_ID))  # instant during dev
end
```

## 8. Deferred Responses

If your command takes more than 3 seconds, defer first:

```julia
@slash_command client "slow" "A slow operation" function(ctx)
    defer(ctx)  # shows "Bot is thinking..."

    # Do expensive work
    sleep(5)
    result = "Done after 5 seconds!"

    # Edit the deferred response
    respond(ctx; content=result)
end
```

### Ephemeral Deferred Response

```julia
@slash_command client "secret" "Private slow operation" function(ctx)
    defer(ctx; ephemeral=true)  # only visible to the user

    sleep(3)
    respond(ctx; content="Secret result!")
end
```

## 9. Followup Messages

Send additional messages after the initial response:

```julia
@slash_command client "multi" "Multiple responses" function(ctx)
    respond(ctx; content="First response!")

    sleep(1)
    followup(ctx; content="Here's a followup!")

    sleep(1)
    followup(ctx; content="And another one!", ephemeral=true)
end
```

## 10. Edit the Original Response

```julia
@slash_command client "countdown" "Countdown timer" function(ctx)
    defer(ctx)

    for i in 3:-1:1
        edit_response(ctx; content="**$i**...")
        sleep(1)
    end

    edit_response(ctx; content="**Go!**")
end
```

---

## Complete Example

```julia
using Accord

token = ENV["DISCORD_TOKEN"]
client = Client(token; intents=IntentGuilds)

# Simple command
@slash_command client "ping" "Check bot latency" function(ctx)
    t = time()
    defer(ctx)
    ms = round(Int, (time() - t) * 1000)
    respond(ctx; content="Pong! API latency: **$(ms) ms**")
end

# Command with options
options = [
    command_option(type=ApplicationCommandOptionTypes.STRING, name="text", description="Text to echo", required=true),
    command_option(type=ApplicationCommandOptionTypes.BOOLEAN, name="ephemeral", description="Only visible to you?"),
]

@slash_command client "echo" "Echo a message" options function(ctx)
    text = get_option(ctx, "text", "")
    eph = get_option(ctx, "ephemeral", false)
    respond(ctx; content=text, ephemeral=eph)
end

on(client, ReadyEvent) do c, event
    @info "Syncing commands..."
    sync_commands!(c, c.command_tree)
    @info "Bot ready!"
end

start(client)
```

---

**Next steps:** [Recipe 04 — Buttons, Selects & Modals](04-buttons-selects-modals.md) to add interactive components to your messages.
