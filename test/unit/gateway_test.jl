@testitem "Gateway Logic" tags=[:fast] begin
    using Accord, HTTP, JSON3
    using Accord: GatewaySession, HeartbeatState, start_heartbeat, stop_heartbeat!,
        heartbeat_ack!, heartbeat_latency, _gateway_loop, GatewayOpcodes,
        GatewayCommand, AbstractEvent, ReadyEvent

    # ── Mock WebSocket ───────────────────────────────────────────────────────────

    mutable struct MockWebSocket
        sent::Vector{String}
        receive_queue::Vector{Any} # Strings (payloads) or Exceptions
        closed::Bool
    end

    MockWebSocket() = MockWebSocket(String[], Any[], false)

    function HTTP.WebSockets.send(ws::MockWebSocket, msg)
        push!(ws.sent, msg)
    end

    function HTTP.WebSockets.receive(ws::MockWebSocket)
        if isempty(ws.receive_queue)
            # Simulate blocking or closing if no more messages
            return HTTP.WebSockets.CloseFrameBody(1000, "Normal Closure")
        end
        msg = popfirst!(ws.receive_queue)
        if msg isa Exception
            throw(msg)
        end
        return msg
    end

    function HTTP.WebSockets.close(ws::MockWebSocket)
        ws.closed = true
    end

    # ── Fixture Helper ───────────────────────────────────────────────────────────

    function load_fixture(name)
        path = joinpath(dirname(@__DIR__), "integration", "fixtures", name)
        json_str = read(path, String)
        # The fixtures are stored as arrays of events [ {op:..., d:...} ]
        # We need to feed the raw JSON object string of the first event to the mock WS
        json_arr = JSON3.read(json_str)
        return JSON3.write(json_arr[1])
    end

    # ── Tests ────────────────────────────────────────────────────────────────────

    @testset "HeartbeatState" begin
        # Test initialization
        state = HeartbeatState(41250)
        @test state.interval_ms == 41250
        @test state.last_send == 0.0
        @test state.last_ack == 0.0
        @test state.ack_received == true # Starts true to allow first heartbeat
        @test state.running == true

        # Test ACK handling
        t_before = time()
        heartbeat_ack!(state)
        t_after = time()
        @test state.ack_received == true
        @test t_before <= state.last_ack <= t_after

        # Test latency calculation
        state.last_send = t_before - 0.05 # 50ms ago
        state.last_ack = t_before
        latency = heartbeat_latency(state)
        @test 49.0 <= latency <= 51.0 # Allow slight floating point variance

        # Test stop
        stop_heartbeat!(state)
        @test state.running == false
    end

    @testset "Gateway Loop - Initial Connection" begin
        # Load fixtures
        hello_payload = load_fixture("gateway_hello.json")
        ready_payload = load_fixture("gateway_ready.json")

        # Setup Mock WS with sequence: HELLO -> READY -> Close
        ws = MockWebSocket()
        push!(ws.receive_queue, hello_payload)
        push!(ws.receive_queue, ready_payload)

        # Setup Session and Channels
        session = GatewaySession()
        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)
        ready_event = Base.Event()

        token = "Bot test_token"
        intents = UInt32(0)
        shard = (0, 1)

        _gateway_loop(ws, token, intents, shard, events, commands, ready_event, session, false)

        # Verify HELLO handling (IDENTIFY sent)
        @test length(ws.sent) >= 1
        identify_msg = JSON3.read(ws.sent[1])
        @test identify_msg.op == GatewayOpcodes.IDENTIFY
        @test identify_msg.d.token == token
        @test identify_msg.d.shard == [0, 1]

        # Verify READY handling
        ready_data = JSON3.read(ready_payload) # Parse fixture to get expected values
        expected_session_id = ready_data.d.session_id
        expected_resume_url = ready_data.d.resume_gateway_url
        expected_username = ready_data.d.user.username

        @test session.session_id == expected_session_id
        @test session.resume_gateway_url == expected_resume_url
        @test !isnothing(session.heartbeat_task)
        @test session.heartbeat_state.interval_ms == 41250 # From hello fixture

        # Verify Event Dispatch
        close(events)
        dispatched = collect(events)
        @test length(dispatched) == 1
        @test dispatched[1] isa ReadyEvent
        @test dispatched[1].user.username == expected_username
    end

    @testset "Gateway Loop - Heartbeat & Resume" begin
        # Setup session with existing ID for resume
        session = GatewaySession()
        session.session_id = "existing_session"
        session.seq = 100
        session.seq_ref[] = 100

        # Load fixtures
        hello_payload = load_fixture("gateway_hello.json")
        ack_payload = load_fixture("gateway_heartbeat_ack.json")

        ws = MockWebSocket()
        push!(ws.receive_queue, hello_payload) # Triggers Resume (since we have session_id)
        push!(ws.receive_queue, ack_payload)   # Updates heartbeat state

        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)
        ready_event = Base.Event()

        _gateway_loop(ws, "Bot token", UInt32(0), (0, 1), events, commands, ready_event, session, true)

        # Verify RESUME sent
        @test length(ws.sent) >= 1
        # The first message should be RESUME because we passed resume=true and have session_id
        msg1 = JSON3.read(ws.sent[1])
        @test msg1.op == GatewayOpcodes.RESUME
        @test msg1.d.session_id == "existing_session"
        @test msg1.d.seq == 100

        # Verify Heartbeat ACK handling
        @test session.heartbeat_state.ack_received == true
        @test session.heartbeat_state.last_ack > 0.0
    end

    @testset "Gateway Loop - Invalid Session (Resumable)" begin
        payload = """{"op": 9, "d": true}"""
        ws = MockWebSocket()
        push!(ws.receive_queue, payload)
        
        session = GatewaySession()
        session.session_id = "old"
        
        events = Channel{AbstractEvent}(1)
        commands = Channel{GatewayCommand}(1)
        
        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, true)
        
        # Should exit loop. Session ID should remain (since resumable)
        @test session.session_id == "old"
    end

    @testset "Gateway Loop - Invalid Session (Non-resumable)" begin
        # d: false -> Cannot resume. Must Identify.
        payload = """{"op": 9, "d": false}"""
        ws = MockWebSocket()
        push!(ws.receive_queue, payload)
        
        session = GatewaySession()
        session.session_id = "old"
        session.seq = 50
        
        events = Channel{AbstractEvent}(1)
        commands = Channel{GatewayCommand}(1)
        
        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, true)
        
        # Should exit loop. Session ID and Seq should be cleared.
        @test isnothing(session.session_id)
        @test isnothing(session.seq)
    end
    
    @testset "Gateway Loop - Reconnect Request" begin
        # OP 7 Reconnect -> Client should close and reconnect
        payload = """{"op": 7, "d": null}"""
        ws = MockWebSocket()
        push!(ws.receive_queue, payload)
        
        session = GatewaySession()
        events = Channel{AbstractEvent}(1)
        commands = Channel{GatewayCommand}(1)
        
        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, false)
        
        # Just exits loop cleanly
        @test true 
    end
end
