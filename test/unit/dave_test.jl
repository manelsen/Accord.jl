@testitem "DAVE state machine (mock libdave)" tags=[:unit, :dave] begin
    using Accord
    using Accord: DaveSession, LibDave, VoiceOpcodes, dave_session_description!,
        dave_handle_json!, dave_handle_binary!, dave_encrypt,
        parse_dave_binary, dave_binary_frame, _voice_heartbeat_payload

    # ── Test doubles for libdave ──────────────────────────────────────────────
    # The state machine only talks to libdave through the LibDave functions,
    # so a mock session/encryptor records what the protocol logic asks for.
    mutable struct MockSession
        calls::Vector{Any}
        commit_result::Any
        welcome_result::Any
        proposals_result::Vector{UInt8}
    end
    MockSession() = MockSession(Any[], (; failed=false, ignored=false, roster=UInt64[1, 2]),
                                UInt64[1, 2], UInt8[0x28, 0x01])
    mutable struct MockRatchet
        user::String
    end
    mutable struct MockEncryptor
        passthrough::Bool
        ratchet::Any
        ssrc_assignments::Vector{UInt32}
        next_code::Int
    end
    MockEncryptor() = MockEncryptor(true, nothing, UInt32[], 0)

    LibDave.init!(m::MockSession, v, g, u) = push!(m.calls, (:init, Int(v), UInt64(g), String(u)))
    LibDave.reset!(m::MockSession) = push!(m.calls, (:reset,))
    LibDave.set_protocol_version!(m::MockSession, v) = push!(m.calls, (:set_version, Int(v)))
    LibDave.set_external_sender!(m::MockSession, d) = push!(m.calls, (:external_sender, copy(d)))
    LibDave.key_package(m::MockSession) = UInt8[0xaa, 0xbb]
    LibDave.process_proposals(m::MockSession, p, users) =
        (push!(m.calls, (:proposals, copy(p), sort(users))); m.proposals_result)
    LibDave.process_commit(m::MockSession, c) = (push!(m.calls, (:commit, copy(c))); m.commit_result)
    LibDave.process_welcome(m::MockSession, w, users) =
        (push!(m.calls, (:welcome, copy(w), sort(users))); m.welcome_result)
    LibDave.key_ratchet(m::MockSession, user) = MockRatchet(String(user))
    LibDave.set_passthrough!(e::MockEncryptor, on::Bool) = (e.passthrough = on; nothing)
    LibDave.set_key_ratchet!(e::MockEncryptor, k) = (e.ratchet = k; nothing)
    LibDave.assign_opus_ssrc!(e::MockEncryptor, ssrc) = push!(e.ssrc_assignments, UInt32(ssrc))
    function LibDave.encrypt(e::MockEncryptor, ssrc, frame)
        e.passthrough && return (Cint(0), copy(frame))
        isnothing(e.ratchet) && return (LibDave.ENCRYPT_MISSING_KEY_RATCHET, UInt8[])
        e.next_code == 0 ? (Cint(0), vcat(frame, UInt8[0xfa, 0xfa])) : (Cint(e.next_code), UInt8[])
    end

    function new_session(; user="42", channel=1234)
        sent = Any[]
        ds = DaveSession(user, channel;
            send_json = (op, d) -> push!(sent, (:json, op, d)),
            send_binary = (op, p) -> push!(sent, (:binary, op, copy(p))),
            session = MockSession(), encryptor = MockEncryptor())
        return ds, sent
    end

    # A transition announcement payload: uint16 transition id + body
    framed(tid, body) = vcat(UInt8[tid >> 8, tid & 0xff], body)

    @testset "session description starts the group and sends a key package" begin
        ds, sent = new_session()
        @test ds.encryptor.passthrough          # nothing encrypted before an epoch
        dave_session_description!(ds, 1)
        @test ds.session.calls[end] == (:init, 1, UInt64(1234), "42")
        @test sent[end] == (:binary, VoiceOpcodes.DAVE_MLS_KEY_PACKAGE, UInt8[0xaa, 0xbb])
        # E2EE required but no key yet: frames are dropped, not sent in clear
        @test !ds.encryptor.passthrough
        @test isnothing(dave_encrypt(ds, 1, UInt8[1, 2]))
    end

    @testset "version 0 in the session description means no E2EE" begin
        ds, sent = new_session()
        dave_session_description!(ds, 0)
        @test ds.session.calls[end] == (:reset,)
        @test isempty(sent)
        @test dave_encrypt(ds, 99, UInt8[1, 2, 3]) == UInt8[1, 2, 3]
    end

    @testset "external sender is handed to libdave" begin
        ds, _ = new_session()
        @test dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_EXTERNAL_SENDER, UInt8[9, 8, 7])
        @test ds.session.calls[end] == (:external_sender, UInt8[9, 8, 7])
    end

    @testset "proposals use the recognized users and answer with a commit" begin
        ds, sent = new_session()
        dave_handle_json!(ds, VoiceOpcodes.CLIENTS_CONNECT, Dict("user_ids" => ["7", "8"]))
        dave_handle_json!(ds, VoiceOpcodes.CLIENT_DISCONNECT, Dict("user_id" => "8"))
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_PROPOSALS, UInt8[0x00, 0x05])
        @test ds.session.calls[end] == (:proposals, UInt8[0x00, 0x05], ["42", "7"])
        @test sent[end] == (:binary, VoiceOpcodes.DAVE_MLS_COMMIT_WELCOME, UInt8[0x28, 0x01])

        # nothing to commit -> nothing sent
        ds.session.proposals_result = UInt8[]
        n = length(sent)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_PROPOSALS, UInt8[0x01])
        @test length(sent) == n
    end

    @testset "announced commit: ready now, switch keys only on execute" begin
        ds, sent = new_session()
        dave_session_description!(ds, 1)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION, framed(5, UInt8[0xc0]))
        @test ds.session.calls[end] == (:commit, UInt8[0xc0])
        @test sent[end] == (:json, VoiceOpcodes.DAVE_TRANSITION_READY, Dict("transition_id" => 5))
        @test isnothing(ds.encryptor.ratchet)     # not switched yet
        @test isnothing(dave_encrypt(ds, 1, UInt8[1]))

        dave_handle_json!(ds, VoiceOpcodes.DAVE_EXECUTE_TRANSITION, Dict("transition_id" => 5))
        @test !ds.encryptor.passthrough
        @test ds.encryptor.ratchet.user == "42"   # our own sender ratchet
        @test dave_encrypt(ds, 1, UInt8[1]) == UInt8[1, 0xfa, 0xfa]
    end

    @testset "welcome with transition 0 executes immediately" begin
        ds, sent = new_session()
        dave_session_description!(ds, 1)
        n = length(sent)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_WELCOME, framed(0, UInt8[0x77]))
        @test ds.session.calls[end] == (:welcome, UInt8[0x77], ["42"])
        @test length(sent) == n                   # no op23 for transition 0
        @test !ds.encryptor.passthrough
    end

    @testset "failed commit or welcome: report and rejoin" begin
        ds, sent = new_session()
        dave_session_description!(ds, 1)
        ds.session.commit_result = (; failed=true, ignored=false, roster=UInt64[])
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION, framed(9, UInt8[0x01]))
        @test (:json, VoiceOpcodes.DAVE_MLS_INVALID_COMMIT_WELCOME, Dict("transition_id" => 9)) in sent
        @test sent[end] == (:binary, VoiceOpcodes.DAVE_MLS_KEY_PACKAGE, UInt8[0xaa, 0xbb])

        ds2, sent2 = new_session()
        dave_session_description!(ds2, 1)
        ds2.session.welcome_result = nothing
        dave_handle_binary!(ds2, VoiceOpcodes.DAVE_MLS_WELCOME, framed(3, UInt8[0x01]))
        @test (:json, VoiceOpcodes.DAVE_MLS_INVALID_COMMIT_WELCOME, Dict("transition_id" => 3)) in sent2
    end

    @testset "ignored commits change nothing" begin
        ds, sent = new_session()
        dave_session_description!(ds, 1)
        ds.session.commit_result = (; failed=false, ignored=true, roster=UInt64[])
        n = length(sent)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION, framed(4, UInt8[0x01]))
        @test length(sent) == n
        @test isempty(ds.pending)
    end

    @testset "downgrade to version 0 via prepare/execute transition" begin
        ds, sent = new_session()
        dave_session_description!(ds, 1)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_WELCOME, framed(0, UInt8[0x01]))
        @test !ds.encryptor.passthrough

        dave_handle_json!(ds, VoiceOpcodes.DAVE_PREPARE_TRANSITION,
                          Dict("transition_id" => 7, "protocol_version" => 0))
        @test sent[end] == (:json, VoiceOpcodes.DAVE_TRANSITION_READY, Dict("transition_id" => 7))
        dave_handle_json!(ds, VoiceOpcodes.DAVE_EXECUTE_TRANSITION, Dict("transition_id" => 7))
        @test ds.encryptor.passthrough
        @test ds.protocol_version == 0
        @test dave_encrypt(ds, 1, UInt8[5]) == UInt8[5]
    end

    @testset "prepare epoch: epoch 1 rebuilds the group, later epochs change version" begin
        ds, sent = new_session()
        dave_handle_json!(ds, VoiceOpcodes.DAVE_PREPARE_EPOCH, Dict("protocol_version" => 1, "epoch" => 1))
        @test ds.session.calls[end] == (:init, 1, UInt64(1234), "42")
        @test sent[end][2] == VoiceOpcodes.DAVE_MLS_KEY_PACKAGE
        dave_handle_json!(ds, VoiceOpcodes.DAVE_PREPARE_EPOCH, Dict("protocol_version" => 2, "epoch" => 6))
        @test ds.session.calls[end] == (:set_version, 2)
    end

    @testset "frame encryption" begin
        ds, _ = new_session()
        dave_session_description!(ds, 1)
        dave_handle_binary!(ds, VoiceOpcodes.DAVE_MLS_WELCOME, framed(0, UInt8[0x01]))

        @test dave_encrypt(ds, 555, UInt8[1, 2]) == UInt8[1, 2, 0xfa, 0xfa]
        dave_encrypt(ds, 555, UInt8[3])
        @test ds.encryptor.ssrc_assignments == UInt32[555]   # assigned once

        ds.encryptor.next_code = Int(LibDave.ENCRYPT_MISSING_KEY_RATCHET)
        @test isnothing(dave_encrypt(ds, 555, UInt8[1]))     # dropped, never sent in clear
    end

    @testset "unknown opcodes are not consumed" begin
        ds, _ = new_session()
        @test !dave_handle_json!(ds, 99, Dict())
        @test !dave_handle_binary!(ds, 99, UInt8[])
    end

    @testset "binary framing" begin
        seq, op, payload = parse_dave_binary(UInt8[0x01, 0x02, 25, 0xaa, 0xbb])
        @test seq == 0x0102
        @test op == 25
        @test payload == UInt8[0xaa, 0xbb]
        @test_throws ArgumentError parse_dave_binary(UInt8[0x00, 0x01])
        @test dave_binary_frame(26, UInt8[1, 2]) == UInt8[26, 1, 2]
    end

    @testset "voice gateway v8 heartbeat carries seq_ack" begin
        @test _voice_heartbeat_payload(123, 10) == Dict("t" => 123, "seq_ack" => 10)
    end

    @testset "voice opcodes match the documentation" begin
        @test VoiceOpcodes.CLIENTS_CONNECT == 11
        @test VoiceOpcodes.CLIENT_DISCONNECT == 13
        @test VoiceOpcodes.DAVE_PREPARE_TRANSITION == 21
        @test VoiceOpcodes.DAVE_MLS_EXTERNAL_SENDER == 25
        @test VoiceOpcodes.DAVE_MLS_KEY_PACKAGE == 26
        @test VoiceOpcodes.DAVE_MLS_WELCOME == 30
        @test VoiceOpcodes.DAVE_MLS_INVALID_COMMIT_WELCOME == 31
    end
end

@testitem "libdave bindings (real library)" tags=[:unit, :dave] begin
    using Accord
    using Accord: LibDave, DaveSession, VoiceOpcodes, dave_session_description!, dave_encrypt

    if get(ENV, "ACCORD_REQUIRE_LIBDAVE", "") == "1"
        @testset "libdave is loaded in the DAVE CI job" begin
            @test LibDave.available()
        end
    end

    if !LibDave.available()
        @test_skip "set ACCORD_LIBDAVE to run the libdave tests"
    else
        @testset "version" begin
            @test LibDave.max_protocol_version() >= 1
        end

        @testset "session produces an MLS key package" begin
            s = LibDave.Session()
            LibDave.init!(s, 1, 1234, "42")
            kp = LibDave.key_package(s)
            # MLS structures start with the protocol version mls10 (0x0001)
            @test length(kp) > 100
            @test kp[1:2] == UInt8[0x00, 0x01]
            @test LibDave.protocol_version(s) == 1
            # A fresh package each time we (re)join
            LibDave.init!(s, 1, 1234, "42")
            @test LibDave.key_package(s) != kp
            LibDave.destroy!(s)
        end

        @testset "garbage MLS input fails cleanly" begin
            s = LibDave.Session()
            LibDave.init!(s, 1, 1234, "42")
            @test LibDave.process_commit(s, UInt8[0x01, 0x02, 0x03]).failed
            @test isempty(LibDave.process_proposals(s, UInt8[0x00, 0xff], ["42"]))
            @test isnothing(LibDave.process_welcome(s, UInt8[0x01, 0x02], ["42"]))
            @test isnothing(LibDave.key_ratchet(s, "42"))   # no group yet
        end

        @testset "encryptor: passthrough, and no key means no frame" begin
            e = LibDave.Encryptor()
            LibDave.assign_opus_ssrc!(e, 1234)
            LibDave.set_passthrough!(e, true)
            @test LibDave.is_passthrough(e)
            code, out = LibDave.encrypt(e, 1234, UInt8[1, 2, 3, 4])
            @test code == LibDave.ENCRYPT_SUCCESS
            @test out == UInt8[1, 2, 3, 4]

            LibDave.set_passthrough!(e, false)
            @test !LibDave.has_key_ratchet(e)
            code, out = LibDave.encrypt(e, 1234, UInt8[1, 2, 3, 4])
            @test code == LibDave.ENCRYPT_MISSING_KEY_RATCHET
            @test isempty(out)
        end

        @testset "decryptor passthrough" begin
            d = LibDave.Decryptor()
            LibDave.transition_to_passthrough!(d, true)
            code, out = LibDave.decrypt(d, UInt8[9, 8, 7])
            @test code == LibDave.DECRYPT_SUCCESS
            @test out == UInt8[9, 8, 7]
        end

        @testset "DaveSession on the real library sends a real key package" begin
            sent = Any[]
            ds = DaveSession("42", 1234;
                send_json = (op, d) -> push!(sent, (op, d)),
                send_binary = (op, p) -> push!(sent, (op, copy(p))))
            dave_session_description!(ds, 1)
            @test sent[end][1] == VoiceOpcodes.DAVE_MLS_KEY_PACKAGE
            @test sent[end][2][1:2] == UInt8[0x00, 0x01]
            # Before any epoch: frames are dropped, never sent unencrypted
            @test isnothing(dave_encrypt(ds, 1234, UInt8[1, 2, 3]))
        end
    end
end
