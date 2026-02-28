using Accord
using DotEnv

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")

# Voice Intents: GuildVoiceStates
client = Client(TOKEN; intents = IntentGuilds | IntentGuildVoiceStates)

# --- Voice State ---
# We keep track of the voice player for each guild.
# Mapping GuildID -> VoiceClient
const voice_sessions = Dict{Int, VoiceClient}()

# --- Commands ---

@slash_command client "join" "Joins your voice channel" function(ctx)
    # Check if user is in a voice channel
    guild = get_guild(ctx.client, ctx.guild_id)
    # Note: We need to get the member's voice state.
    # VoiceState cache should be enabled or queried via API.
    
    # Simple check: user must be in a voice channel.
    # Attempt to get voice state of user who executed command (requires Cache)
    member_vs = get(client.state.voice_states, (ctx.guild_id, ctx.user.id), nothing)
    
    if isnothing(member_vs) || isnothing(member_vs.channel_id)
        respond(ctx; content="You need to be in a voice channel!", ephemeral=true)
        return
    end
    
    channel_id = member_vs.channel_id
    
    defer(ctx) # Connecting can take time
    
    try
        vc = connect!(ctx.client, ctx.guild_id, channel_id)
        voice_sessions[Int(ctx.guild_id)] = vc
        respond(ctx; content="Connected to <#$channel_id>! 🔊")
    catch e
        respond(ctx; content="Error connecting: $e")
    end
end

@slash_command client "play" "Plays audio (URL or File)" options=[
    command_option(name="url", description="YouTube link, direct file or local path", required=true)
] function(ctx)
    url = get_option(ctx, "url")
    guild_id = Int(ctx.guild_id)
    
    if !haskey(voice_sessions, guild_id)
        respond(ctx; content="I'm not connected to any channel. Use `/join` first.", ephemeral=true)
        return
    end
    
    vc = voice_sessions[guild_id]
    
    defer(ctx)
    
    # Create audio source using FFmpeg (supports YouTube if youtube-dl/yt-dlp is in PATH, or local/http files)
    # For real YouTube usage, a wrapper for yt-dlp is recommended before passing to FFmpegSource
    source = FFmpegSource(url)
    
    play!(vc, source)
    
    respond(ctx; content="▶️ Playing: $url")
end

@slash_command client "stop" "Stops the music" function(ctx)
    guild_id = Int(ctx.guild_id)
    if haskey(voice_sessions, guild_id)
        stop!(voice_sessions[guild_id])
        respond(ctx; content="⏹️ Stopped.")
    else
        respond(ctx; content="Nothing is playing.", ephemeral=true)
    end
end

@slash_command client "leave" "Leaves the voice channel" function(ctx)
    guild_id = Int(ctx.guild_id)
    if haskey(voice_sessions, guild_id)
        disconnect!(voice_sessions[guild_id])
        delete!(voice_sessions, guild_id)
        respond(ctx; content="👋 Bye!")
    else
        respond(ctx; content="I'm not connected.", ephemeral=true)
    end
end

on(client, ReadyEvent) do c, event
    @info "MusicBot ready!"
    sync_commands!(c)
end

start(client)
