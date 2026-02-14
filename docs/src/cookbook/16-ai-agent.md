# Recipe 16 — AI Agent Bot

**Difficulty:** Advanced
**What you will build:** A Discord bot that connects to LLM APIs (OpenAI, Anthropic Claude, Ollama) with streaming responses, tool use, conversation memory, and rate limiting.

**Prerequisites:** [Recipe 03](03-slash-commands.md), [Recipe 04](04-buttons-selects-modals.md)

---

## 1. Architecture

```text
User message → Discord → Accord.jl → LLM API → Discord
                             ↑                    ↓
                      Conversation memory    Streaming edits
                      Tool execution         Followup messages
```

## 2. Calling LLM APIs from Julia

All three major providers work via HTTP.jl.

### OpenAI

```text
import HTTP
import JSON3

function openai_chat(messages::Vector{Dict}; model="gpt-4o", api_key=ENV["OPENAI_API_KEY"])
    body = Dict(
        "model" => model,
        "messages" => messages,
        "max_tokens" => 1024,
    )

    resp = HTTP.post(
        "https://api.openai.com/v1/chat/completions",
        ["Authorization" => "Bearer \$api_key", "Content-Type" => "application/json"],
        JSON3.write(body)
    )

    data = JSON3.read(resp.body)
    return data["choices"][1]["message"]["content"]
end
```

### Anthropic Claude

```text
function claude_chat(messages::Vector{Dict}; model="claude-sonnet-4-5-20250929", api_key=ENV["ANTHROPIC_API_KEY"])
    body = Dict(
        "model" => model,
        "max_tokens" => 1024,
        "messages" => messages,
    )

    resp = HTTP.post(
        "https://api.anthropic.com/v1/messages",
        [
            "x-api-key" => \$api_key,
            "anthropic-version" => "2023-06-01",
            "Content-Type" => "application/json",
        ],
        JSON3.write(body)
    )

    data = JSON3.read(resp.body)
    return data["content"][1]["text"]
end
```

### Local Ollama

```text
function ollama_chat(messages::Vector{Dict}; model="llama3.1", base_url="http://localhost:11434")
    body = Dict(
        "model" => model,
        "messages" => messages,
        "stream" => false,
    )

    resp = HTTP.post(
        "\$base_url/api/chat",
        ["Content-Type" => "application/json"],
        JSON3.write(body)
    )

    data = JSON3.read(resp.body)
    return data["message"]["content"]
end
```

## 3. Streaming Responses

Show the LLM's response progressively by editing the message:

```text
function openai_chat_stream(messages::Vector{Dict}, update_fn::Function;
        model="gpt-4o", api_key=ENV["OPENAI_API_KEY"])
    body = Dict(
        "model" => model,
        "messages" => messages,
        "max_tokens" => 1024,
        "stream" => true,
    )

    buffer = IOBuffer()
    last_edit = Ref(0.0)
    full_text = Ref("")

    HTTP.open("POST", "https://api.openai.com/v1/chat/completions",
        ["Authorization" => "Bearer \$api_key", "Content-Type" => "application/json"],
    ) do io
        write(io, JSON3.write(body))
        HTTP.closewrite(io)

        while !eof(io)
            line = readline(io)
            startswith(line, "data: ") || continue
            data_str = line[7:end]
            data_str == "[DONE]" && break

            try
                chunk = JSON3.read(data_str)
                delta = get(chunk["choices"][1]["delta"], "content", nothing)
                if !isnothing(delta)
                    full_text[] *= delta

                    # Throttle edits to 1 per second
                    if time() - last_edit[] >= 1.0
                        update_fn(full_text[])
                        last_edit[] = time()
                    end
                end
            catch
                continue
            end
        end
    end

    # Final update
    update_fn(full_text[])
    return full_text[]
end
```

### Using with Discord

```julia
options_chat = [
    command_option(type=ApplicationCommandOptionTypes.STRING, name="message", description="Your message", required=true),
]

@slash_command client "chat" "Chat with AI" options_chat function(ctx)
    user_msg = get_option(ctx, "message", "")
    defer(ctx)

    messages = [
        Dict("role" => "system", "content" => "You are a helpful assistant in a Discord server. Keep responses under 2000 characters."),
        Dict("role" => "user", "content" => user_msg),
    ]

    openai_chat_stream(messages, text -> begin
        try
            truncated = length(text) > 1990 ? text[1:1990] * "..." : text
            edit_response(ctx; content=truncated)
        catch e
            @warn "Edit failed" exception=e
        end
    end)
end
```


## 4. Tool Use / Function Calling

Let the LLM call functions your bot defines:

```julia
# Define available tools
const TOOLS = [
    Dict(
        "type" => "function",
        "function" => Dict(
            "name" => "get_weather",
            "description" => "Get current weather for a city",
            "parameters" => Dict(
                "type" => "object",
                "properties" => Dict(
                    "city" => Dict("type" => "string", "description" => "City name"),
                ),
                "required" => ["city"],
            ),
        ),
    ),
    Dict(
        "type" => "function",
        "function" => Dict(
            "name" => "roll_dice",
            "description" => "Roll dice in NdM format",
            "parameters" => Dict(
                "type" => "object",
                "properties" => Dict(
                    "notation" => Dict("type" => "string", "description" => "Dice notation like 2d6"),
                ),
                "required" => ["notation"],
            ),
        ),
    ),
]

# Tool implementations
function execute_tool(name::String, args::Dict)
    if name == "get_weather"
        city = args["city"]
        # Simulated — replace with real API
        return """{"city": "\$city", "temp": "22°C", "condition": "Sunny"}"""
    elseif name == "roll_dice"
        notation = args["notation"]
        m = match(r"(\d+)d(\d+)", notation)
        isnothing(m) && return """{"error": "Invalid notation"}"""
        n, sides = parse(Int, m[1]), parse(Int, m[2])
        rolls = [rand(1:sides) for _ in 1:n]
        return """{"rolls": \$rolls, "total": \$(sum(rolls))}"""
    end
    return """{"error": "Unknown tool"}"""
end
```

### Agent Loop

```text
function agent_chat(messages::Vector{Dict}; model="gpt-4o", api_key=ENV["OPENAI_API_KEY"], max_iterations=5)
    for _ in 1:max_iterations
        body = Dict(
            "model" => model,
            "messages" => messages,
            "tools" => TOOLS,
            "max_tokens" => 1024,
        )

        resp = HTTP.post(
            "https://api.openai.com/v1/chat/completions",
            ["Authorization" => "Bearer \$api_key", "Content-Type" => "application/json"],
            JSON3.write(body)
        )

        data = JSON3.read(resp.body)
        choice = data["choices"][1]
        msg = choice["message"]

        # Add assistant message to history
        push!(messages, Dict(pairs(msg)))

        # Check for tool calls
        if choice["finish_reason"] == "tool_calls" && haskey(msg, "tool_calls")
            for tool_call in msg["tool_calls"]
                func = tool_call["function"]
                name = func["name"]
                args = JSON3.read(func["arguments"], Dict{String, Any})

                @info "Tool call" name=name args=args
                result = execute_tool(name, args)

                push!(messages, Dict(
                    "role" => "tool",
                    "tool_call_id" => tool_call["id"],
                    "content" => result,
                ))
            end
            continue  # Loop back for LLM to process results
        end

        # No tool calls — return the response
        return get(msg, "content", "")
    end

    return "I ran out of steps trying to answer that."
end
```

## 5. Conversation Memory

Per-channel conversation history with a sliding window:

```julia
const MAX_HISTORY = 20
const conversations = Dict{Snowflake, Vector{Dict{String,String}}}()

function get_history(channel_id::Snowflake)
    get!(conversations, channel_id) do
        Dict{String,String}[]
    end
end

function add_message!(channel_id::Snowflake, role::String, content::String)
    history = get_history(channel_id)
    push!(history, Dict("role" => role, "content" => content))

    # Sliding window: keep last MAX_HISTORY messages
    while length(history) > MAX_HISTORY
        popfirst!(history)
    end
end

function clear_history!(channel_id::Snowflake)
    conversations[channel_id] = Dict{String,String}[]
end
```

## 6. Per-User Rate Limiting

Token bucket pattern to prevent API abuse:

```julia
mutable struct TokenBucket
    tokens::Float64
    max_tokens::Float64
    refill_rate::Float64  # tokens per second
    last_refill::Float64
end

TokenBucket(max_tokens, refill_rate) = TokenBucket(max_tokens, max_tokens, refill_rate, time())

function try_consume!(bucket::TokenBucket, n::Float64=1.0)
    now_t = time()
    elapsed = now_t - bucket.last_refill
    bucket.tokens = min(bucket.max_tokens, bucket.tokens + elapsed * bucket.refill_rate)
    bucket.last_refill = now_t

    if bucket.tokens >= n
        bucket.tokens -= n
        return true
    end
    return false
end

# Per-user rate limits: 5 requests, refill 1 per 10 seconds
const user_buckets = Dict{Snowflake, TokenBucket}()

function check_rate_limit(user_id::Snowflake)
    bucket = get!(user_buckets, user_id) do
        TokenBucket(5.0, 0.1)  # 5 requests max, 1 every 10 seconds
    end
    return try_consume!(bucket)
end
```

## 7. Complete Working Bot

```julia
using Accord
import HTTP
import JSON3

token = ENV["DISCORD_TOKEN"]
client = Client(token; intents=IntentGuilds)
tree = CommandTree()

# --- Configuration ---
const SYSTEM_PROMPT = """You are a helpful AI assistant in a Discord server.
Keep responses concise (under 1800 characters).
You can use markdown formatting.
If asked to do something you can't, explain why."""

const MAX_HISTORY = 20
const conversations = Dict{Snowflake, Vector{Dict{String,String}}}()
const user_buckets = Dict{Snowflake, TokenBucket}()

# --- Helpers ---
function get_history(channel_id)
    get!(conversations, channel_id, Dict{String,String}[])
end

function add_to_history!(channel_id, role, content)
    history = get_history(channel_id)
    push!(history, Dict("role" => role, "content" => content))
    while length(history) > MAX_HISTORY
        popfirst!(history)
    end
end

mutable struct TokenBucket
    tokens::Float64
    max_tokens::Float64
    refill_rate::Float64
    last_refill::Float64
end
TokenBucket(max_t, rate) = TokenBucket(max_t, max_t, rate, time())

function try_consume!(b::TokenBucket)
    elapsed = time() - b.last_refill
    b.tokens = min(b.max_tokens, b.tokens + elapsed * b.refill_rate)
    b.last_refill = time()
    b.tokens >= 1.0 || return false
    b.tokens -= 1.0
    return true
end

function check_rate_limit(user_id)
    bucket = get!(user_buckets, user_id) do; TokenBucket(5.0, 0.1) end
    try_consume!(bucket)
end

# --- API Call ---
function call_llm(messages; api_key=ENV["OPENAI_API_KEY"])
    body = Dict(
        "model" => "gpt-4o",
        "messages" => messages,
        "max_tokens" => 1024,
        "stream" => false,
    )
    resp = HTTP.post(
        "https://api.openai.com/v1/chat/completions",
        ["Authorization" => "Bearer \$api_key", "Content-Type" => "application/json"],
        JSON3.write(body)
    )
    data = JSON3.read(resp.body)
    return data["choices"][1]["message"]["content"]
end

# --- Commands ---

# /chat <message>
options_chat = [
    command_option(type=ApplicationCommandOptionTypes.STRING, name="message", description="Your message", required=true),
]

@slash_command client "chat" "Chat with the AI" options_chat function(ctx)
    user_id = ctx.interaction.member.user.id
    channel_id = ctx.interaction.channel_id

    # Rate limit check
    if !check_rate_limit(user_id)
        respond(ctx; content="You're sending messages too fast. Please wait a moment.", ephemeral=true)
        return
    end

    user_msg = get_option(ctx, "message", "")::String
    defer(ctx)

    # Build messages with history
    add_to_history!(channel_id, "user", user_msg)
    messages = vcat(
        [Dict("role" => "system", "content" => SYSTEM_PROMPT)],
        get_history(channel_id)
    )

    try
        response = call_llm(messages)

        # Truncate if needed
        if length(response) > 1990
            response = response[1:1990] * "..."
        end

        add_to_history!(channel_id, "assistant", response)
        respond(ctx; content=response)
    catch e
        @error "LLM call failed" exception=e
        respond(ctx; content="Sorry, I couldn't process that request. Please try again.")
    end
end

# /clear-history
@slash_command client "clear-history" "Clear conversation history" function(ctx)
    channel_id = ctx.interaction.channel_id
    conversations[channel_id] = Dict{String,String}[]
    respond(ctx; content="Conversation history cleared.", ephemeral=true)
end

# /model-info
@slash_command client "model-info" "Show AI model info" function(ctx)
    channel_id = ctx.interaction.channel_id
    history_len = length(get_history(channel_id))

    e = embed(
        title="AI Assistant Info",
        color=0x5865F2,
        fields=[
            Dict("name" => "Model", "value" => "GPT-4o", "inline" => true),
            Dict("name" => "History", "value" => "\$history_len / \$MAX_HISTORY messages", "inline" => true),
            Dict("name" => "Rate Limit", "value" => "5 requests / 50 seconds", "inline" => true),
        ]
    )
    respond(ctx; embeds=[e], ephemeral=true)
end

# --- Wiring ---
on(client, InteractionCreate) do c, event
    dispatch_interaction!(tree, c, event.interaction)
end

on(client, ReadyEvent) do c, event
    sync_commands!(c, tree)
    @info "AI Agent bot ready!" user=event.user.username
end

start(client)
```

## 8. Advanced: Voice-Commanded AI Agent

Combine [Recipe 05 (Voice)](05-voice.md) with this recipe for a voice-commanded agent:

```julia
# Architecture:
# 1. User speaks in voice channel
# 2. Capture audio → PCM buffer
# 3. Detect silence → trim audio
# 4. pcm_to_wav() → WAV bytes
# 5. Whisper API → transcript text
# 6. Send transcript to LLM
# 7. LLM response → text channel (or TTS → voice playback)

# The voice capture code from Recipe 05 feeds into:
function handle_voice_transcript(client, channel_id, transcript)
    # Add to conversation and get AI response
    add_to_history!(channel_id, "user", "[Voice] \$transcript")

    messages = vcat(
        [Dict("role" => "system", "content" => SYSTEM_PROMPT)],
        get_history(channel_id)
    )

    response = call_llm(messages)
    add_to_history!(channel_id, "assistant", response)

    create_message(client, channel_id; content=response)
end
```

## 9. Choosing an LLM Provider

| Provider | Strengths | Cost | Local? |
|----------|-----------|------|--------|
| OpenAI GPT-4o | Tool calling, streaming, function calling | $$$ | No |
| Anthropic Claude | Long context, careful reasoning | $$$ | No |
| Ollama (Llama 3) | Free, private, no rate limits | Free | Yes |
| Ollama (Mistral) | Fast, good quality/speed ratio | Free | Yes |

For development, start with Ollama (free, no API key needed). For production, choose based on your quality/cost requirements.

---

This recipe brings together everything in the cookbook: slash commands, embeds, async patterns, and external API integration. You now have all the tools to build production Discord bots in Julia.

**Back to:** [Cookbook Index](@ref cookbook-index)
