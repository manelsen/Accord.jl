# Audio player — abstract source and playback control
#
# Internal module: Defines the AbstractAudioSource interface and AudioPlayer loop.
# Sources provide PCM frames; the player encodes to Opus and sends via a callback.

"""
    AbstractAudioSource

Use this abstract type when implementing custom audio sources for voice playback.

Base type for audio sources. Subtypes must implement:
- `read_frame(source) -> Union{Vector{Int16}, Nothing}` — read one frame of PCM audio (960 samples * channels)
- `close_source(source)` — cleanup
"""
abstract type AbstractAudioSource end

"""Use this to retrieve audio data from a source during playback.

Read one PCM frame from the source. Returns nothing when done."""
function read_frame end

"""Use this to release resources when done playing audio from a source.

Close/cleanup the audio source."""
function close_source end

"""
    AudioPlayer

Use this to manage audio playback in voice channels including play, pause, and stop operations.

Controls playback of audio to a voice connection.
"""
mutable struct AudioPlayer
    source::Nullable{AbstractAudioSource}
    encoder::Nullable{OpusEncoder}
    playing::Bool
    paused::Bool
    volume::Float64  # 0.0 to 2.0
    task::Nullable{Task}
end

function AudioPlayer()
    AudioPlayer(nothing, nothing, false, false, 1.0, nothing)
end

"""
    play!(player, source, send_fn)

Use this to begin playing audio from a source through a voice connection.

Start playing an audio source. `send_fn(opus_data)` is called for each encoded frame.
"""
function play!(player::AudioPlayer, source::AbstractAudioSource, send_fn::Function)
    stop!(player)

    player.source = source
    player.playing = true
    player.paused = false

    if isnothing(player.encoder)
        player.encoder = OpusEncoder()
    end

    player.task = @async _playback_loop(player, send_fn)
    return player
end

"""Use this to immediately stop audio playback and clean up the source.

Stop playback."""
function stop!(player::AudioPlayer)
    player.playing = false
    if !isnothing(player.source)
        try
            close_source(player.source)
        catch e
            @warn "Error closing audio source" exception=e
        end
        player.source = nothing
    end
end

"""Use this to temporarily pause audio playback without releasing resources.

Pause playback."""
function pause!(player::AudioPlayer)
    player.paused = true
end

"""Use this to continue playing audio after a pause.

Resume playback."""
function resume!(player::AudioPlayer)
    player.paused = false
end

"""Use this to determine whether audio is currently being played.

Check if the player is currently playing."""
is_playing(player::AudioPlayer) = player.playing && !isnothing(player.source)

function _playback_loop(player::AudioPlayer, send_fn::Function)
    frame_duration = OPUS_FRAME_DURATION_MS / 1000.0  # 20ms
    next_send = time()

    while player.playing && !isnothing(player.source)
        if player.paused
            sleep(0.05)
            next_send = time()
            continue
        end

        # Read PCM frame
        pcm = try
            read_frame(player.source)
        catch e
            @warn "Error reading audio frame" exception=e
            nothing
        end

        if isnothing(pcm)
            # Source exhausted
            player.playing = false
            break
        end

        # Apply volume
        if player.volume != 1.0
            pcm = round.(Int16, clamp.(Float64.(pcm) .* player.volume, -32768, 32767))
        end

        # Encode to Opus
        encoder = player.encoder
        if isnothing(encoder)
            @warn "No Opus encoder available"
            player.playing = false
            break
        end
        opus_data = try
            opus_encode(encoder, pcm)
        catch e
            @warn "Opus encode error" exception=e
            continue
        end

        # Send
        try
            send_fn(opus_data)
        catch e
            @warn "Error sending voice data" exception=e
            player.playing = false
            break
        end

        # Timing: maintain 20ms cadence
        next_send += frame_duration
        sleep_time = next_send - time()
        if sleep_time > 0
            sleep(sleep_time)
        end
    end

    @debug "Playback loop ended"
end
