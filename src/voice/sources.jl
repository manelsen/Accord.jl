# Audio sources for the voice player

"""
    PCMSource

Audio source from raw PCM Int16 data (48kHz, stereo).
"""
mutable struct PCMSource <: AbstractAudioSource
    data::Vector{Int16}
    position::Int
    channels::Int
end

PCMSource(data::Vector{Int16}; channels::Int=OPUS_CHANNELS) = PCMSource(data, 1, channels)

function read_frame(source::PCMSource)
    samples_per_frame = OPUS_FRAME_SIZE * source.channels
    if source.position + samples_per_frame - 1 > length(source.data)
        return nothing
    end
    frame = source.data[source.position:source.position + samples_per_frame - 1]
    source.position += samples_per_frame
    return frame
end

close_source(::PCMSource) = nothing

"""
    FileSource

Audio source from a raw PCM file (48kHz, 16-bit signed LE, stereo).
"""
mutable struct FileSource <: AbstractAudioSource
    io::IO
    channels::Int
end

function FileSource(path::String; channels::Int=OPUS_CHANNELS)
    io = open(path, "r")
    FileSource(io, channels)
end

function read_frame(source::FileSource)
    bytes_per_frame = OPUS_FRAME_SIZE * source.channels * sizeof(Int16)
    data = read(source.io, bytes_per_frame)
    length(data) < bytes_per_frame && return nothing
    return reinterpret(Int16, data)
end

function close_source(source::FileSource)
    isopen(source.io) && close(source.io)
end

"""
    FFmpegSource

Audio source that uses FFmpeg to decode any audio format to PCM.
Requires `ffmpeg` to be available in PATH.
"""
mutable struct FFmpegSource <: AbstractAudioSource
    process::Base.Process
    io::IO
    channels::Int
end

function FFmpegSource(path::String; channels::Int=OPUS_CHANNELS, volume::Float64=1.0)
    args = [
        "-i", path,
        "-f", "s16le",
        "-ar", string(OPUS_SAMPLE_RATE),
        "-ac", string(channels),
        "-loglevel", "error",
    ]
    if volume != 1.0
        push!(args, "-af", "volume=$(volume)")
    end
    push!(args, "pipe:1")

    proc = open(`ffmpeg $args`, "r")
    FFmpegSource(proc, proc, channels)
end

function read_frame(source::FFmpegSource)
    bytes_per_frame = OPUS_FRAME_SIZE * source.channels * sizeof(Int16)
    data = try
        read(source.io, bytes_per_frame)
    catch e
        return nothing
    end
    length(data) < bytes_per_frame && return nothing
    return reinterpret(Int16, data)
end

function close_source(source::FFmpegSource)
    try
        kill(source.process)
    catch
    end
end

"""
    SilenceSource

Generates silence frames. Useful for keeping the voice connection alive.
"""
mutable struct SilenceSource <: AbstractAudioSource
    frames_remaining::Int
    channels::Int
end

SilenceSource(duration_ms::Int; channels::Int=OPUS_CHANNELS) = SilenceSource(
    div(duration_ms, OPUS_FRAME_DURATION_MS), channels
)

function read_frame(source::SilenceSource)
    source.frames_remaining <= 0 && return nothing
    source.frames_remaining -= 1
    return zeros(Int16, OPUS_FRAME_SIZE * source.channels)
end

close_source(::SilenceSource) = nothing
