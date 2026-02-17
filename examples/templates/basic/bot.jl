using Accord
using DotEnv

# Carrega variáveis de ambiente do arquivo .env (se existir)
DotEnv.config()

# Token do Bot
const TOKEN = get(ENV, "DISCORD_TOKEN", "")

if isempty(TOKEN)
    println("Erro: DISCORD_TOKEN não encontrado. Crie um arquivo .env ou defina a variável de ambiente.")
    exit(1)
end

# Inicializa o Cliente
# Intents básicos: Guilds (para comandos slash)
client = Client(TOKEN; intents = IntentGuilds)

# --- Eventos ---

on(client, ReadyEvent) do c, event
    @info "Bot conectado! Logado como $(event.user.username)"
    
    # Registra os comandos slash definidos abaixo
    # Em produção, você pode querer registrar globalmente (pode demorar 1h)
    # ou por guilda (imediato) passando guild_id=...
    sync_commands!(c)
end

# --- Comandos ---

@slash_command client "ping" "Verifica a latência do bot" function(ctx)
    # Responde à interação
    respond(ctx; content="Pong! 🏓")
end

@slash_command client "hello" "Diz olá para o usuário" function(ctx)
    user = ctx.user
    respond(ctx; content="Olá, **$(user.username)**! Bem-vindo ao Accord.jl.")
end

# --- Execução ---

@info "Iniciando o bot..."
start(client)
