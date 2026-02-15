@testitem "Gateway Logic" tags=[:unit] begin
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

    # ── HeartbeatState Unit Tests ────────────────────────────────────────────────

    @testset "HeartbeatState" begin
        state = HeartbeatState(41250)
        @test state.interval_ms == 41250
        @test state.last_send == 0.0
        @test state.last_ack == 0.0
        @test state.ack_received == true # Starts true to allow first heartbeat
        @test state.running == true

        # ACK handling
        t_before = time()
        heartbeat_ack!(state)
        t_after = time()
        @test state.ack_received == true
        @test t_before <= state.last_ack <= t_after

        # Latency calculation
        state.last_send = t_before - 0.05 # 50ms ago
        state.last_ack = t_before
        latency = heartbeat_latency(state)
        @test 49.0 <= latency <= 51.0

        # Stop
        stop_heartbeat!(state)
        @test state.running == false
    end

    @testset "Latency returns -1 before first heartbeat" begin
        state = HeartbeatState(1000)
        @test heartbeat_latency(state) == -1.0
    end

    # ── Heartbeat Actor Tests (real start_heartbeat with short intervals) ───────

    @testset "Heartbeat sends OP 1 with null seq" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 50, seq_ref, stop)  # 50ms interval
        sleep(0.2)  # Let at least one heartbeat fire
        stop_heartbeat!(state)
        wait(task)

        @test length(ws.sent) >= 1
        msg = JSON3.read(ws.sent[1])
        @test msg.op == 1
        @test msg.d === nothing
    end

    @testset "Heartbeat sends OP 1 with seq number" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(42)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 50, seq_ref, stop)
        sleep(0.2)
        stop_heartbeat!(state)
        wait(task)

        @test length(ws.sent) >= 1
        msg = JSON3.read(ws.sent[1])
        @test msg.op == 1
        @test msg.d == 42
    end

    @testset "Zombie detection — no ACK stops heartbeat" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 50, seq_ref, stop)  # 50ms interval
        # Do NOT call heartbeat_ack! — simulate missing ACK
        sleep(0.3)  # Wait for jitter + at least 2 cycles (zombie detected on 2nd)
        wait(task)

        @test state.running == false
        @test state.ack_received == false
        # Should have sent at least 1 heartbeat before detecting zombie
        @test length(ws.sent) >= 1
    end

    @testset "ACK received — heartbeat continues" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 100, seq_ref, stop)  # 100ms interval

        # Background ACK responder — ACK every 20ms to never miss a cycle
        ack_task = @async begin
            while state.running
                heartbeat_ack!(state)
                sleep(0.02)
            end
        end

        sleep(0.5)  # Let several heartbeat cycles complete

        @test state.running == true
        @test length(ws.sent) >= 2  # Multiple heartbeats sent

        stop_heartbeat!(state)
        wait(task)
        wait(ack_task)
    end

    @testset "stop_event stops heartbeat" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 50, seq_ref, stop)
        sleep(0.08)
        notify(stop)  # Signal external shutdown
        wait(task)

        # Task should have exited
        @test istaskdone(task)
    end

    @testset "seq_ref updates reflected in heartbeat" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()

        task, state = start_heartbeat(ws, 100, seq_ref, stop)  # 100ms interval

        # Background ACK responder
        ack_task = @async begin
            while state.running
                heartbeat_ack!(state)
                sleep(0.02)
            end
        end

        # Wait for first heartbeat, then update seq
        sleep(0.15)
        seq_ref[] = 99
        sleep(0.25)  # Let at least one more heartbeat fire with seq=99

        stop_heartbeat!(state)
        wait(task)
        wait(ack_task)

        # First heartbeat had null, later one should have 99
        @test length(ws.sent) >= 2
        first_msg = JSON3.read(ws.sent[1])
        @test first_msg.d === nothing
        last_msg = JSON3.read(ws.sent[end])
        @test last_msg.d == 99
    end

    # ── Gateway Loop Tests ───────────────────────────────────────────────────────

    @testset "Gateway Loop - Initial Connection" begin
        hello_payload = load_fixture("gateway_hello.json")
        ready_payload = load_fixture("gateway_ready.json")

        ws = MockWebSocket()
        push!(ws.receive_queue, hello_payload)
        push!(ws.receive_queue, ready_payload)

        session = GatewaySession()
        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)
        ready_event = Base.Event()

        token = "Bot test_token"
        intents = UInt32(0)
        shard = (0, 1)

        _gateway_loop(ws, token, intents, shard, events, commands, ready_event, session, false)

        # Verify IDENTIFY sent
        @test length(ws.sent) >= 1
        identify_msg = JSON3.read(ws.sent[1])
        @test identify_msg.op == GatewayOpcodes.IDENTIFY
        @test identify_msg.d.token == token
        @test identify_msg.d.shard == [0, 1]

        # Verify READY handling
        ready_data = JSON3.read(ready_payload)
        @test session.session_id == ready_data.d.session_id
        @test session.resume_gateway_url == ready_data.d.resume_gateway_url
        @test !isnothing(session.heartbeat_task)
        @test session.heartbeat_state.interval_ms == 41250

        # Verify Event Dispatch
        close(events)
        dispatched = collect(events)
        @test length(dispatched) == 1
        @test dispatched[1] isa ReadyEvent
        @test dispatched[1].user.username == ready_data.d.user.username
    end

    @testset "Gateway Loop - Heartbeat & Resume" begin
        session = GatewaySession()
        session.session_id = "existing_session"
        session.seq = 100
        session.seq_ref[] = 100

        hello_payload = load_fixture("gateway_hello.json")
        ack_payload = load_fixture("gateway_heartbeat_ack.json")

        ws = MockWebSocket()
        push!(ws.receive_queue, hello_payload)
        push!(ws.receive_queue, ack_payload)

        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)
        ready_event = Base.Event()

        _gateway_loop(ws, "Bot token", UInt32(0), (0, 1), events, commands, ready_event, session, true)

        # Verify RESUME sent
        @test length(ws.sent) >= 1
        msg1 = JSON3.read(ws.sent[1])
        @test msg1.op == GatewayOpcodes.RESUME
        @test msg1.d.session_id == "existing_session"
        @test msg1.d.seq == 100

        # Verify Heartbeat ACK handling
        @test session.heartbeat_state.ack_received == true
        @test session.heartbeat_state.last_ack > 0.0
    end

    @testset "Gateway Loop - Sequence number tracking" begin
        # Send two DISPATCH events with incrementing seq numbers
        dispatch1 = """{"op":0,"s":1,"t":"PRESENCE_UPDATE","d":{}}"""
        dispatch2 = """{"op":0,"s":5,"t":"PRESENCE_UPDATE","d":{}}"""

        ws = MockWebSocket()
        push!(ws.receive_queue, dispatch1)
        push!(ws.receive_queue, dispatch2)

        session = GatewaySession()
        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)

        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, false)

        @test session.seq == 5
        @test session.seq_ref[] == 5
    end

    @testset "Gateway Loop - OP 1 server heartbeat request" begin
        # Server can send OP 1 to request an immediate heartbeat
        hello_payload = load_fixture("gateway_hello.json")
        server_hb = """{"op":1,"d":null}"""

        ws = MockWebSocket()
        push!(ws.receive_queue, hello_payload)
        push!(ws.receive_queue, server_hb)

        session = GatewaySession()
        events = Channel{AbstractEvent}(10)
        commands = Channel{GatewayCommand}(10)

        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, false)

        # Should have sent IDENTIFY (from HELLO) + immediate heartbeat (from OP 1)
        sent_ops = [JSON3.read(m).op for m in ws.sent]
        @test GatewayOpcodes.IDENTIFY in sent_ops
        @test GatewayOpcodes.HEARTBEAT in sent_ops
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

        @test session.session_id == "old"
    end

    @testset "Gateway Loop - Invalid Session (Non-resumable)" begin
        payload = """{"op": 9, "d": false}"""
        ws = MockWebSocket()
        push!(ws.receive_queue, payload)

        session = GatewaySession()
        session.session_id = "old"
        session.seq = 50

        events = Channel{AbstractEvent}(1)
        commands = Channel{GatewayCommand}(1)

        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, true)

        @test isnothing(session.session_id)
        @test isnothing(session.seq)
    end

    @testset "Gateway Loop - Reconnect Request" begin
        payload = """{"op": 7, "d": null}"""
        ws = MockWebSocket()
        push!(ws.receive_queue, payload)

        session = GatewaySession()
        events = Channel{AbstractEvent}(1)
        commands = Channel{GatewayCommand}(1)

        _gateway_loop(ws, "tok", 0, (0,1), events, commands, Base.Event(), session, false)

        @test true
    end
end
