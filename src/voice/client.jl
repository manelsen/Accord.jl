# VoiceClient — high-level voice connection management
#
# Internal module: Provides the high-level VoiceClient API for connecting to
# Discord voice channels, playing audio, and managing the full voice pipeline
# (gateway → voice WS → UDP → Opus → encrypted RTP).

"""
    VoiceClient

Use this to connect your bot to voice channels and play audio.

Manages a voice connection to a Discord voice channel.
Handles the full connection flow: gateway → voice WS → UDP → audio.

!!! compat "Accord 0.1.0"
    Voice support was added in Accord 0.1.0.
"""
mutable struct VoiceClient
    client::Client
    guild_id::Snowflake
    channel_id::Snowflake
    session::Nullable{VoiceGatewaySession}
    udp_socket::Nullable{UDPSocket}
    player::AudioPlayer
    sequence::UInt16
    timestamp::UInt32
    encryption_mode::String
    connected::Bool
    _voice_state_event::Base.Event
    _voice_server_event::Base.Event
    _voice_session_id::Nullable{String}
    _voice_token::Nullable{String}
    _voice_endpoint::Nullable{String}
end

function VoiceClient(client::Client, guild_id::Snowflake, channel_id::Snowflake)
    VoiceClient(
        client, guild_id, channel_id,
        nothing, nothing, AudioPlayer(),
        UInt16(0), UInt32(0), "",
        false,
        Base.Event(), Base.Event(),
        nothing, nothing, nothing,
    )
end

"""
    connect!(vc::VoiceClient) -> VoiceClient

Use this to establish a connection to a voice channel before playing audio.

Connect to the voice channel. This performs the full handshake:
1. Send VOICE_STATE_UPDATE to gateway
2. Wait for VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE events
3. Connect to voice WebSocket
4. Perform IP discovery
5. Select protocol and establish session

!!! note
    Your bot must have the [`IntentGuildVoiceStates`](@ref) intent enabled,
    otherwise the connection will hang waiting for voice events.

# Example
```julia
vc = VoiceClient(client, guild_id, channel_id)
connect!(vc)
```
"""
function connect!(vc::VoiceClient)
    # Register temporary event handlers to capture voice events
    voice_state_handler = (client, event) -> begin
        if event isa VoiceStateUpdateEvent
            vs = event.state
            if !ismissing(vs.guild_id) && vs.guild_id == vc.guild_id && vs.user_id == vc.client.state.me.id
                vc._voice_session_id = vs.session_id
                notify(vc._voice_state_event)
            end
        end
    end

    voice_server_handler = (client, event) -> begin
        if event isa VoiceServerUpdate && event.guild_id == vc.guild_id
            vc._voice_token = event.token
            vc._voice_endpoint = event.endpoint
            notify(vc._voice_server_event)
        end
    end

    on(voice_state_handler, vc.client, VoiceStateUpdateEvent)
    on(voice_server_handler, vc.client, VoiceServerUpdate)

    # Step 1: Send voice state update to join channel
    update_voice_state(vc.client, vc.guild_id; channel_id=vc.channel_id)

    # Step 2: Wait for both events
    @info "Waiting for voice events..."
    wait(vc._voice_state_event)
    wait(vc._voice_server_event)

    isnothing(vc._voice_endpoint) && error("Voice endpoint is null — cannot connect")

    # Step 3: Connect to voice WebSocket
    @info "Connecting to voice gateway" endpoint=vc._voice_endpoint
    me = vc.client.state.me
    isnothing(me) && error("Client user not available")

    session = VoiceGatewaySession(
        vc.guild_id, vc.channel_id, me.id,
        vc._voice_session_id, vc._voice_endpoint, vc._voice_token
    )
    vc.session = session

    voice_gateway_connect(session)
    wait(session.ready)

    # Step 4: IP Discovery
    @info "Performing IP discovery"
    socket = create_voice_udp(session.ip, session.port)
    vc.udp_socket = socket
    our_ip, our_port = ip_discovery(socket, session.ip, session.port, session.ssrc)

    # Step 5: Select protocol
    vc.encryption_mode = select_encryption_mode(session.modes)
    @info "Selected encryption mode" mode=vc.encryption_mode
    send_select_protocol(session, our_ip, our_port, vc.encryption_mode)

    # Wait briefly for session description
    sleep(1.0)

    vc.connected = true
    @info "Voice connection established" guild_id=vc.guild_id channel_id=vc.channel_id
    return vc
end

"""
    disconnect!(vc::VoiceClient)

Use this to leave a voice channel and clean up resources.

Disconnect from the voice channel.

# Example
```julia
# Leave the voice channel and clean up
disconnect!(vc)
```
"""
function disconnect!(vc::VoiceClient)
    vc.connected = false

    # Stop player
    stop!(vc.player)

    # Close UDP socket
    socket = vc.udp_socket
    if !isnothing(socket)
        close(socket)
        vc.udp_socket = nothing
    end

    # Close voice gateway
    session = vc.session
    if !isnothing(session)
        session.connected = false
        vc.session = nothing
    end

    # Leave voice channel
    update_voice_state(vc.client, vc.guild_id; channel_id=nothing)

    @info "Voice disconnected" guild_id=vc.guild_id
end

"""
    play!(vc::VoiceClient, source::AbstractAudioSource)

Use this to start playing audio in a connected voice channel.

Play audio from the given source.

!!! warning
    Only one source can play at a time. Calling `play!` while audio is already
    playing will stop the current source and start the new one.

# Example
```julia
source = FFmpegSource("music.mp3")
play!(vc, source)
```
"""
function play!(vc::VoiceClient, source::AbstractAudioSource)
    !vc.connected && error("Not connected to voice")
    session = vc.session
    isnothing(session) && error("No voice session")
    isempty(session.secret_key) && error("No encryption key — session not fully established")

    # Signal that we're speaking
    send_speaking(session, true)

    play!(vc.player, source, opus_data -> _send_audio(vc, opus_data))

    return vc.player
end

"""
    stop!(vc::VoiceClient)

Use this to stop playing audio in a voice channel.

Stop audio playback.

# Example
```julia
# Stop the current track without disconnecting
stop!(vc)
# Play something else
play!(vc, FFmpegSource("next_song.mp3"))
```
"""
function stop!(vc::VoiceClient)
    stop!(vc.player)
    session = vc.session
    if vc.connected && !isnothing(session)
        try
            send_speaking(session, false)
        catch
        end
    end
end

function _send_audio(vc::VoiceClient, opus_data::Vector{UInt8})
    session = vc.session
    isnothing(session) && error("No voice session")
    socket = vc.udp_socket
    isnothing(socket) && error("No UDP socket")

    vc.sequence = vc.sequence == typemax(UInt16) ? UInt16(0) : vc.sequence + UInt16(1)
    vc.timestamp += UInt32(OPUS_FRAME_SIZE)

    header = rtp_header(vc.sequence, vc.timestamp, session.ssrc)

    # Encrypt based on mode
    encrypted = _encrypt_audio(vc, header, opus_data)

    # Send via UDP
    send_voice_packet(socket, session.ip, session.port, header, encrypted)
end

function _encrypt_audio(vc::VoiceClient, header::Vector{UInt8}, opus_data::Vector{UInt8})
    session = vc.session
    isnothing(session) && error("No voice session")
    key = session.secret_key

    if vc.encryption_mode == "xsalsa20_poly1305"
        # Nonce is the RTP header padded to 24 bytes
        nonce = zeros(UInt8, 24)
        copyto!(nonce, 1, header, 1, min(length(header), 24))
        return xsalsa20_poly1305_encrypt(key, nonce, opus_data)

    elseif vc.encryption_mode == "xsalsa20_poly1305_suffix"
        # Generate random 24-byte nonce, append to packet
        nonce = random_nonce(24)
        encrypted = xsalsa20_poly1305_encrypt(key, nonce, opus_data)
        return vcat(encrypted, nonce)

    elseif vc.encryption_mode == "xsalsa20_poly1305_lite"
        # 4-byte incrementing nonce, padded to 24
        nonce_val = vc.sequence
        nonce = zeros(UInt8, 24)
        nonce[1] = UInt8((nonce_val >> 24) & 0xFF)
        nonce[2] = UInt8((nonce_val >> 16) & 0xFF)
        nonce[3] = UInt8((nonce_val >> 8) & 0xFF)
        nonce[4] = UInt8(nonce_val & 0xFF)
        encrypted = xsalsa20_poly1305_encrypt(key, nonce, opus_data)
        return vcat(encrypted, nonce[1:4])

    elseif vc.encryption_mode == "aead_xchacha20_poly1305_rtpsize"
        # AEAD with RTP header as AAD
        nonce = random_nonce(24)
        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, opus_data, header)
        return vcat(encrypted, nonce)

    else
        error("Unsupported encryption mode: $(vc.encryption_mode)")
    end
end
