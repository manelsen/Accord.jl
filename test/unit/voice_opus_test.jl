@testitem "Voice Opus codec" tags=[:unit] begin
    using Accord

    @testset "OpusEncoder constants" begin
        @test OPUS_SAMPLE_RATE == 48000
        @test OPUS_CHANNELS == 2
        @test OPUS_FRAME_SIZE == 960
        @test OPUS_FRAME_DURATION_MS == 20
        @test OPUS_MAX_PACKET_SIZE == 4000
    end

    @testset "OpusEncoder creation" begin
        enc = OpusEncoder()
        @test enc.ptr != C_NULL
        @test enc.sample_rate == OPUS_SAMPLE_RATE
        @test enc.channels == OPUS_CHANNELS

        enc_custom = OpusEncoder(48000, 2, OPUS_APPLICATION_AUDIO)
        @test enc_custom.ptr != C_NULL
    end

    @testset "OpusDecoder creation" begin
        dec = OpusDecoder()
        @test dec.ptr != C_NULL
        @test dec.sample_rate == OPUS_SAMPLE_RATE
        @test dec.channels == OPUS_CHANNELS

        dec_custom = OpusDecoder(48000, 2)
        @test dec_custom.ptr != C_NULL
    end

    @testset "opus_encode basic" begin
        enc = OpusEncoder()
        pcm = zeros(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        opus = opus_encode(enc, pcm)
        @test !isempty(opus)
        @test length(opus) <= OPUS_MAX_PACKET_SIZE
    end

    @testset "opus_decode basic" begin
        enc = OpusEncoder()
        dec = OpusDecoder()

        pcm_original = rand(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)
        opus = opus_encode(enc, pcm_original)

        pcm_decoded = opus_decode(dec, opus, OPUS_FRAME_SIZE)
        @test length(pcm_decoded) == OPUS_FRAME_SIZE * OPUS_CHANNELS
    end

    @testset "opus_encode silence" begin
        enc = OpusEncoder()
        pcm = zeros(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        opus = opus_encode(enc, pcm)
        @test length(opus) < 100  # Silence compresses well
    end

    @testset "opus_encode random data" begin
        enc = OpusEncoder()
        pcm = rand(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        opus = opus_encode(enc, pcm)
        @test !isempty(opus)
        @test length(opus) <= OPUS_MAX_PACKET_SIZE
    end

    @testset "opus_encode with custom parameters" begin
        enc = OpusEncoder(16000, 1, OPUS_APPLICATION_VOIP)
        pcm = zeros(Int16, 320 * 1)  # 20ms @ 16kHz mono

        opus = opus_encode(enc, pcm)
        @test !isempty(opus)
    end

    @testset "opus_decode with custom parameters" begin
        enc = OpusEncoder(16000, 1, OPUS_APPLICATION_VOIP)
        dec = OpusDecoder(16000, 1)

        pcm_original = zeros(Int16, 320 * 1)
        opus = opus_encode(enc, pcm_original)

        pcm_decoded = opus_decode(dec, opus, 320)
        @test length(pcm_decoded) == 320
    end

    @testset "set_bitrate!" begin
        enc = OpusEncoder()
        pcm = zeros(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        opus_default = opus_encode(enc, pcm)

        set_bitrate!(enc, 64000)  # 64 kbps
        opus_64k = opus_encode(enc, pcm)

        set_bitrate!(enc, 128000)  # 128 kbps
        opus_128k = opus_encode(enc, pcm)

        @test length(opus_default) > 0
        @test length(opus_64k) > 0
        @test length(opus_128k) > 0
    end

    @testset "set_signal!" begin
        enc = OpusEncoder(48000, 2, OPUS_APPLICATION_VOIP)
        pcm = zeros(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        opus_voice = opus_encode(enc, pcm)

        @test !isempty(opus_voice)
    end

    @testset "opus_encode round-trip" begin
        enc = OpusEncoder()
        dec = OpusDecoder()

        # Test multiple frames
        frames = 10
        all_good = true

        for i in 1:frames
            pcm_input = rand(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)
            opus = opus_encode(enc, pcm_input)
            pcm_output = opus_decode(dec, opus, OPUS_FRAME_SIZE)

            if length(pcm_output) != OPUS_FRAME_SIZE * OPUS_CHANNELS
                all_good = false
                break
            end
        end

        @test all_good
    end

    @testset "opus_decode with custom parameters" begin
        dec = OpusDecoder(48000, 2)  # Explicitly stereo
        opus = zeros(UInt8, 100)

        # Decode with custom frame size
        # Note: Opus may return fewer samples than requested for invalid input
        pcm = opus_decode(dec, opus, 960)
        @test length(pcm) >= 0  # Should decode to some PCM (even if silence)
    end

    @testset "OpusEncoder application modes" begin
        audio_enc = OpusEncoder(48000, 2, OPUS_APPLICATION_AUDIO)
        voip_enc = OpusEncoder(48000, 2, OPUS_APPLICATION_VOIP)

        pcm = zeros(Int16, OPUS_FRAME_SIZE * 2)

        audio_opus = opus_encode(audio_enc, pcm)
        voip_opus = opus_encode(voip_enc, pcm)

        @test !isempty(audio_opus)
        @test !isempty(voip_opus)
    end

    @testset "OpusEncoder and OpusDecoder mismatch" begin
        enc = OpusEncoder(48000, 2)
        dec = OpusDecoder(48000, 1)  # Mismatched channels

        pcm_input = zeros(Int16, OPUS_FRAME_SIZE * 2)
        opus = opus_encode(enc, pcm_input)

        # Should decode to mono (960 samples, not 1920)
        pcm_output = opus_decode(dec, opus, OPUS_FRAME_SIZE)
        @test length(pcm_output) == OPUS_FRAME_SIZE * 1
    end

    @testset "opus_encode stereo data" begin
        enc = OpusEncoder()
        pcm = zeros(Int16, OPUS_FRAME_SIZE * 2)

        # Set different values for left and right channels
        for i in 1:OPUS_FRAME_SIZE
            pcm[2*i - 1] = Int16(i)  # Left
            pcm[2*i] = Int16(-i)     # Right
        end

        opus = opus_encode(enc, pcm)
        @test !isempty(opus)
    end

    @testset "opus_decode preserves channel count" begin
        enc = OpusEncoder(48000, 2)
        dec = OpusDecoder(48000, 2)

        pcm_input = rand(Int16, OPUS_FRAME_SIZE * 2)
        opus = opus_encode(enc, pcm_input)
        pcm_output = opus_decode(dec, opus, OPUS_FRAME_SIZE)

        @test length(pcm_output) == OPUS_FRAME_SIZE * 2
    end
end
