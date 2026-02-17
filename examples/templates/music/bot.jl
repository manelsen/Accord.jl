using Accord
using DotEnv

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")

# Intents necessários para Voz: GuildVoiceStates
client = Client(TOKEN; intents = IntentGuilds | IntentGuildVoiceStates)

# --- Estado de Voz ---
# Mantemos o player de cada guilda no estado do cliente ou num dicionário global
# Aqui usamos um Dict simples mapeando GuildID -> VoiceClient
const voice_sessions = Dict{Int, VoiceClient}()

# --- Comandos ---

@slash_command client "join" "Entra no seu canal de voz" function(ctx)
    # Verifica se o usuário está em um canal de voz
    guild = get_guild(ctx.client, ctx.guild_id)
    # Nota: Precisamos pegar o estado de voz do membro. 
    # O cache de VoiceState deve estar ativado ou consultamos via API se cache falhar.
    
    # Simplificação: O usuário deve fornecer o ID do canal ou estar no mesmo canal.
    # Para este exemplo, vamos simplificar e pedir o ID ou pegar do cache se disponível.
    
    # Vamos tentar pegar o canal de voz do usuário que executou o comando (requer Cache)
    member_vs = get(client.state.voice_states, (ctx.guild_id, ctx.user.id), nothing)
    
    if isnothing(member_vs) || isnothing(member_vs.channel_id)
        respond(ctx; content="Você precisa estar em um canal de voz!", ephemeral=true)
        return
    end
    
    channel_id = member_vs.channel_id
    
    defer(ctx) # Conectar pode demorar
    
    try
        vc = connect!(ctx.client, ctx.guild_id, channel_id)
        voice_sessions[Int(ctx.guild_id)] = vc
        respond(ctx; content="Conectado ao canal <#$channel_id>! 🔊")
    catch e
        respond(ctx; content="Erro ao conectar: $e")
    end
end

@slash_command client "play" "Toca um áudio (URL ou Arquivo)" options=[
    command_option(name="url", description="Link do YouTube/Arquivo ou caminho local", required=true)
] function(ctx)
    url = get_option(ctx, "url")
    guild_id = Int(ctx.guild_id)
    
    if !haskey(voice_sessions, guild_id)
        respond(ctx; content="Não estou conectado em nenhum canal. Use `/join` primeiro.", ephemeral=true)
        return
    end
    
    vc = voice_sessions[guild_id]
    
    defer(ctx)
    
    # Cria uma fonte de áudio usando FFmpeg (suporta YouTube se youtube-dl/yt-dlp estiver no PATH e configurado, ou arquivos locais/http diretos)
    # Para YouTube real, recomendasse usar uma lib wrapper do yt-dlp antes de passar pro FFmpegSource
    source = FFmpegSource(url)
    
    play!(vc, source)
    
    respond(ctx; content="▶️ Tocando: $url")
end

@slash_command client "stop" "Para a música" function(ctx)
    guild_id = Int(ctx.guild_id)
    if haskey(voice_sessions, guild_id)
        stop!(voice_sessions[guild_id])
        respond(ctx; content="⏹️ Parado.")
    else
        respond(ctx; content="Nada tocando.", ephemeral=true)
    end
end

@slash_command client "leave" "Sai do canal de voz" function(ctx)
    guild_id = Int(ctx.guild_id)
    if haskey(voice_sessions, guild_id)
        disconnect!(voice_sessions[guild_id])
        delete!(voice_sessions, guild_id)
        respond(ctx; content="👋 Tchau!")
    else
        respond(ctx; content="Não estou conectado.", ephemeral=true)
    end
end

on(client, ReadyEvent) do c, event
    @info "MusicBot pronto!"
    sync_commands!(c)
end

start(client)
