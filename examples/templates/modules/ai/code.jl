# AI Module
# Integrates with OpenAI for intelligent chat and assistance.

using Accord
using HTTP
using JSON3

function setup_ai(client::Client)
    # Configuration - Reads OPENAI_API_KEY from environment
    api_key = get(ENV, "OPENAI_API_KEY", "")
    model = "gpt-4o-mini"

    @slash_command client "ask" "Ask the AI assistant anything" [
        @option String "prompt" "Your question" required=true
    ] function(ctx)
        prompt = Accord.get_option(ctx, "prompt")

        if isempty(api_key)
            return Accord.respond(ctx; content="❌ OpenAI API key not configured. Set `OPENAI_API_KEY`.", ephemeral=true)
        end

        Accord.defer(ctx)  # the API call can take longer than Discord's 3 seconds

        answer = try
            body = Dict("model" => model, "messages" => [Dict("role" => "user", "content" => prompt)])
            resp = HTTP.post("https://api.openai.com/v1/chat/completions",
                ["Authorization" => "Bearer $api_key", "Content-Type" => "application/json"],
                JSON3.write(body))
            JSON3.read(resp.body).choices[1].message.content
        catch e
            @error "AI request failed" exception=e
            "❌ Failed to get a response from the AI."
        end
        Accord.respond(ctx; content=first("**Prompt:** $prompt\n\n**AI:** $answer", 2000))
    end

    println("🧠 AI module loaded (Requires OPENAI_API_KEY).")
end
