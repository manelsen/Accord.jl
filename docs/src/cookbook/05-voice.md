# Recipe 05 — Voice: Playback, Recording & Transcription

**Difficulty:** Advanced
**What you will build:** A voice bot that plays audio, records speech, and transcribes it with the Whisper API.

**Prerequisites:** [Recipe 03](03-slash-commands.md), `ffmpeg` installed, `IntentGuildVoiceStates` enabled

---

!!! warning "System Dependencies for Voice"
    Accord.jl's voice support requires:
    - **Opus_jll** and **libsodium_jll** — bundled automatically via JLL packages
    - **FFmpeg** — must be installed on your system and available in PATH for [`FFmpegSource`](@ref)
    
    Install FFmpeg:
    - Ubuntu/Debian: `sudo apt-get install ffmpeg`
    - macOS: `brew install ffmpeg`
    - Windows: Download from https://ffmpeg.org/download.html

## 1. Prerequisites

```julia
client = Client(token;
    intents = IntentGuilds | IntentGuildVoiceStates
)
```

!!! note "Voice Connection Timeout Behavior"
    Voice connections may take several seconds to establish as they require:
    1. Gateway handshake (VOICE_STATE_UPDATE)
    2. Voice server assignment (VoiceServerUpdate event)
    3. Voice WebSocket connection
    4. UDP IP discovery
    5. Encryption negotiation
    
    If [`connect!`](@ref) hangs, verify `IntentGuildVoiceStates` is enabled and the bot has permission to connect to the voice channel.

## 2. Connecting to Voice

```julia
using Accord

vc = [`VoiceClient`](@ref)(client, guild_id, voice_channel_id)

# Full handshake: gateway → voice WS → UDP → ready
connect!(vc)

# Later, disconnect
disconnect!(vc)
```

The [`connect!`](@ref) flow:
1. Sends `VOICE_STATE_UPDATE` to the gateway
2. Waits for [`VoiceStateUpdateEvent`](@ref) and `VoiceServerUpdate` events
3. Connects to the voice WebSocket
4. Performs IP discovery via UDP
5. Selects encryption mode and establishes the session

## 3. Playing Audio

### From Any File (via FFmpeg)

```julia
source = [`FFmpegSource`](@ref)("song.mp3")
play!(vc, source)
```

[`FFmpegSource`](@ref) handles any format ffmpeg supports: MP3, FLAC, OGG, WAV, M4A, URLs, etc.

```julia
# Play from a URL
source = [`FFmpegSource`](@ref)("https://example.com/stream.mp3")
play!(vc, source)

# Adjust volume at the ffmpeg level
source = [`FFmpegSource`](@ref)("song.mp3"; volume=0.5)
play!(vc, source)
```

### From Raw PCM

```julia
# Raw PCM Int16, 48kHz stereo
pcm_data = zeros(Int16, 48000 * 2 * 5)  # 5 seconds of silence
source = [`PCMSource`](@ref)(pcm_data)
play!(vc, source)
```

### From a Raw PCM File

```julia
# File must be: 48kHz, 16-bit signed little-endian, stereo
source = [`FileSource`](@ref)("audio.raw")
play!(vc, source)
```

### Silence (Keep-Alive)

```julia
# 5 seconds of silence to keep the voice connection alive
source = [`SilenceSource`](@ref)(5000)
play!(vc, source)
```

## 4. Playback Control

```julia
player = vc.player

# Pause/resume
pause!(player)
resume!(player)

# Check status
is_playing(player)  # true/false

# Volume (0.0 to 2.0, applied to PCM before encoding)
player.volume = 0.5   # 50%
player.volume = 1.5   # 150%

# Stop playback
stop!(vc)
```

## 5. Opus Encoding Details

Discord requires Opus-encoded audio:
- **Sample rate:** 48,000 Hz
- **Channels:** 2 (stereo)
- **Frame duration:** 20 ms
- **Frame size:** 960 samples per channel (1,920 total)

Accord.jl handles this automatically when you use [`play!`](@ref). For manual encoding:

```julia
encoder = [`OpusEncoder`](@ref)()  # defaults: 48kHz, stereo, AUDIO application

pcm_frame = rand(Int16, 960 * 2)  # one 20ms frame
opus_data = opus_encode(encoder, pcm_frame)

# Decoding
decoder = [`OpusDecoder`](@ref)()
pcm_out = opus_decode(decoder, opus_data)
```

## 6. Voice Transcription

This recipe captures incoming voice audio and sends it to OpenAI's Whisper API for transcription.

### Architecture

```text
Discord Voice → UDP packets → Opus decode → PCM buffer
                                              ↓
                              Silence detected → WAV file
                                              ↓
                              Whisper API → Transcript → Text channel
```

### PCM to WAV Helper

```julia
function pcm_to_wav(pcm::Vector{Int16}; sample_rate=48000, channels=2)
    data_size = length(pcm) * sizeof(Int16)
    file_size = 36 + data_size

    io = IOBuffer()
    # RIFF header
    write(io, b"RIFF")
    write(io, UInt32(file_size))
    write(io, b"WAVE")
    # fmt chunk
    write(io, b"fmt ")
    write(io, UInt32(16))          # chunk size
    write(io, UInt16(1))           # PCM format
    write(io, UInt16(channels))
    write(io, UInt32(sample_rate))
    write(io, UInt32(sample_rate * channels * sizeof(Int16)))  # byte rate
    write(io, UInt16(channels * sizeof(Int16)))                 # block align
    write(io, UInt16(16))          # bits per sample
    # data chunk
    write(io, b"data")
    write(io, UInt32(data_size))
    write(io, pcm)

    return take!(io)
end
```

### Transcription with Whisper API

```julia
import HTTP
import JSON3

function transcribe_audio(wav_bytes::Vector{UInt8}; api_key=ENV["OPENAI_API_KEY"])
    # Build multipart form
    body = HTTP.Forms.Form(Dict(
        "file" => HTTP.Forms.File(wav_bytes, "audio.wav", "audio/wav"),
        "model" => "whisper-1",
        "language" => "en",
    ))

    resp = HTTP.post(
        "https://api.openai.com/v1/audio/transcriptions",
        ["Authorization" => "Bearer $api_key"],
        body
    )

    result = JSON3.read(resp.body)
    return result["text"]
end
```

### Capture and Transcribe Loop

This is a conceptual pattern for capturing voice data per user (SSRC):

```julia
# Per-user audio buffers
const audio_buffers = Dict{UInt32, Vector{Int16}}()  # SSRC → PCM samples
const decoders = Dict{UInt32, OpusDecoder}()
const silence_counters = Dict{UInt32, Int}()

const SILENCE_THRESHOLD = 50     # ~1 second of silence (50 × 20ms frames)
const MIN_AUDIO_FRAMES = 25      # at least 0.5s of speech

function process_voice_packet(ssrc::UInt32, opus_data::Vector{UInt8})
    dec = get!(decoders, ssrc) do; OpusDecoder() end
    buf = get!(audio_buffers, ssrc) do; Int16[] end

    pcm = opus_decode(dec, opus_data)

    # Simple energy-based silence detection
    energy = sum(abs.(Float64.(pcm))) / length(pcm)
    if energy < 100.0
        silence_counters[ssrc] = get(silence_counters, ssrc, 0) + 1

        if silence_counters[ssrc] >= SILENCE_THRESHOLD && length(buf) > MIN_AUDIO_FRAMES * 960 * 2
            # Silence detected after speech — transcribe
            wav = pcm_to_wav(buf)
            audio_buffers[ssrc] = Int16[]
            silence_counters[ssrc] = 0

            @async begin
                try
                    text = transcribe_audio(wav)
                    if !isempty(strip(text))
                        create_message(client, text_channel_id;
                            content="**SSRC $ssrc**: $text")
                    end
                catch e
                    @error "Transcription failed" exception=e
                end
            end
            return
        end
    else
        silence_counters[ssrc] = 0
    end

    append!(buf, pcm)
    audio_buffers[ssrc] = buf
end
```

## 7. Slash Commands for Voice

```julia
tree = CommandTree()

register_command!(tree, "join", "Join your voice channel", function(ctx)
    defer(ctx)

    guild_id = ctx.interaction.guild_id
    user_id = ctx.interaction.member.user.id

    # Find user's voice channel from state
    guild_vs = get(ctx.client.state.voice_states, guild_id, nothing)
    if isnothing(guild_vs)
        respond(ctx; content="You're not in a voice channel!")
        return
    end
    vs = get(guild_vs, user_id, nothing)
    if isnothing(vs) || isnothing(vs.channel_id)
        respond(ctx; content="You're not in a voice channel!")
        return
    end

    vc = VoiceClient(ctx.client, guild_id, vs.channel_id)
    connect!(vc)
    respond(ctx; content="Joined <#$(vs.channel_id)>!")
end)

register_command!(tree, "leave", "Leave voice channel", function(ctx)
    # Assumes you store the VoiceClient somewhere accessible
    disconnect!(vc)
    respond(ctx; content="Disconnected from voice.")
end)

register_command!(tree, "play", "Play audio", function(ctx)
    url = get_option(ctx, "url", "")
    defer(ctx)

    source = FFmpegSource(url)
    play!(vc, source)
    respond(ctx; content="Now playing!")
end; options=[
    command_option(type=ApplicationCommandOptionTypes.STRING, name="url", description="Audio URL or path", required=true),
])

register_command!(tree, "stop", "Stop playback", function(ctx)
    stop!(vc)
    respond(ctx; content="Playback stopped.")
end)
```

---

**Next steps:** [Recipe 06 — Permissions](06-permissions.md) to add permission checks to your commands.
