# AI Module
# Integrates with OpenAI for intelligent chat and assistance.

using Accord
using HTTP
using JSON3

function setup_ai(client::Client)
    # Configuration - Reads OPENAI_API_KEY from environment
    API_KEY = get(ENV, "OPENAI_API_KEY", "")
    MODEL = "gpt-3.5-turbo"

    @slash_command client "ask" "Ask the AI assistant anything" [
        @option String "prompt" "Your question" required=true
    ] do ctx
        prompt = get_option(ctx, "prompt")
        
        if isempty(API_KEY)
            return respond(ctx, content="❌ OpenAI API key not configured. Set `OPENAI_API_KEY`.", flags=MsgFlagEphemeral)
        end

        defer(ctx)

        try
            body = Dict(
                "model" => MODEL,
                "messages" => [Dict("role" => "user", "content" => prompt)]
            )
            
            resp = HTTP.post("https://api.openai.com/v1/chat/completions",
                ["Authorization" => "Bearer $API_KEY", "Content-Type" => "application/json"],
                JSON3.write(body)
            )
            
            data = JSON3.read(resp.body)
            answer = data.choices[1].message.content
            
            followup(ctx, content="**Prompt:** $prompt\n\n**AI:** $answer")
        catch e
            followup(ctx, content="❌ Failed to get a response from the AI.")
        end
    end

    println("🧠 AI module loaded (Requires OPENAI_API_KEY).")
end
