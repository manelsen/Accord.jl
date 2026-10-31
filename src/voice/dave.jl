# DAVE (Discord Audio & Video End-to-End Encryption) state machine
#
# Internal module: Tracks the MLS group for one voice connection and reacts to
# the voice gateway's DAVE opcodes (21–31, plus 11/13 for the participant
# list). The cryptography is done by libdave (see libdave.jl); this file is the
# protocol glue around it. Reference: https://daveprotocol.com
#
# Opcode flow, summarised:
#   op4  session description → initial protocol version (0 = no E2EE)
#   op25 external sender     → libdave creates a pending group
#   op26 key package         ← sent on (re)initialisation
#   op27 proposals           → op28 commit/welcome (if we have something to commit)
#   op29 announced commit    → apply, then op23 "ready for transition"
#   op30 welcome             → join, then op23
#   op21 prepare transition  → remember it; op23 (transition 0 executes at once)
#   op22 execute transition  → switch our encryptor to the new epoch/version
#   op24 prepare epoch       → epoch 1 means a new group: reinitialise
#   op31 invalid commit/welcome ← sent when we can't apply one; then reinitialise

"""
    DaveSession

Per-connection DAVE state. Created by the voice gateway when the server
announces a DAVE protocol version; frames go through [`dave_encrypt`](@ref)
before transport encryption.
"""
mutable struct DaveSession
    session::Any                  # LibDave.Session (or a test double)
    encryptor::Any                # LibDave.Encryptor (or a test double)
    user_id::String
    channel_id::UInt64
    protocol_version::Int
    connected_users::Set{String}  # from clients_connect / client_disconnect
    pending::Dict{Int, Int}       # transition_id => protocol version it moves to
    pending_ratchet::Any          # our own key ratchet for the epoch being prepared
    ssrc::UInt32
    lock::ReentrantLock
    send_json::Function           # (op, data::Dict) -> nothing
    send_binary::Function         # (op, payload::Vector{UInt8}) -> nothing
end

function DaveSession(user_id::AbstractString, channel_id::Integer;
                     send_json::Function, send_binary::Function,
                     session=LibDave.Session(), encryptor=LibDave.Encryptor())
    ds = DaveSession(session, encryptor, String(user_id), UInt64(channel_id), 0,
                     Set{String}(), Dict{Int, Int}(), nothing, UInt32(0), ReentrantLock(),
                     send_json, send_binary)
    LibDave.set_passthrough!(encryptor, true)   # protocol version 0 until told otherwise
    return ds
end

_recognized_users(ds::DaveSession) = collect(push!(copy(ds.connected_users), ds.user_id))

# (Re)create the local MLS state for the current protocol version and announce
# a fresh key package. Key packages are single-use, so this runs every time we
# need to (re)join.
function _reinit!(ds::DaveSession)
    if ds.protocol_version > 0
        LibDave.init!(ds.session, ds.protocol_version, ds.channel_id, ds.user_id)
        # E2EE is required from here on: until an epoch gives us a key, frames
        # are dropped rather than sent unencrypted.
        LibDave.set_passthrough!(ds.encryptor, false)
        ds.send_binary(VoiceOpcodes.DAVE_MLS_KEY_PACKAGE, LibDave.key_package(ds.session))
    else
        LibDave.reset!(ds.session)
        LibDave.set_passthrough!(ds.encryptor, true)
    end
    nothing
end

# Switch our outgoing frames to what a transition announced.
function _execute_transition!(ds::DaveSession, transition_id::Integer)
    version = pop!(ds.pending, transition_id, nothing)
    isnothing(version) && (@debug "DAVE: execute for unknown transition" transition_id; return)
    old = ds.protocol_version
    ds.protocol_version = version
    if version == 0
        @info "DAVE: downgraded to unencrypted media" transition_id
        LibDave.set_passthrough!(ds.encryptor, true)
    elseif !isnothing(ds.pending_ratchet)
        LibDave.set_key_ratchet!(ds.encryptor, ds.pending_ratchet)
        LibDave.set_passthrough!(ds.encryptor, false)
        ds.pending_ratchet = nothing
        old == 0 && @info "DAVE: end-to-end encryption active" protocol_version=version
    end
    nothing
end

# A commit or welcome left us in a new epoch: fetch our sender ratchet and
# get ready to execute the transition.
function _prepare_new_epoch!(ds::DaveSession, transition_id::Integer)
    ds.pending_ratchet = LibDave.key_ratchet(ds.session, ds.user_id)
    ds.pending[transition_id] = ds.protocol_version
    if transition_id == 0
        _execute_transition!(ds, 0)   # (re)initialisation executes immediately
    else
        ds.send_json(VoiceOpcodes.DAVE_TRANSITION_READY, Dict("transition_id" => transition_id))
    end
end

# We couldn't apply a commit/welcome: tell the gateway and rejoin.
function _recover!(ds::DaveSession, transition_id::Integer)
    @warn "DAVE: invalid commit/welcome, rejoining the group" transition_id
    ds.send_json(VoiceOpcodes.DAVE_MLS_INVALID_COMMIT_WELCOME, Dict("transition_id" => transition_id))
    _reinit!(ds)
end

"""
    dave_session_description!(ds, protocol_version)

Handle the DAVE part of opcode 4: start (or skip) E2EE at the given version.
"""
function dave_session_description!(ds::DaveSession, protocol_version::Integer)
    lock(ds.lock) do
        ds.protocol_version = protocol_version
        _reinit!(ds)
    end
end

"""
    dave_handle_json!(ds, op, d)

Handle a JSON DAVE opcode (11, 13, 21, 22, 24). Returns `true` if `op` was a
DAVE opcode.
"""
function dave_handle_json!(ds::DaveSession, op::Integer, d)
    lock(ds.lock) do
        if op == VoiceOpcodes.CLIENTS_CONNECT
            union!(ds.connected_users, string.(d["user_ids"]))
        elseif op == VoiceOpcodes.CLIENT_DISCONNECT
            delete!(ds.connected_users, string(d["user_id"]))
        elseif op == VoiceOpcodes.DAVE_PREPARE_TRANSITION
            tid = Int(d["transition_id"])
            ds.pending[tid] = Int(d["protocol_version"])
            if tid == 0
                _execute_transition!(ds, 0)
            else
                ds.send_json(VoiceOpcodes.DAVE_TRANSITION_READY, Dict("transition_id" => tid))
            end
        elseif op == VoiceOpcodes.DAVE_EXECUTE_TRANSITION
            _execute_transition!(ds, Int(d["transition_id"]))
        elseif op == VoiceOpcodes.DAVE_PREPARE_EPOCH
            version = Int(d["protocol_version"])
            if Int(d["epoch"]) == 1
                # A new group is being created for this protocol version
                ds.protocol_version = version
                _reinit!(ds)
            else
                LibDave.set_protocol_version!(ds.session, version)
            end
        else
            return false
        end
        return true
    end
end

"""
    dave_handle_binary!(ds, op, payload)

Handle a binary DAVE opcode (25, 27, 29, 30). `payload` excludes the sequence
number and opcode bytes.
"""
function dave_handle_binary!(ds::DaveSession, op::Integer, payload::Vector{UInt8})
    lock(ds.lock) do
        if op == VoiceOpcodes.DAVE_MLS_EXTERNAL_SENDER
            LibDave.set_external_sender!(ds.session, payload)
        elseif op == VoiceOpcodes.DAVE_MLS_PROPOSALS
            commit_welcome = LibDave.process_proposals(ds.session, payload, _recognized_users(ds))
            isempty(commit_welcome) ||
                ds.send_binary(VoiceOpcodes.DAVE_MLS_COMMIT_WELCOME, commit_welcome)
        elseif op == VoiceOpcodes.DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION
            length(payload) >= 2 || return false
            tid = _transition_id(payload)
            result = LibDave.process_commit(ds.session, payload[3:end])
            if result.failed
                _recover!(ds, tid)
            elseif !result.ignored
                _prepare_new_epoch!(ds, tid)
            end
        elseif op == VoiceOpcodes.DAVE_MLS_WELCOME
            length(payload) >= 2 || return false
            tid = _transition_id(payload)
            roster = LibDave.process_welcome(ds.session, payload[3:end], _recognized_users(ds))
            isnothing(roster) ? _recover!(ds, tid) : _prepare_new_epoch!(ds, tid)
        else
            return false
        end
        return true
    end
end

_transition_id(payload::Vector{UInt8}) = (Int(payload[1]) << 8) | Int(payload[2])

"""
    dave_encrypt(ds, ssrc, opus) -> Union{Vector{UInt8}, Nothing}

E2EE-encrypt one outgoing Opus frame. Returns the frame unchanged when E2EE
is off (protocol version 0), and `nothing` when the frame must be dropped
because the key for the current epoch isn't ready yet.
"""
function dave_encrypt(ds::DaveSession, ssrc::Integer, opus::Vector{UInt8})
    lock(ds.lock) do
        ds.protocol_version == 0 && return opus
        if ds.ssrc != ssrc
            LibDave.assign_opus_ssrc!(ds.encryptor, ssrc)
            ds.ssrc = UInt32(ssrc)
        end
        code, frame = LibDave.encrypt(ds.encryptor, ssrc, opus)
        code == LibDave.ENCRYPT_SUCCESS && return frame
        code == LibDave.ENCRYPT_MISSING_KEY_RATCHET ||
            @warn "DAVE: frame encryption failed" code maxlog=10
        return nothing
    end
end

# ── Binary framing (voice gateway) ────────────────────────────────────────────

"""
    parse_dave_binary(frame) -> (seq, op, payload)

Split a server→client binary voice gateway frame: big-endian uint16 sequence
number, uint8 opcode, then the payload.
"""
function parse_dave_binary(frame::AbstractVector{UInt8})
    length(frame) >= 3 || throw(ArgumentError("binary voice frame too short ($(length(frame)) bytes)"))
    seq = (Int(frame[1]) << 8) | Int(frame[2])
    return seq, Int(frame[3]), Vector{UInt8}(frame[4:end])
end

"""Client→server binary frame: opcode byte followed by the payload (no sequence number)."""
dave_binary_frame(op::Integer, payload::AbstractVector{UInt8}) = vcat(UInt8(op), payload)
