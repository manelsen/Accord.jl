# Music Module
# Provides basic voice and music playback functionality.

using Accord

function setup_music(client::Client)
    # Track active voice clients per guild
    # Local to the setup function to avoid collisions
    voice_clients = Dict{Snowflake, VoiceClient}()

    @slash_command client "join" "Joins your current voice channel" do ctx
        guild_id = ctx.interaction.guild_id
        guild = fetch_guild(ctx.client, guild_id)
        
        # Simple search for user's voice state
        vs = nothing
        if !ismissing(guild.voice_states)
            idx = findfirst(s -> s.user_id == ctx.interaction.member.user.id, guild.voice_states)
            vs = isnothing(idx) ? nothing : guild.voice_states[idx]
        end
        
        if isnothing(vs) || ismissing(vs.channel_id) || isnothing(vs.channel_id)
            return respond(ctx, content="❌ You must be in a voice channel first!", flags=MsgFlagEphemeral)
        end

        vc = connect!(ctx.client, guild_id, vs.channel_id)
        voice_clients[guild_id] = vc
        
        respond(ctx, content="Joined <#$(vs.channel_id)>! 🎶")
    end

    @slash_command client "play" "Plays a stream (URL) in the voice channel" [
        @option String "url" "The URL to play" required=true
    ] do ctx
        guild_id = ctx.interaction.guild_id
        url = get_option(ctx, "url")
        
        if !haskey(voice_clients, guild_id)
            return respond(ctx, content="❌ I am not in a voice channel. Use `/join` first.", flags=MsgFlagEphemeral)
        end

        vc = voice_clients[guild_id]
        
        try
            source = FFmpegSource(url)
            play!(vc, source)
            respond(ctx, content="Now playing: $(url) 🔊")
        catch e
            respond(ctx, content="❌ Failed to play audio.", flags=MsgFlagEphemeral)
        end
    end

    @slash_command client "stop" "Stops playback and leaves the voice channel" do ctx
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
