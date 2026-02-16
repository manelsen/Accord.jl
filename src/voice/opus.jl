# Opus codec wrapper via Opus_jll

using Opus_jll

const OPUS_APPLICATION_AUDIO = 2049
const OPUS_APPLICATION_VOIP = 2048
const OPUS_APPLICATION_LOWDELAY = 2051

const OPUS_OK = 0
const OPUS_SET_BITRATE_REQUEST = 4002
const OPUS_SET_SIGNAL_REQUEST = 4024
const OPUS_SIGNAL_MUSIC = 3002
const OPUS_SIGNAL_VOICE = 3001

# Discord uses 48kHz stereo, 20ms frames
const OPUS_SAMPLE_RATE = 48000
const OPUS_CHANNELS = 2
const OPUS_FRAME_DURATION_MS = 20
const OPUS_FRAME_SIZE = div(OPUS_SAMPLE_RATE * OPUS_FRAME_DURATION_MS, 1000)  # 960 samples
const OPUS_MAX_PACKET_SIZE = 4000

"""Use this to encode PCM audio to Opus format for voice transmission.

Opus encoder handle."""
mutable struct OpusEncoder
    ptr::Ptr{Cvoid}
    sample_rate::Int32
    channels::Int32

    function OpusEncoder(sample_rate::Int=OPUS_SAMPLE_RATE, channels::Int=OPUS_CHANNELS, application::Int=OPUS_APPLICATION_AUDIO)
        err = Ref{Cint}(0)
        ptr = ccall((:opus_encoder_create, Opus_jll.libopus),
            Ptr{Cvoid},
            (Cint, Cint, Cint, Ptr{Cint}),
            sample_rate, channels, application, err)

        err[] == OPUS_OK || error("opus_encoder_create failed: $(err[])")
        ptr != C_NULL || error("opus_encoder_create returned null")

        enc = new(ptr, Int32(sample_rate), Int32(channels))
        finalizer(enc) do e
            if e.ptr != C_NULL
                ccall((:opus_encoder_destroy, Opus_jll.libopus), Cvoid, (Ptr{Cvoid},), e.ptr)
                e.ptr = C_NULL
            end
        end
        return enc
    end
end

"""Use this to decode Opus audio back to PCM format.

Opus decoder handle."""
mutable struct OpusDecoder
    ptr::Ptr{Cvoid}
    sample_rate::Int32
    channels::Int32

    function OpusDecoder(sample_rate::Int=OPUS_SAMPLE_RATE, channels::Int=OPUS_CHANNELS)
        err = Ref{Cint}(0)
        ptr = ccall((:opus_decoder_create, Opus_jll.libopus),
            Ptr{Cvoid},
            (Cint, Cint, Ptr{Cint}),
            sample_rate, channels, err)

        err[] == OPUS_OK || error("opus_decoder_create failed: $(err[])")
        ptr != C_NULL || error("opus_decoder_create returned null")

        dec = new(ptr, Int32(sample_rate), Int32(channels))
        finalizer(dec) do d
            if d.ptr != C_NULL
                ccall((:opus_decoder_destroy, Opus_jll.libopus), Cvoid, (Ptr{Cvoid},), d.ptr)
                d.ptr = C_NULL
            end
        end
        return dec
    end
end

"""
    opus_encode(encoder, pcm) -> Vector{UInt8}

Use this to compress PCM audio into Opus format for efficient voice transmission.

Encode PCM audio (Int16 samples) to Opus.
`pcm` should contain `frame_size * channels` samples.
"""
function opus_encode(enc::OpusEncoder, pcm::Vector{Int16})
    frame_size = div(length(pcm), enc.channels)
    output = Vector{UInt8}(undef, OPUS_MAX_PACKET_SIZE)

    nbytes = ccall((:opus_encode, Opus_jll.libopus),
        Cint,
        (Ptr{Cvoid}, Ptr{Int16}, Cint, Ptr{UInt8}, Cint),
        enc.ptr, pcm, frame_size, output, OPUS_MAX_PACKET_SIZE)

    nbytes > 0 || error("opus_encode failed: $nbytes")
    return output[1:nbytes]
end

"""
    opus_decode(decoder, data, frame_size) -> Vector{Int16}

Use this to decompress Opus audio back into PCM format for playback or processing.

Decode Opus data to PCM audio (Int16 samples).
"""
function opus_decode(dec::OpusDecoder, data::Vector{UInt8}, frame_size::Int=OPUS_FRAME_SIZE)
    pcm = Vector{Int16}(undef, frame_size * dec.channels)

    nsamples = ccall((:opus_decode, Opus_jll.libopus),
        Cint,
        (Ptr{Cvoid}, Ptr{UInt8}, Cint, Ptr{Int16}, Cint, Cint),
        dec.ptr, data, length(data), pcm, frame_size, 0)

    nsamples > 0 || error("opus_decode failed: $nsamples")
    return pcm[1:(nsamples * dec.channels)]
end

"""Use this to adjust the audio quality and bandwidth usage of the Opus encoder.

Set the bitrate for an Opus encoder."""
function set_bitrate!(enc::OpusEncoder, bitrate::Int)
    ret = ccall((:opus_encoder_ctl, Opus_jll.libopus),
        Cint,
        (Ptr{Cvoid}, Cint, Cint),
        enc.ptr, OPUS_SET_BITRATE_REQUEST, Cint(bitrate))
    ret == OPUS_OK || error("opus_encoder_ctl SET_BITRATE failed: $ret")
end

"""Use this to optimize the encoder for either music or voice content.

Set the signal type for an Opus encoder (OPUS_SIGNAL_MUSIC or OPUS_SIGNAL_VOICE)."""
function set_signal!(enc::OpusEncoder, signal::Int)
    ret = ccall((:opus_encoder_ctl, Opus_jll.libopus),
        Cint,
        (Ptr{Cvoid}, Cint, Cint),
        enc.ptr, OPUS_SET_SIGNAL_REQUEST, Cint(signal))
    ret == OPUS_OK || error("opus_encoder_ctl SET_SIGNAL failed: $ret")
end
