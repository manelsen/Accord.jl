# Voice UDP transport — IP discovery and RTP packet handling
#
# Internal module: Handles RTP packet construction/parsing, IP discovery protocol,
# and encrypted voice packet transmission over UDP.

using Sockets

const RTP_HEADER_SIZE = 12
const RTP_VERSION = 0x80  # version 2, no padding, no extension
const RTP_PAYLOAD_TYPE = 0x78  # 120 — Opus

"""
    RTPPacket

Represents an RTP packet for voice data.
"""
struct RTPPacket
    version_flags::UInt8
    payload_type::UInt8
    sequence::UInt16
    timestamp::UInt32
    ssrc::UInt32
    payload::Vector{UInt8}
end

"""Build the RTP header bytes."""
function rtp_header(seq::UInt16, timestamp::UInt32, ssrc::UInt32)
    buf = IOBuffer()
    write(buf, RTP_VERSION)
    write(buf, RTP_PAYLOAD_TYPE)
    write(buf, hton(seq))
    write(buf, hton(timestamp))
    write(buf, hton(ssrc))
    return take!(buf)
end

"""Parse an RTP header from raw bytes."""
function parse_rtp_header(data::Vector{UInt8})
    length(data) >= RTP_HEADER_SIZE || error("Data too short for RTP header")
    buf = IOBuffer(data)
    version_flags = read(buf, UInt8)
    payload_type = read(buf, UInt8)
    sequence = ntoh(read(buf, UInt16))
    timestamp = ntoh(read(buf, UInt32))
    ssrc = ntoh(read(buf, UInt32))
    payload = data[RTP_HEADER_SIZE+1:end]
    RTPPacket(version_flags, payload_type, sequence, timestamp, ssrc, payload)
end

"""
    ip_discovery(sock::UDPSocket, address::String, port::Int, ssrc::UInt32) -> (ip, port)

Perform IP discovery to find our external IP and port.
Sends a 74-byte request packet and reads the response.
"""
function ip_discovery(sock::UDPSocket, address::String, port::Int, ssrc::UInt32)
    # Build discovery request (74 bytes)
    buf = IOBuffer()
    write(buf, hton(UInt16(0x1)))  # Type: request
    write(buf, hton(UInt16(70)))    # Length
    write(buf, hton(ssrc))

    # Pad address to 64 bytes
    addr_bytes = Vector{UInt8}(codeunits(address))
    resize!(addr_bytes, 64)
    write(buf, addr_bytes)

    write(buf, hton(UInt16(port)))

    packet = take!(buf)
    @assert length(packet) == 74

    # Send discovery request
    ip = Sockets.getaddrinfo(address)
    Sockets.send(sock, ip, port, packet)

    # Read response
    response = Sockets.recv(sock)
    length(response) >= 74 || error("IP discovery response too short: $(length(response))")

    # Parse response
    resp_buf = IOBuffer(response)
    resp_type = ntoh(read(resp_buf, UInt16))
    resp_len = ntoh(read(resp_buf, UInt16))
    resp_ssrc = ntoh(read(resp_buf, UInt32))

    # Extract IP (null-terminated string in 64-byte field)
    ip_bytes = read(resp_buf, 64)
    null_idx = findfirst(==(0x00), ip_bytes)
    our_ip = String(ip_bytes[1:(isnothing(null_idx) ? 64 : null_idx - 1)])

    # Extract port (last 2 bytes)
    our_port = ntoh(read(resp_buf, UInt16))

    @info "IP Discovery result" our_ip our_port
    return (our_ip, Int(our_port))
end

"""
    send_voice_packet(sock, address, port, header, encrypted_audio)

Send an encrypted voice packet via UDP.
"""
function send_voice_packet(sock::UDPSocket, address::String, port::Int, header::Vector{UInt8}, encrypted_audio::Vector{UInt8})
    packet = vcat(header, encrypted_audio)
    ip = Sockets.getaddrinfo(address)
    Sockets.send(sock, ip, port, packet)
end

"""
    create_voice_udp(address::String, port::Int) -> UDPSocket

Create and connect a UDP socket for voice communication.
"""
function create_voice_udp(address::String, port::Int)
    sock = UDPSocket()
    return sock
end
