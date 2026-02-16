# Recipe 12 — Performance

**Difficulty:** Advanced
**What you will build:** Optimized bots using Julia-specific techniques: type stability, precompilation, async patterns, and profiling.

**Prerequisites:** [Recipe 11](11-architectural-patterns.md)

---

## 1. Type Stability in Handlers

!!! tip "Type Stability for Performance"
    Julia's JIT compiler generates fast code when types are predictable. Always annotate types when extracting options from [`get_option`](@ref), which returns `Any`. Use `@code_warntype` to identify type instabilities (look for red "Any" in the output).

Julia's JIT compiler generates fast code when types are predictable. The [`get_option`](@ref) function returns `Any` — annotate it:

```julia
# Slow: compiler doesn't know the type
@slash_command client "compute" "Do math" function(ctx)
    x = get_option(ctx, "x", 0)      # returns Any
    y = get_option(ctx, "y", 0)      # returns Any
    respond(ctx; content="Result: $(x + y)")  # dynamic dispatch
end

# Fast: annotate types
@slash_command client "compute" "Do math" function(ctx)
    x = get_option(ctx, "x", 0)::Number
    y = get_option(ctx, "y", 0)::Number
    respond(ctx; content="Result: $(x + y)")  # static dispatch
end
```

### Verify with @code_warntype

```julia
function handle_compute(ctx)
    x = get_option(ctx, "x", 0)::Number
    y = get_option(ctx, "y", 0)::Number
    return x + y
end

# In the REPL (with a mock context):
# @code_warntype handle_compute(ctx)
# Look for red "Any" — those are type instabilities
```

## 2. Precompilation

### SnoopCompile for Precompile Statements

```julia
# precompile_script.jl
using SnoopCompile

tinf = @snoopi_deep begin
    using Accord

    # Simulate typical operations
    client = Client("Bot fake_token"; intents=IntentGuilds)
    tree = CommandTree()
    embed(title="Test", color=0x5865F2)
    button(label="Test", custom_id="test")
    action_row([button(label="X", custom_id="x")])
    command_option(type=3, name="test", description="test")
end

# Generate precompile statements
pc = SnoopCompile.parcel(tinf)
SnoopCompile.write("precompile", pc)
```

### PackageCompiler.jl System Image

Create a custom sysimage for near-instant startup:

```julia
using PackageCompiler

create_sysimage(
    ["Accord", "HTTP", "JSON3"],
    sysimage_path="bot_sysimage.so",
    precompile_execution_file="precompile_script.jl",
)
```

Run with the sysimage:

```bash
julia --sysimage=bot_sysimage.so --project=. bin/run.jl
```

Startup goes from ~10s to ~1s.

## 3. Async Patterns

### @async vs Threads.@spawn

```julia
# @async — runs on the same thread, cooperative multitasking
# Good for I/O-bound work (API calls, file reads)
on(client, MessageCreate) do c, event
    @async begin
        result = some_api_call()  # yields while waiting
        create_message(c, event.message.channel_id; content=result)
    end
end

# Threads.@spawn — runs on a different thread
# Good for CPU-bound work (computation, image processing)
on(client, MessageCreate) do c, event
    Threads.@spawn begin
        result = expensive_computation()  # runs in parallel
        create_message(c, event.message.channel_id; content=string(result))
    end
end
```

Start Julia with multiple threads:

```bash
julia --threads=4 --project=. bin/run.jl
```

### Avoiding Event Loop Blocking

```julia
!!! warning "Global Variables Cause Type Instability"
    Avoid global mutable state. Global variables have unpredictable types, forcing the compiler to use dynamic dispatch. Instead, inject state through `Client(; state=...)` or use `const` globals with concrete types.

# BAD: blocks the event loop
on(client, MessageCreate) do c, event
    sleep(10)  # nothing else processes for 10 seconds!
    create_message(c, event.message.channel_id; content="Done")
end

# GOOD: defer to a task
on(client, MessageCreate) do c, event
    @async begin
        sleep(10)
        create_message(c, event.message.channel_id; content="Done")
    end
end
```

### Channel-Based Worker Pattern

```julia
# Process heavy work in a dedicated worker
const work_queue = Channel{Tuple{Client, Snowflake, String}}(100)

# Worker task
@async begin
    for (client, channel_id, input) in work_queue
        try
            result = expensive_processing(input)
            create_message(client, channel_id; content=result)
        catch e
            @error "Worker error" exception=e
        end
    end
end

# Handler just enqueues
on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.content) && return
    startswith(msg.content, "!process ") || return
    put!(work_queue, (c, msg.channel_id, msg.content[10:end]))
end
```

## 4. Memory Management

### Cache Sizing

```julia
# Monitor memory usage
function memory_report(client)
    guilds = length(client.state.guilds)
    channels = length(client.state.channels)
    users = length(client.state.users)

    total_mb = Base.summarysize(client.state) / 1024 / 1024

    @info "Memory report" guilds channels users total_mb=round(total_mb, digits=1)
end

# Run periodically
@async while client.running
    sleep(300)  # every 5 minutes
    memory_report(client)
end
```

### Avoid String Allocations in Hot Paths

```julia
# Allocates a new string every call
function make_greeting(name)
    return "Hello, $name! Welcome to the server."
end

# Pre-allocate with IOBuffer for complex strings
function make_report(items)
    io = IOBuffer()
    for (i, item) in enumerate(items)
        print(io, i, ". ", item, "\n")
    end
    return String(take!(io))
end
```

## 5. Profiling

### @time and @allocated

```julia
# In REPL with non-blocking mode
start(client; blocking=false)

# Time a specific operation
@time create_message(client, channel_id; content="test")
# 0.052 seconds (423 allocations: 28.5 KiB)

@allocated embed(title="Test", color=0x5865F2)
# 1248
```

### Profile.@profile

```julia
using Profile

# Profile event handling
Profile.@profile begin
    for i in 1:1000
        embed(title="Test $i", color=i, fields=[
            Dict("name" => "Field", "value" => "Value")
        ])
    end
end

Profile.print(mincount=10)
```

### Allocation tracking

```julia
# Find where allocations happen
Profile.Allocs.@profile sample_rate=1.0 begin
    for i in 1:100
        embed(title="Test", fields=[
            Dict("name" => "N", "value" => string(i))
        ])
    end
end
```

## 6. Batch Operations

Use batch endpoints to reduce API calls:

```julia
# Instead of N individual deletes:
for id in message_ids
    delete_message(client, channel_id, id)  # N API calls
end

# Use bulk delete (1 API call):
bulk_delete_messages(client.ratelimiter, channel_id;
    token=client.token, message_ids=message_ids)

# Instead of N individual command creates:
# Use sync_commands! which calls bulk_overwrite_global_application_commands
sync_commands!(client, tree)  # 1 API call for all commands
```

## 7. Connection Pooling for External Services

```julia
# Reuse HTTP connections for external APIs
const http_pool = Ref{HTTP.Pool}()

function init_pool()
    http_pool[] = HTTP.Pool(16)  # 16 connections
end

function call_external_api(endpoint, body)
    HTTP.post(endpoint, ["Content-Type" => "application/json"],
        JSON3.write(body);
        pool=http_pool[],
        retry=true,
        retries=3,
    )
end
```

## 8. Benchmark: Event Handler Overhead

```julia
using BenchmarkTools

# Measure handler dispatch overhead
eh = EventHandler()
register_handler!(eh, MessageCreate, (c, e) -> nothing)

# Create a fake event
fake_msg = Message(id=Snowflake(1), channel_id=Snowflake(2))
fake_event = MessageCreate(fake_msg)

@benchmark dispatch_event!($eh, nothing, $fake_event)
# Should be < 1μs — handler dispatch is not your bottleneck
```

---

**Next steps:** [Recipe 13 — Deployment](13-deploy.md) for running your bot in production.
