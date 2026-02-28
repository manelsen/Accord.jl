# AI Module
# Integrates with OpenAI for intelligent chat and assistance.

using Accord
using HTTP
using JSON3

function setup_ai(client::Client)
    # Configuration - Reads OPENAI_API_KEY from environment
    const API_KEY = get(ENV, "OPENAI_API_KEY", "")
    const MODEL = "gpt-3.5-turbo" # Or gpt-4

    @slash_command client begin
        name = "ask"
        description = "Ask the AI assistant anything"
        @option prompt String "Your question or prompt" required=true
    end
    function ask_cmd(ctx)
        prompt = get_option(ctx, "prompt")
        
        if isempty(API_KEY)
            return respond(ctx, content="❌ OpenAI API key not configured. Set `OPENAI_API_KEY`.", flags=MsgFlagEphemeral)
        end

        # Defer because AI can take a few seconds
        defer(ctx)

        try
            # Call OpenAI API
            body = Dict(
                "model" => MODEL,
                "messages" => [Dict("role" => "user", "content" => prompt)]
            )
            
            resp = HTTP.post("https://api.openai.com/v1/chat/completions",
                ["Authorization" => "Bearer \$API_KEY", "Content-Type" => "application/json"],
                JSON3.write(body)
            )
            
            data = JSON3.read(resp.body)
            answer = data.choices[1].message.content
            
            # Send followup since we deferred
            followup(ctx, content="**Prompt:** \$prompt

**AI:** \$answer")
        catch e
            @error "AI Request failed" exception=e
            followup(ctx, content="❌ Failed to get a response from the AI. Try again later.")
        end
    end

    println("🧠 AI module loaded (Requires OPENAI_API_KEY).")
end
