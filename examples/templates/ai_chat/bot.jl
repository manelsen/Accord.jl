using Accord
using DotEnv
using HTTP
using JSON3
using LRUCache

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")
const OPENAI_KEY = get(ENV, "OPENAI_API_KEY", "")

# Cache de conversas: Armazena as últimas 10 mensagens de cada usuário
# Chave: user_id, Valor: Vector{Dict} (histórico)
const CONVERSATIONS = LRU{Int, Vector{Dict{Symbol, String}}}(maxsize=100)

client = Client(TOKEN; intents = IntentGuilds)

# --- Função de API (Simulada/Real) ---
function ask_gpt(history)
    if isempty(OPENAI_KEY)
        return "⚠️ **Erro:** API Key não configurada. Configure `OPENAI_API_KEY` no .env."
    end

    try
        # Chamada real à API da OpenAI
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
        @error "Erro na API AI" exception=e
        return "Desculpe, tive um problema ao processar sua solicitação."
    end
end

# --- Comandos ---

@slash_command client "chat" "Converse com a IA" options=[
    command_option(name="prompt", description="Sua mensagem", required=true)
] function(ctx)
    prompt = get_option(ctx, "prompt")
    user_id = Int(ctx.user.id)
    
    # 1. Recupera ou cria histórico
    history = get!(CONVERSATIONS, user_id) do
        Dict{Symbol, String}[]
    end
    
    # 2. Adiciona msg do usuário
    push!(history, Dict(:role => "user", :content => prompt))
    
    # Mantém histórico curto (últimas 6 msgs) para economizar tokens
    if length(history) > 6
        popfirst!(history)
    end
    
    defer(ctx) # API pode demorar
    
    # 3. Chama a IA
    reply_content = ask_gpt(history)
    
    # 4. Adiciona resposta da IA ao histórico
    push!(history, Dict(:role => "assistant", :content => reply_content))
    
    # 5. Responde no Discord (limitado a 2000 chars)
    # Se for maior, deveria enviar como arquivo ou dividir.
    respond(ctx; content=first(reply_content, 2000))
end

@slash_command client "reset" "Apaga o histórico da conversa" function(ctx)
    user_id = Int(ctx.user.id)
    delete!(CONVERSATIONS, user_id)
    respond(ctx; content="🧠 Memória apagada. Podemos começar do zero!", ephemeral=true)
end

on(client, ReadyEvent) do c, event
    @info "AI Bot online!"
    sync_commands!(c)
end

start(client)
