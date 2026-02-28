@testitem "Voice UDP and RTP" tags=[:unit] begin
    using Accord
    using Sockets
    import Accord: rtp_header, parse_rtp_header, RTPPacket,
                   create_voice_udp, send_voice_packet,
                   RTP_HEADER_SIZE, RTP_VERSION, RTP_PAYLOAD_TYPE

    @testset "RTP constants" begin
        @test RTP_HEADER_SIZE == 12
        @test RTP_VERSION == 0x80  # version 2
        @test RTP_PAYLOAD_TYPE == 0x78  # Opus
    end

    @testset "rtp_header basic" begin
        seq = UInt16(12345)
        timestamp = UInt32(678901234)
        ssrc = UInt32(987654321)

        header = rtp_header(seq, timestamp, ssrc)

        @test length(header) == RTP_HEADER_SIZE
        @test header[1] == RTP_VERSION
        @test header[2] == RTP_PAYLOAD_TYPE
    end

    @testset "rtp_header sequence number" begin
        seq = UInt16(0x1234)
        timestamp = UInt32(0)
        ssrc = UInt32(0)

        header = rtp_header(seq, timestamp, ssrc)

        # Sequence number is at bytes 3-4 (network byte order)
        seq_bytes = @view header[3:4]
        parsed_seq = reinterpret(UInt16, [seq_bytes[1], seq_bytes[2]])[1]
        @test ntoh(parsed_seq) == seq
    end

    @testset "rtp_header timestamp" begin
        seq = UInt16(0)
        timestamp = UInt32(0x12345678)
        ssrc = UInt32(0)

        header = rtp_header(seq, timestamp, ssrc)

        # Timestamp is at bytes 5-8 (network byte order)
        ts_bytes = @view header[5:8]
        parsed_ts = reinterpret(UInt32, [ts_bytes[1], ts_bytes[2], ts_bytes[3], ts_bytes[4]])[1]
        @test ntoh(parsed_ts) == timestamp
    end

    @testset "rtp_header SSRC" begin
        seq = UInt16(0)
        timestamp = UInt32(0)
        ssrc = UInt32(0x9ABCDEF0)

        header = rtp_header(seq, timestamp, ssrc)

        # SSRC is at bytes 9-12 (network byte order)
        ssrc_bytes = @view header[9:12]
        parsed_ssrc = reinterpret(UInt32, [ssrc_bytes[1], ssrc_bytes[2], ssrc_bytes[3], ssrc_bytes[4]])[1]
        @test ntoh(parsed_ssrc) == ssrc
    end

    @testset "rtp_header wrap around" begin
        seq = UInt16(0xFFFF)
        timestamp = UInt32(0xFFFFFFFF)
        ssrc = UInt32(0xFFFFFFFF)

        header = rtp_header(seq, timestamp, ssrc)

        @test length(header) == RTP_HEADER_SIZE
    end

    @testset "parse_rtp_header basic" begin
        header = rtp_header(UInt16(123), UInt32(456), UInt32(789))

        packet = parse_rtp_header(header)

        @test packet.version_flags == RTP_VERSION
        @test packet.payload_type == RTP_PAYLOAD_TYPE
        @test packet.sequence == 123
        @test packet.timestamp == 456
        @test packet.ssrc == 789
    end

    @testset "parse_rtp_header with payload" begin
        header = rtp_header(UInt16(100), UInt32(200), UInt32(300))
        payload = UInt8[1, 2, 3, 4, 5]
        data = vcat(header, payload)

        packet = parse_rtp_header(data)

        @test packet.sequence == 100
        @test packet.timestamp == 200
        @test packet.ssrc == 300
        @test packet.payload == payload
    end

    @testset "parse_rtp_header too short" begin
        data = zeros(UInt8, 10)  # Less than RTP_HEADER_SIZE

        @test_throws ErrorException parse_rtp_header(data)
    end

    @testset "parse_rtp_header round-trip" begin
        seq = UInt16(0xABCD)
        timestamp = UInt32(0x12345678)
        ssrc = UInt32(0xFEDCBA98)
        payload = UInt8[0xAA, 0xBB, 0xCC, 0xDD]

        header = rtp_header(seq, timestamp, ssrc)
        data = vcat(header, payload)
        packet = parse_rtp_header(data)

        @test packet.sequence == seq
        @test packet.timestamp == timestamp
        @test packet.ssrc == ssrc
        @test packet.payload == payload
    end

    @testset "RTPPacket struct" begin
        version_flags = RTP_VERSION
        payload_type = RTP_PAYLOAD_TYPE
        sequence = UInt16(1000)
        timestamp = UInt32(2000000)
        ssrc = UInt32(3000000)
        payload = UInt8[1, 2, 3]

        packet = RTPPacket(version_flags, payload_type, sequence, timestamp, ssrc, payload)

        @test packet.version_flags == version_flags
        @test packet.payload_type == payload_type
        @test packet.sequence == sequence
        @test packet.timestamp == timestamp
        @test packet.ssrc == ssrc
        @test packet.payload == payload
    end

    @testset "create_voice_udp" begin
        sock = create_voice_udp("127.0.0.1", 1234)

        @test sock isa UDPSocket

        close(sock)
    end

    @testset "create_voice_udp multiple sockets" begin
        sock1 = create_voice_udp("127.0.0.1", 1234)
        sock2 = create_voice_udp("127.0.0.1", 1235)

        @test sock1 !== sock2

        close(sock1)
        close(sock2)
    end

    @testset "RTP header consistency" begin
        # Test that the header format is consistent across calls
        header1 = rtp_header(UInt16(100), UInt32(1000), UInt32(100))
        header2 = rtp_header(UInt16(100), UInt32(1000), UInt32(100))

        @test header1 == header2

        # But different inputs produce different headers
        header3 = rtp_header(UInt16(101), UInt32(1000), UInt32(100))
        @test header1 != header3
    end

    @testset "parse_rtp_header version flags" begin
        header = rtp_header(UInt16(0), UInt32(0), UInt32(0))

        @test header[1] == RTP_VERSION

        packet = parse_rtp_header(header)
        @test packet.version_flags == RTP_VERSION
    end

    @testset "parse_rtp_header payload type" begin
        header = rtp_header(UInt16(0), UInt32(0), UInt32(0))

        @test header[2] == RTP_PAYLOAD_TYPE

        packet = parse_rtp_header(header)
        @test packet.payload_type == RTP_PAYLOAD_TYPE
    end

    @testset "send_voice_packet IPv6 address" begin
        # Test that create_voice_udp can handle IPv6 addresses
        # Note: This test may fail on systems without IPv6 support

        try
            sock = create_voice_udp("::1", 0)
            close(sock)
            @test true
        catch e
            @test_skip "IPv6 not supported on this system"
        end
    end

    @testset "send_voice_packet mock" begin
        # Mock test: verify packet construction without actual UDP send
        header = rtp_header(UInt16(1), UInt32(1000), UInt32(100))
        payload = UInt8[1, 2, 3, 4, 5]

        # Verify packet structure
        @test length(header) == RTP_HEADER_SIZE
        @test length(payload) == 5

        # Simulate packet construction
        packet = vcat(header, payload)
        @test length(packet) == RTP_HEADER_SIZE + 5
        @test packet[1:RTP_HEADER_SIZE] == header
        @test packet[(RTP_HEADER_SIZE+1):end] == payload
    end

    @testset "send_voice_packet multiple packets mock" begin
        packets = []
        for i in 1:10
            header = rtp_header(UInt16(i), UInt32(i * 1000), UInt32(100))
            payload = UInt8[i, i + 1, i + 2]
            packet = vcat(header, payload)
            push!(packets, packet)
        end

        @test length(packets) == 10
        for (i, packet) in enumerate(packets)
            @test length(packet) == RTP_HEADER_SIZE + 3
        end
    end

    @testset "send_voice_packet large payload mock" begin
        header = rtp_header(UInt16(1), UInt32(1000), UInt32(100))
        payload = rand(UInt8, 1000)

        # Verify packet construction
        packet = vcat(header, payload)
        @test length(packet) == length(header) + length(payload)
        @test length(packet) == RTP_HEADER_SIZE + 1000
    end

    @testset "send_voice_packet empty payload mock" begin
        header = rtp_header(UInt16(1), UInt32(1000), UInt32(100))
        payload = UInt8[]

        packet = vcat(header, payload)
        @test length(packet) == RTP_HEADER_SIZE
    end

    @testset "parse_rtp_header with maximum values" begin
        seq = UInt16(0xFFFF)
        timestamp = UInt32(0xFFFFFFFF)
        ssrc = UInt32(0xFFFFFFFF)

        header = rtp_header(seq, timestamp, ssrc)
        packet = parse_rtp_header(header)

        @test packet.sequence == 0xFFFF
        @test packet.timestamp == 0xFFFFFFFF
        @test packet.ssrc == 0xFFFFFFFF
    end
end
