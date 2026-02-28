# Music Module
# Provides basic voice and music playback functionality.

using Accord

function setup_music(client::Client)
    # Track active voice clients per guild
    const voice_clients = Dict{Snowflake, VoiceClient}()

    @slash_command client begin
        name = "join"
        description = "Joins your current voice channel"
    end
    function join_cmd(ctx)
        guild_id = ctx.interaction.guild_id
        
        # Find user's voice state
        guild = fetch_guild(ctx.client, guild_id)
        vs = findfirst(s -> s.user_id == ctx.interaction.member.user.id, guild.voice_states)
        
        if isnothing(vs) || ismissing(vs.channel_id) || isnothing(vs.channel_id)
            return respond(ctx, content="❌ You must be in a voice channel first!", flags=MsgFlagEphemeral)
        end

        vc = connect!(ctx.client, guild_id, vs.channel_id)
        voice_clients[guild_id] = vc
        
        respond(ctx, content="Joined <#\$(vs.channel_id)>! 🎶")
    end

    @slash_command client begin
        name = "play"
        description = "Plays a stream (URL) in the voice channel"
        @option url String "The URL to play (must be compatible with FFmpeg)" required=true
    end
    function play_cmd(ctx)
        guild_id = ctx.interaction.guild_id
        url = get_option(ctx, "url")
        
        if !haskey(voice_clients, guild_id)
            return respond(ctx, content="❌ I am not in a voice channel. Use `/join` first.", flags=MsgFlagEphemeral)
        end

        vc = voice_clients[guild_id]
        
        try
            # Create FFmpeg source
            source = FFmpegSource(url)
            play!(vc, source)
            respond(ctx, content="Now playing: \$(url) 🔊")
        catch e
            respond(ctx, content="❌ Failed to play audio. Check the URL.", flags=MsgFlagEphemeral)
        end
    end

    @slash_command client begin
        name = "stop"
        description = "Stops playback and leaves the voice channel"
    end
    function stop_cmd(ctx)
        guild_id = ctx.interaction.guild_id
        
        if haskey(voice_clients, guild_id)
            vc = voice_clients[guild_id]
            disconnect!(vc)
            delete!(voice_clients, guild_id)
            respond(ctx, content="Stopped and disconnected. 👋")
        else
            respond(ctx, content="❌ I am not in a voice channel.", flags=MsgFlagEphemeral)
        end
    end

    println("🎵 Music module loaded (Requires FFmpeg).")
end
