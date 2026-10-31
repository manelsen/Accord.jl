# Music Module
# Provides basic voice and music playback functionality.
# Needs FFmpeg on the PATH, the Guild Voice States intent, and libdave
# (set ACCORD_LIBDAVE; see the voice recipe in Accord's docs).

using Accord

function setup_music(client::Client)
    # Track active voice clients per guild. Handlers run in parallel, so guard the Dict.
    voice_clients = Dict{Snowflake, VoiceClient}()
    vc_lock = ReentrantLock()

    @slash_command client "join" "Joins a voice channel" [
        @option Channel "channel" "The voice channel to join" required=true channel_types=[ChannelTypes.GUILD_VOICE, ChannelTypes.GUILD_STAGE_VOICE]
    ] function(ctx)
        channel_id = Snowflake(Accord.get_option(ctx, "channel"))
        Accord.defer(ctx)  # connecting takes a few seconds

        try
            vc = VoiceClient(ctx.client, ctx.guild_id, channel_id)
            Accord.connect!(vc)
            lock(() -> voice_clients[ctx.guild_id] = vc, vc_lock)
            Accord.respond(ctx; content="Joined <#$channel_id>! 🎶")
        catch e
            @error "Failed to join voice" exception=e
            Accord.respond(ctx; content="❌ Could not join <#$channel_id>.")
        end
    end

    @slash_command client "play" "Plays a file or stream URL in the voice channel" [
        @option String "url" "The URL or file to play" required=true
    ] function(ctx)
        url = Accord.get_option(ctx, "url")
        vc = lock(() -> get(voice_clients, ctx.guild_id, nothing), vc_lock)
        if isnothing(vc)
            return Accord.respond(ctx; content="❌ I am not in a voice channel. Use `/join` first.", ephemeral=true)
        end

        try
            Accord.play!(vc, FFmpegSource(url))
            Accord.respond(ctx; content="Now playing: $url 🔊")
        catch e
            @error "Failed to play audio" exception=e
            Accord.respond(ctx; content="❌ Failed to play audio.", ephemeral=true)
        end
    end

    @slash_command client "stop" "Stops playback and leaves the voice channel" function(ctx)
        vc = lock(() -> pop!(voice_clients, ctx.guild_id, nothing), vc_lock)
        if isnothing(vc)
            return Accord.respond(ctx; content="❌ I am not in a voice channel.", ephemeral=true)
        end
        Accord.disconnect!(vc)
        Accord.respond(ctx; content="Stopped and disconnected. 👋")
    end

    println("🎵 Music module loaded (Requires FFmpeg).")
end
