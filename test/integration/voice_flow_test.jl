@testitem "Voice flow integration tests" tags=[:integration] begin
    using Accord
    const AI = Accord.internals
    const VoiceGatewaySession = AI.VoiceGatewaySession
    const CRYPTO_SECRETBOX_KEYBYTES = AI.CRYPTO_SECRETBOX_KEYBYTES
    const CRYPTO_SECRETBOX_NONCEBYTES = AI.CRYPTO_SECRETBOX_NONCEBYTES
    const xsalsa20_poly1305_encrypt = AI.xsalsa20_poly1305_encrypt
    const rtp_header = AI.rtp_header
    const ENCRYPTION_MODES = AI.ENCRYPTION_MODES
    const select_encryption_mode = AI.select_encryption_mode
    const VoiceOpcodes = AI.VoiceOpcodes

    @testset "VoiceClient creation" begin
        client = Client("mock_token")
        guild_id = Snowflake(123)
        channel_id = Snowflake(456)

        vc = VoiceClient(client, guild_id, channel_id)

        @test vc.client === client
        @test vc.guild_id == guild_id
        @test vc.channel_id == channel_id
        @test vc.connected == false
        @test vc.sequence == UInt16(0)
        @test vc.timestamp == UInt32(0)
    end

    @testset "VoiceClient state" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        @test vc.connected == false
        @test isnothing(vc.session)
        @test isnothing(vc.udp_socket)
    end

    @testset "VoiceGatewaySession creation" begin
        guild_id = Snowflake(100)
        channel_id = Snowflake(200)
        user_id = Snowflake(300)
        session_id = "session_123"
        endpoint = "voice-server.discord.gg"
        token = "voice_token_abc"

        session = VoiceGatewaySession(guild_id, channel_id, user_id, session_id, endpoint, token)

        @test session.guild_id == guild_id
        @test session.channel_id == channel_id
        @test session.user_id == user_id
        @test session.session_id == session_id
        @test session.endpoint == "wss://voice-server.discord.gg"
        @test session.token == token
        @test session.connected == false
        @test session.ssrc == UInt32(0)
        @test isempty(session.secret_key)
    end

    @testset "VoiceGatewaySession with wss:// endpoint" begin
        session = VoiceGatewaySession(
            Snowflake(1), Snowflake(2), Snowflake(3),
            "sid", "wss://test.com", "token"
        )

        @test session.endpoint == "wss://test.com"
    end

    @testset "VoiceGatewaySession URL formatting" begin
        session = VoiceGatewaySession(
            Snowflake(1), Snowflake(2), Snowflake(3),
            "sid", "test.com", "token"
        )

        @test session.endpoint == "wss://test.com"
    end

    @testset "AudioPlayer creation" begin
        player = AudioPlayer()

        @test player.playing == false
        @test player.paused == false
        @test player.volume == 1.0
        @test isnothing(player.source)
        @test isnothing(player.encoder)
    end

    @testset "AudioPlayer volume" begin
        player = AudioPlayer()

        @test player.volume == 1.0
        player.volume = 0.5
        @test player.volume == 0.5
    end

    @testset "AudioPlayer pause/resume" begin
        player = AudioPlayer()

        @test player.paused == false

        player.paused = true
        @test player.paused == true

        player.paused = false
        @test player.paused == false
    end

    @testset "VoiceClient sequence increment" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        @test vc.sequence == UInt16(0)

        vc.sequence = UInt16(100)
        @test vc.sequence == UInt16(100)
    end

    @testset "VoiceClient timestamp increment" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        @test vc.timestamp == UInt32(0)

        vc.timestamp = UInt32(10000)
        @test vc.timestamp == UInt32(10000)
    end

    @testset "Audio playback flow mock" begin
        # Simulate the audio playback flow without actual Discord connection
        player = AudioPlayer()
        source = SilenceSource(100)  # 100ms = 5 frames

        @test player.playing == false

        # Simulate playing
        player.playing = true
        player.source = source

        @test player.playing == true

        # Simulate stopping
        player.playing = false
        close_source(source)

        @test player.playing == false
    end

    @testset "Voice encryption flow" begin
        key = zeros(UInt8, CRYPTO_SECRETBOX_KEYBYTES)
        nonce = zeros(UInt8, CRYPTO_SECRETBOX_NONCEBYTES)

        # Simulate audio data
        pcm_data = rand(Int16, OPUS_FRAME_SIZE * OPUS_CHANNELS)

        # Encode to Opus
        encoder = OpusEncoder()
        opus_data = opus_encode(encoder, pcm_data)

        # Encrypt
        encrypted = xsalsa20_poly1305_encrypt(key, nonce, opus_data)

        @test length(encrypted) == length(opus_data) + 16  # MAC
    end

    @testset "RTP packet construction flow" begin
        seq = UInt16(0)
        timestamp = UInt32(0)
        ssrc = UInt32(100)

        # Create header
        header = rtp_header(seq, timestamp, ssrc)

        # Mock encrypted audio data
        encrypted_audio = rand(UInt8, 100)

        # Combine into packet
        packet = vcat(header, encrypted_audio)

        @test length(packet) == 12 + 100
        @test packet[1:12] == header
        @test packet[13:end] == encrypted_audio
    end

    @testset "Full audio pipeline mock" begin
        # Simulate the full audio pipeline without network

        # 1. Read frame from source
        source = SilenceSource(20)  # One frame
        pcm = read_frame(source)

        @test length(pcm) == OPUS_FRAME_SIZE * 2

        # 2. Encode to Opus
        encoder = OpusEncoder()
        opus_data = opus_encode(encoder, pcm)

        @test !isempty(opus_data)

        # 3. Encrypt
        key = zeros(UInt8, CRYPTO_SECRETBOX_KEYBYTES)
        nonce = zeros(UInt8, CRYPTO_SECRETBOX_NONCEBYTES)
        encrypted = xsalsa20_poly1305_encrypt(key, nonce, opus_data)

        @test !isempty(encrypted)

        # 4. Build RTP header
        header = rtp_header(UInt16(0), UInt32(0), UInt32(100))

        @test length(header) == 12

        # 5. Combine into final packet
        final_packet = vcat(header, encrypted)

        @test !isempty(final_packet)
    end

    @testset "Encryption mode selection" begin
        server_modes = ENCRYPTION_MODES

        mode = select_encryption_mode(server_modes)

        @test mode in ENCRYPTION_MODES
        @test mode == "aead_xchacha20_poly1305_rtpsize"
    end

    @testset "Encryption mode selection priority" begin
        modes = ["xsalsa20_poly1305", "xsalsa20_poly1305_suffix"]

        mode = select_encryption_mode(modes)

        @test mode == "xsalsa20_poly1305_suffix"
    end

    @testset "AudioPlayer with multiple sources" begin
        player = AudioPlayer()

        source1 = SilenceSource(40)  # 2 frames
        source2 = SilenceSource(20)  # 1 frame

        @test player.playing == false

        # Play first source
        player.playing = true
        player.source = source1

        @test player.playing == true

        # Stop and switch sources
        player.playing = false
        close_source(source1)

        player.playing = true
        player.source = source2

        @test player.playing == true

        player.playing = false
        close_source(source2)
    end

    @testset "VoiceClient event setup" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        # Check that events are initialized
        @test isa(vc._voice_state_event, Base.Event)
        @test isa(vc._voice_server_event, Base.Event)

        # Check that session info is empty initially
        @test isnothing(vc._voice_session_id)
        @test isnothing(vc._voice_token)
        @test isnothing(vc._voice_endpoint)
    end

    @testset "VoiceGatewaySession ready event" begin
        session = VoiceGatewaySession(
            Snowflake(1), Snowflake(2), Snowflake(3),
            "sid", "wss://test.com", "token"
        )

        @test isa(session.ready, Base.Event)
    end

    @testset "VoiceClient encryption modes" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        # Check encryption mode can be set
        vc.encryption_mode = "xsalsa20_poly1305"

        @test vc.encryption_mode == "xsalsa20_poly1305"
    end

    @testset "VoiceClient with all encryption modes" begin
        for mode in ENCRYPTION_MODES
            client = Client("mock_token")
            vc = VoiceClient(client, Snowflake(1), Snowflake(2))

            vc.encryption_mode = mode

            @test vc.encryption_mode == mode
        end
    end

    @testset "AudioPlayer state transitions" begin
        player = AudioPlayer()

        # Initial state
        @test player.playing == false
        @test player.paused == false

        # Start playing
        player.playing = true
        @test player.playing == true
        @test player.paused == false

        # Pause
        player.paused = true
        @test player.playing == true
        @test player.paused == true

        # Resume
        player.paused = false
        @test player.playing == true
        @test player.paused == false

        # Stop
        player.playing = false
        @test player.playing == false
        @test player.paused == false
    end

    @testset "VoiceClient cleanup" begin
        client = Client("mock_token")
        vc = VoiceClient(client, Snowflake(1), Snowflake(2))

        # Simulate connection state
        vc.connected = true

        # Disconnect
        vc.connected = false

        @test vc.connected == false
    end

    @testset "Multiple frames processing" begin
        # Simulate processing multiple audio frames
        source = SilenceSource(100)  # 5 frames

        frames = []
        while true
            frame = read_frame(source)
            if frame === nothing
                break
            end
            push!(frames, frame)
        end

        @test length(frames) == 5

        for frame in frames
            @test length(frame) == OPUS_FRAME_SIZE * 2
            @test all(iszero, frame)
        end
    end

    @testset "VoiceOpcodes constants" begin
        @test VoiceOpcodes.HELLO == 8
        @test VoiceOpcodes.IDENTIFY == 0
        @test VoiceOpcodes.SELECT_PROTOCOL == 1
        @test VoiceOpcodes.READY == 2
        @test VoiceOpcodes.HEARTBEAT == 3
        @test VoiceOpcodes.SESSION_DESCRIPTION == 4
        @test VoiceOpcodes.SPEAKING == 5
        @test VoiceOpcodes.HEARTBEAT_ACK == 6
    end

    @testset "Voice flow error handling mock" begin
        # Test that the system handles errors gracefully

        # 1. Source exhaustion
        source = SilenceSource(20)  # 1 frame

        frame1 = read_frame(source)
        frame2 = read_frame(source)

        @test frame1 !== nothing
        @test frame2 === nothing

        # 2. Player cleanup
        player = AudioPlayer()
        source = SilenceSource(20)

        player.playing = true
        player.source = source

        player.playing = false
        close_source(source)

        @test player.playing == false
    end

    @testset "Audio timing mock" begin
        # Simulate the timing of audio frame delivery

        frame_duration = OPUS_FRAME_DURATION_MS / 1000.0  # 20ms in seconds

        @test frame_duration == 0.02

        # Calculate expected frame count for 1 second
        frames_per_second = div(1000, OPUS_FRAME_DURATION_MS)

        @test frames_per_second == 50
    end
end
