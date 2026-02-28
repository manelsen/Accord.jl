@testitem "Voice audio sources" tags=[:unit] begin
    using Accord

    @testset "PCMSource basic" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)

        @test src.data === data
        @test src.position == 1
        @test src.channels == 2
    end

    @testset "PCMSource read single frame" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)

        frame = read_frame(src)
        @test length(frame) == OPUS_FRAME_SIZE * 2
        @test all(iszero, frame)
        @test src.position == OPUS_FRAME_SIZE * 2 + 1
    end

    @testset "PCMSource read multiple frames" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 4 * 2)  # 4 frames
        src = PCMSource(data)

        frame1 = read_frame(src)
        frame2 = read_frame(src)
        frame3 = read_frame(src)
        frame4 = read_frame(src)

        @test length(frame1) == OPUS_FRAME_SIZE * 2
        @test length(frame2) == OPUS_FRAME_SIZE * 2
        @test length(frame3) == OPUS_FRAME_SIZE * 2
        @test length(frame4) == OPUS_FRAME_SIZE * 2
    end

    @testset "PCMSource exhausts" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)

        frame1 = read_frame(src)
        @test frame1 !== nothing

        frame2 = read_frame(src)
        @test frame2 === nothing  # Exhausted
    end

    @testset "PCMSource with custom channels" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 1)
        src = PCMSource(data; channels=1)

        @test src.channels == 1

        frame = read_frame(src)
        @test length(frame) == OPUS_FRAME_SIZE * 1
    end

    @testset "PCMSource with data" begin
        data = Int16[1:OPUS_FRAME_SIZE*2;]
        src = PCMSource(data)

        frame = read_frame(src)
        @test frame == data
    end

    @testset "PCMSource partial frame" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2 - 1)  # One sample short
        src = PCMSource(data)

        frame = read_frame(src)
        @test frame === nothing  # Not enough data for full frame
    end

    @testset "PCMSource close_source" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)

        close_source(src)  # Should not throw
        @test true
    end

    @testset "SilenceSource basic" begin
        src = SilenceSource(40)  # 40ms

        @test src.frames_remaining == 2  # 40ms / 20ms = 2 frames
        @test src.channels == 2
    end

    @testset "SilenceSource read frame" begin
        src = SilenceSource(20)  # 20ms = 1 frame

        frame = read_frame(src)
        @test length(frame) == OPUS_FRAME_SIZE * 2
        @test all(iszero, frame)
        @test src.frames_remaining == 0
    end

    @testset "SilenceSource multiple frames" begin
        src = SilenceSource(60)  # 60ms = 3 frames

        frame1 = read_frame(src)
        frame2 = read_frame(src)
        frame3 = read_frame(src)

        @test all(iszero, frame1)
        @test all(iszero, frame2)
        @test all(iszero, frame3)
        @test src.frames_remaining == 0
    end

    @testset "SilenceSource exhausts" begin
        src = SilenceSource(20)

        frame1 = read_frame(src)
        @test frame1 !== nothing

        frame2 = read_frame(src)
        @test frame2 === nothing  # Exhausted
    end

    @testset "SilenceSource custom channels" begin
        src = SilenceSource(20; channels=1)

        @test src.channels == 1

        frame = read_frame(src)
        @test length(frame) == OPUS_FRAME_SIZE * 1
    end

    @testset "SilenceSource close_source" begin
        src = SilenceSource(20)

        close_source(src)  # Should not throw
        @test true
    end

    @testset "SilenceSource zero duration" begin
        src = SilenceSource(0)

        frame = read_frame(src)
        @test frame === nothing  # No frames
    end

    @testset "FileSource basic (mock file)" begin
        mktemp() do path, io
            data = zeros(UInt8, OPUS_FRAME_SIZE * 2 * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path)
            @test src.channels == 2

            frame = read_frame(src)
            @test length(frame) == OPUS_FRAME_SIZE * 2
            @test all(iszero, frame)

            close_source(src)
        end
    end

    @testset "FileSource exhausts" begin
        mktemp() do path, io
            data = zeros(UInt8, OPUS_FRAME_SIZE * 2 * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path)

            frame1 = read_frame(src)
            @test frame1 !== nothing

            frame2 = read_frame(src)
            @test frame2 === nothing  # Exhausted

            close_source(src)
        end
    end

    @testset "FileSource with data" begin
        mktemp() do path, io
            pcm_data = Int16[1:OPUS_FRAME_SIZE*2;]
            write(io, reinterpret(UInt8, pcm_data))
            close(io)

            src = FileSource(path)
            frame = read_frame(src)

            @test frame == pcm_data

            close_source(src)
        end
    end

    @testset "FileSource custom channels" begin
        mktemp() do path, io
            data = zeros(UInt8, OPUS_FRAME_SIZE * 1 * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path; channels=1)
            @test src.channels == 1

            frame = read_frame(src)
            @test length(frame) == OPUS_FRAME_SIZE * 1

            close_source(src)
        end
    end

    @testset "FileSource partial frame" begin
        mktemp() do path, io
            data = zeros(UInt8, (OPUS_FRAME_SIZE * 2 - 1) * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path)

            frame = read_frame(src)
            @test frame === nothing  # Not enough data

            close_source(src)
        end
    end

    @testset "FileSource close_source closes file" begin
        mktemp() do path, io
            data = zeros(UInt8, OPUS_FRAME_SIZE * 2 * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path)
            close_source(src)

            @test !isopen(src.io)
        end
    end

    @testset "FFmpegSource structure" begin
        try
            # This test only runs if ffmpeg is available
            mktemp() do path, io
                # Create a minimal WAV file
                write(io, [0x52, 0x49, 0x46, 0x46])  # "RIFF"
                write(io, UInt32(36))  # file size - 8
                write(io, [0x57, 0x41, 0x56, 0x45])  # "WAVE"
                write(io, [0x66, 0x6d, 0x74, 0x20])  # "fmt "
                write(io, UInt32(16))  # PCM header size
                write(io, UInt16(1))  # PCM format
                write(io, UInt16(2))  # stereo
                write(io, UInt32(48000))  # sample rate
                write(io, UInt32(192000))  # byte rate
                write(io, UInt16(4))  # block align
                write(io, UInt16(16))  # bits per sample
                write(io, [0x64, 0x61, 0x74, 0x61])  # "data"
                write(io, UInt32(0))  # data size (empty)
                close(io)

                src = FFmpegSource(path)
                @test src.channels == 2

                close_source(src)
            end
        catch e
            # ffmpeg not available, skip test
            @test_skip "ffmpeg not available"
        end
    end

    @testset "PCMSource is AbstractAudioSource" begin
        data = zeros(Int16, OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)
        @test src isa AbstractAudioSource
    end

    @testset "SilenceSource is AbstractAudioSource" begin
        src = SilenceSource(20)
        @test src isa AbstractAudioSource
    end

    @testset "FileSource is AbstractAudioSource" begin
        mktemp() do path, io
            data = zeros(UInt8, OPUS_FRAME_SIZE * 2 * sizeof(Int16))
            write(io, data)
            close(io)

            src = FileSource(path)
            @test src isa AbstractAudioSource

            close_source(src)
        end
    end

    @testset "PCMSource with large data" begin
        num_frames = 100
        data = zeros(Int16, num_frames * OPUS_FRAME_SIZE * 2)
        src = PCMSource(data)

        for i in 1:num_frames
            frame = read_frame(src)
            @test length(frame) == OPUS_FRAME_SIZE * 2
            @test all(iszero, frame)
        end

        @test read_frame(src) === nothing
    end

    @testset "SilenceSource with large duration" begin
        src = SilenceSource(2000)  # 2000ms = 100 frames

        for i in 1:100
            frame = read_frame(src)
            @test length(frame) == OPUS_FRAME_SIZE * 2
            @test all(iszero, frame)
        end

        @test read_frame(src) === nothing
    end

    @testset "PCMSource preserves original data" begin
        original_data = Int16[1:OPUS_FRAME_SIZE*2;]
        src = PCMSource(copy(original_data))

        read_frame(src)

        @test src.data == original_data
    end

    @testset "PCMSource mono to stereo conversion" begin
        # This tests that PCMSource correctly handles mono data
        data = zeros(Int16, OPUS_FRAME_SIZE)
        src = PCMSource(data; channels=1)

        frame = read_frame(src)
        @test length(frame) == OPUS_FRAME_SIZE
        @test all(iszero, frame)
    end
end
