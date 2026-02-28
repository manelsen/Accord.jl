using Accord
using DotEnv
using HTTP
using JSON3
using LRUCache

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const OPENAI_KEY = get(ENV, "OPENAI_API_KEY", "")

# Conversation Cache: Stores the last 10 messages for each user
# Key: user_id, Value: Vector{Dict} (history)
const CONVERSATIONS = LRU{Int, Vector{Dict{Symbol, String}}}(maxsize=100)

client = Client(TOKEN; intents = IntentGuilds)

# --- API Function (Real/Mock) ---
function ask_gpt(history)
    if isempty(OPENAI_KEY)
        return "⚠️ **Error:** API Key not configured. Set `OPENAI_API_KEY` in .env."
    end

    try
        # Real call to OpenAI API
        resp = HTTP.post("https://api.openai.com/v1/chat/completions",
            ["Authorization" => "Bearer $OPENAI_KEY", "Content-Type" => "application/json"],
            JSON3.write(Dict(
                "model" => "gpt-3.5-turbo",
                "messages" => history
            ))
        )
        json = JSON3.read(resp.body)
        return json.choices[1].message.content
    catch e
        @error "AI API Error" exception=e
        return "Sorry, I had a problem processing your request."
    end
end

# --- Commands ---

@slash_command client "chat" "Chat with the AI" options=[
    command_option(name="prompt", description="Your message", required=true)
] function(ctx)
    prompt = get_option(ctx, "prompt")
    user_id = Int(ctx.user.id)
    
    # 1. Retrieve or create history
    history = get!(CONVERSATIONS, user_id) do
        Dict{Symbol, String}[]
    end
    
    # 2. Add user message
    push!(history, Dict(:role => "user", :content => prompt))
    
    # Keep history short (last 6 msgs) to save tokens
    if length(history) > 6
        popfirst!(history)
    end
    
    defer(ctx) # API might take some time
    
    # 3. Call the AI (in a separate Task to not block the Gateway)
    @async begin
        reply_content = ask_gpt(history)
        
        # 4. Add AI response to history
        push!(history, Dict(:role => "assistant", :content => reply_content))
        
        # 5. Respond on Discord (limited to 2000 chars)
        respond(ctx; content=first(reply_content, 2000))
    end
end

@slash_command client "reset" "Clear conversation history" function(ctx)
    user_id = Int(ctx.user.id)
    delete!(CONVERSATIONS, user_id)
    respond(ctx; content="🧠 Memory cleared. We can start fresh!", ephemeral=true)
end

on(client, ReadyEvent) do c, event
    @info "AI Bot online!"
    sync_commands!(c)
end

start(client)
