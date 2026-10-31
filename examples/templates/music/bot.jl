using Accord
using DotEnv

DotEnv.config()
const TOKEN = get(ENV, "DISCORD_TOKEN", "")

# Voice needs the Guild Voice States intent, FFmpeg on the PATH, and libdave
# (set ACCORD_LIBDAVE; see the voice recipe in Accord's docs).
client = Client(TOKEN; intents = IntentGuilds | Accord.IntentGuildVoiceStates)

# --- Voice State ---
# The voice client of each guild. Handlers run in parallel, so guard the Dict.
const voice_sessions = Dict{Snowflake, VoiceClient}()
const sessions_lock = ReentrantLock()

session(guild_id) = lock(() -> get(voice_sessions, guild_id, nothing), sessions_lock)

# --- Commands ---

@slash_command client "join" "Joins a voice channel" [
    @option Channel "channel" "The voice channel to join" required=true channel_types=[ChannelTypes.GUILD_VOICE, ChannelTypes.GUILD_STAGE_VOICE]
] function(ctx)
    channel_id = Snowflake(Accord.get_option(ctx, "channel"))
    Accord.defer(ctx)  # connecting takes a few seconds

    try
        vc = VoiceClient(ctx.client, ctx.guild_id, channel_id)
        Accord.connect!(vc)
        lock(() -> voice_sessions[ctx.guild_id] = vc, sessions_lock)
        Accord.respond(ctx; content="Connected to <#$channel_id>! 🔊")
    catch e
        @error "Failed to join voice" exception=e
        Accord.respond(ctx; content="Error connecting to <#$channel_id>.")
    end
end

@slash_command client "play" "Plays audio (URL or file)" [
    @option String "url" "Direct file URL, stream or local path" required=true
] function(ctx)
    url = Accord.get_option(ctx, "url")
    vc = session(ctx.guild_id)
    if isnothing(vc)
        return Accord.respond(ctx; content="I'm not connected to any channel. Use `/join` first.", ephemeral=true)
    end

    # FFmpeg reads local files and http(s) URLs. For YouTube, resolve the
    # stream URL with yt-dlp first and pass that.
    Accord.play!(vc, FFmpegSource(url))
    Accord.respond(ctx; content="▶️ Playing: $url")
end

@slash_command client "stop" "Stops the music" function(ctx)
    vc = session(ctx.guild_id)
    if isnothing(vc)
        return Accord.respond(ctx; content="Nothing is playing.", ephemeral=true)
    end
    Accord.stop!(vc)
    Accord.respond(ctx; content="⏹️ Stopped.")
end

@slash_command client "leave" "Leaves the voice channel" function(ctx)
    vc = lock(() -> pop!(voice_sessions, ctx.guild_id, nothing), sessions_lock)
    if isnothing(vc)
        return Accord.respond(ctx; content="I'm not connected.", ephemeral=true)
    end
    Accord.disconnect!(vc)
    Accord.respond(ctx; content="👋 Bye!")
end

Accord.on(client, ReadyEvent) do c, event
    @info "MusicBot ready!"
    sync_commands!(c, c.command_tree)
end

Accord.start(client)
