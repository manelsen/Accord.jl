using Accord
using DotEnv
using HTTP
using JSON3
using LRUCache

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const OPENAI_KEY = get(ENV, "OPENAI_API_KEY", "")

# Conversation cache: the recent messages of up to 100 users.
# LRUCache is thread-safe; each user's history is only touched by their own commands.
const CONVERSATIONS = LRU{Snowflake, Vector{Dict{String, String}}}(maxsize=100)

client = Client(TOKEN; intents = IntentGuilds)

# --- API Function ---
function ask_gpt(history)
    if isempty(OPENAI_KEY)
        return "⚠️ **Error:** API Key not configured. Set `OPENAI_API_KEY` in .env."
    end

    try
        resp = HTTP.post("https://api.openai.com/v1/chat/completions",
            ["Authorization" => "Bearer $OPENAI_KEY", "Content-Type" => "application/json"],
            JSON3.write(Dict("model" => "gpt-4o-mini", "messages" => history)))
        return JSON3.read(resp.body).choices[1].message.content
    catch e
        @error "AI API Error" exception=e
        return "Sorry, I had a problem processing your request."
    end
end

# --- Commands ---

@slash_command client "chat" "Chat with the AI" [
    @option String "prompt" "Your message" required=true
] function(ctx)
    prompt = Accord.get_option(ctx, "prompt")
    history = get!(() -> Dict{String, String}[], CONVERSATIONS, ctx.user.id)

    push!(history, Dict("role" => "user", "content" => prompt))
    # Keep history short (last 6 messages) to save tokens
    length(history) > 6 && popfirst!(history)

    # The API can take longer than Discord's 3 seconds. Handlers run in their
    # own task, so waiting here doesn't block the gateway.
    Accord.defer(ctx)
    reply_content = ask_gpt(history)
    push!(history, Dict("role" => "assistant", "content" => reply_content))

    # Discord messages are limited to 2000 characters
    Accord.respond(ctx; content=first(reply_content, 2000))
end

@slash_command client "reset" "Clear conversation history" function(ctx)
    delete!(CONVERSATIONS, ctx.user.id)
    Accord.respond(ctx; content="🧠 Memory cleared. We can start fresh!", ephemeral=true)
end

Accord.on(client, ReadyEvent) do c, event
    @info "AI Bot online!"
    sync_commands!(c, c.command_tree)
end

Accord.start(client)
