# Bindings to libdave, Discord's reference implementation of the DAVE protocol
# (end-to-end encryption for voice), through its C API (`dave.h`).
#
# libdave is not bundled yet. Point Accord at a shared build with the
# ACCORD_LIBDAVE environment variable (or `LibDave.load!(path)`) before
# connecting to voice. Without it, voice connects with
# `max_dave_protocol_version = 0`, which Discord rejects for E2EE calls.

"""
    Accord.LibDave

Low-level bindings to libdave's C API. You normally don't call these directly:
[`VoiceClient`](@ref) drives the DAVE session. Load the library with
`ENV["ACCORD_LIBDAVE"] = "/path/to/libdave.so"` (read on first use) or
[`LibDave.load!`](@ref).
"""
module LibDave

using Libdl

const _handle = Ref{Ptr{Cvoid}}(C_NULL)
const _path = Ref{String}("")
const _symbols = Dict{Symbol, Ptr{Cvoid}}()
const _lock = ReentrantLock()

const _SYMBOLS = (:daveCommitResultDestroy, :daveCommitResultGetRosterMemberIds, :daveCommitResultIsFailed, :daveCommitResultIsIgnored, :daveDecryptorCreate, :daveDecryptorDecrypt, :daveDecryptorDestroy, :daveDecryptorGetMaxPlaintextByteSize, :daveDecryptorTransitionToKeyRatchet, :daveDecryptorTransitionToPassthroughMode, :daveEncryptorAssignSsrcToCodec, :daveEncryptorCreate, :daveEncryptorDestroy, :daveEncryptorEncrypt, :daveEncryptorGetMaxCiphertextByteSize, :daveEncryptorHasKeyRatchet, :daveEncryptorIsPassthroughMode, :daveEncryptorSetKeyRatchet, :daveEncryptorSetPassthroughMode, :daveFree, :daveKeyRatchetDestroy, :daveMaxSupportedProtocolVersion, :daveSessionCreate, :daveSessionDestroy, :daveSessionGetKeyRatchet, :daveSessionGetMarshalledKeyPackage, :daveSessionGetProtocolVersion, :daveSessionInit, :daveSessionProcessCommit, :daveSessionProcessProposals, :daveSessionProcessWelcome, :daveSessionReset, :daveSessionSetExternalSender, :daveSessionSetProtocolVersion, :daveWelcomeResultDestroy, :daveWelcomeResultGetRosterMemberIds,)

# libdave enums (dave.h)
const CODEC_OPUS = Cint(1)
const MEDIA_AUDIO = Cint(0)
const ENCRYPT_SUCCESS = Cint(0)
const ENCRYPT_MISSING_KEY_RATCHET = Cint(2)
const DECRYPT_SUCCESS = Cint(0)

"""
    load!(path=get(ENV, "ACCORD_LIBDAVE", "")) -> Bool

Load libdave from `path`. Returns `true` when the library is loaded (now or
before), `false` when no path is configured. Throws if the path is set but the
library cannot be opened.
"""
function load!(path::AbstractString=get(ENV, "ACCORD_LIBDAVE", ""))
    lock(_lock) do
        _handle[] != C_NULL && return true
        isempty(path) && return false
        h = Libdl.dlopen(path)
        # Resolve every symbol up front: finalizers call into libdave and must
        # not take locks or touch the loader.
        for name in _SYMBOLS
            _symbols[name] = Libdl.dlsym(h, name)
        end
        _path[] = path
        _handle[] = h
        return true
    end
end

"""
    available() -> Bool

Whether libdave is loaded or can be loaded from `ACCORD_LIBDAVE`.
"""
available() = try
    load!()
catch e
    @error "Could not load libdave" path=get(ENV, "ACCORD_LIBDAVE", "") exception=e
    false
end

function _sym(name::Symbol)
    if _handle[] == C_NULL && !load!()
        error("libdave is not loaded: set ENV[\"ACCORD_LIBDAVE\"] to the path of the libdave shared library")
    end
    return _symbols[name]
end

# Copy a library-allocated buffer into Julia memory and release it with daveFree.
function _take_bytes(ptr::Ptr{UInt8}, len::Integer)
    ptr == C_NULL && return UInt8[]
    out = copy(unsafe_wrap(Array, ptr, Int(len)))
    ccall(_sym(:daveFree), Cvoid, (Ptr{Cvoid},), ptr)
    return out
end

function _take_ids(ptr::Ptr{UInt64}, len::Integer)
    ptr == C_NULL && return UInt64[]
    out = copy(unsafe_wrap(Array, ptr, Int(len)))
    ccall(_sym(:daveFree), Cvoid, (Ptr{Cvoid},), ptr)
    return out
end

"""Highest DAVE protocol version the loaded libdave supports."""
max_protocol_version() = Int(ccall(_sym(:daveMaxSupportedProtocolVersion), UInt16, ()))

# MLS failures are reported through a C callback, synchronously, on the
# calling thread.
function _mls_failure(source::Cstring, reason::Cstring, ::Ptr{Cvoid})
    @error "DAVE MLS failure" source=unsafe_string(source) reason=unsafe_string(reason)
    return nothing
end

# ── Session ───────────────────────────────────────────────────────────────────

"""MLS group state for one voice connection (`DAVESessionHandle`)."""
mutable struct Session
    handle::Ptr{Cvoid}
    function Session()
        cb = @cfunction(_mls_failure, Cvoid, (Cstring, Cstring, Ptr{Cvoid}))
        h = ccall(_sym(:daveSessionCreate), Ptr{Cvoid},
                  (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}, Ptr{Cvoid}),
                  C_NULL, C_NULL, cb, C_NULL)
        h == C_NULL && error("daveSessionCreate failed")
        s = new(h)
        finalizer(destroy!, s)
    end
end

function destroy!(s::Session)
    if s.handle != C_NULL
        ccall(_sym(:daveSessionDestroy), Cvoid, (Ptr{Cvoid},), s.handle)
        s.handle = C_NULL
    end
    nothing
end

init!(s::Session, version::Integer, group_id::Integer, self_user_id::AbstractString) =
    ccall(_sym(:daveSessionInit), Cvoid, (Ptr{Cvoid}, UInt16, UInt64, Cstring),
          s.handle, version, group_id, self_user_id)

reset!(s::Session) = ccall(_sym(:daveSessionReset), Cvoid, (Ptr{Cvoid},), s.handle)

set_protocol_version!(s::Session, version::Integer) =
    ccall(_sym(:daveSessionSetProtocolVersion), Cvoid, (Ptr{Cvoid}, UInt16), s.handle, version)

protocol_version(s::Session) =
    Int(ccall(_sym(:daveSessionGetProtocolVersion), UInt16, (Ptr{Cvoid},), s.handle))

set_external_sender!(s::Session, data::Vector{UInt8}) =
    ccall(_sym(:daveSessionSetExternalSender), Cvoid, (Ptr{Cvoid}, Ptr{UInt8}, Csize_t),
          s.handle, data, length(data))

"""Serialized MLS key package to send to the voice gateway (opcode 26)."""
function key_package(s::Session)
    out = Ref{Ptr{UInt8}}(C_NULL)
    len = Ref{Csize_t}(0)
    ccall(_sym(:daveSessionGetMarshalledKeyPackage), Cvoid,
          (Ptr{Cvoid}, Ptr{Ptr{UInt8}}, Ptr{Csize_t}), s.handle, out, len)
    _take_bytes(out[], len[])
end

"""
    process_proposals(s, payload, recognized_user_ids) -> Vector{UInt8}

Process an opcode 27 payload (operation type byte + proposals). Returns the
commit/welcome bytes to send back (opcode 28), or an empty vector when there
is nothing to commit.
"""
function process_proposals(s::Session, payload::Vector{UInt8}, recognized::Vector{String})
    out = Ref{Ptr{UInt8}}(C_NULL)
    len = Ref{Csize_t}(0)
    GC.@preserve recognized begin
        ids = [Base.unsafe_convert(Cstring, id) for id in recognized]
        ccall(_sym(:daveSessionProcessProposals), Cvoid,
              (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{Cstring}, Csize_t, Ptr{Ptr{UInt8}}, Ptr{Csize_t}),
              s.handle, payload, length(payload), ids, length(ids), out, len)
    end
    _take_bytes(out[], len[])
end

"""
    process_commit(s, commit) -> (; failed, ignored, roster)

Apply an announced commit (opcode 29).
"""
function process_commit(s::Session, commit::Vector{UInt8})
    h = ccall(_sym(:daveSessionProcessCommit), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{UInt8}, Csize_t),
              s.handle, commit, length(commit))
    h == C_NULL && return (; failed=true, ignored=false, roster=UInt64[])
    try
        failed = ccall(_sym(:daveCommitResultIsFailed), Bool, (Ptr{Cvoid},), h)
        ignored = ccall(_sym(:daveCommitResultIsIgnored), Bool, (Ptr{Cvoid},), h)
        ids = Ref{Ptr{UInt64}}(C_NULL)
        len = Ref{Csize_t}(0)
        ccall(_sym(:daveCommitResultGetRosterMemberIds), Cvoid,
              (Ptr{Cvoid}, Ptr{Ptr{UInt64}}, Ptr{Csize_t}), h, ids, len)
        return (; failed, ignored, roster=_take_ids(ids[], len[]))
    finally
        ccall(_sym(:daveCommitResultDestroy), Cvoid, (Ptr{Cvoid},), h)
    end
end

"""
    process_welcome(s, welcome, recognized_user_ids) -> Union{Vector{UInt64}, Nothing}

Join the group from a Welcome (opcode 30). Returns the roster, or `nothing`
when the welcome could not be processed.
"""
function process_welcome(s::Session, welcome::Vector{UInt8}, recognized::Vector{String})
    h = GC.@preserve recognized begin
        ids = [Base.unsafe_convert(Cstring, id) for id in recognized]
        ccall(_sym(:daveSessionProcessWelcome), Ptr{Cvoid},
              (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{Cstring}, Csize_t),
              s.handle, welcome, length(welcome), ids, length(ids))
    end
    h == C_NULL && return nothing
    try
        out = Ref{Ptr{UInt64}}(C_NULL)
        len = Ref{Csize_t}(0)
        ccall(_sym(:daveWelcomeResultGetRosterMemberIds), Cvoid,
              (Ptr{Cvoid}, Ptr{Ptr{UInt64}}, Ptr{Csize_t}), h, out, len)
        return _take_ids(out[], len[])
    finally
        ccall(_sym(:daveWelcomeResultDestroy), Cvoid, (Ptr{Cvoid},), h)
    end
end

# ── Key ratchet ───────────────────────────────────────────────────────────────

"""Per-sender key ratchet (`DAVEKeyRatchetHandle`)."""
mutable struct KeyRatchet
    handle::Ptr{Cvoid}
    function KeyRatchet(h::Ptr{Cvoid})
        k = new(h)
        finalizer(destroy!, k)
    end
end

function destroy!(k::KeyRatchet)
    if k.handle != C_NULL
        ccall(_sym(:daveKeyRatchetDestroy), Cvoid, (Ptr{Cvoid},), k.handle)
        k.handle = C_NULL
    end
    nothing
end

"""Key ratchet for `user_id` in the current epoch, or `nothing`."""
function key_ratchet(s::Session, user_id::AbstractString)
    h = ccall(_sym(:daveSessionGetKeyRatchet), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), s.handle, user_id)
    h == C_NULL ? nothing : KeyRatchet(h)
end

# ── Encryptor ─────────────────────────────────────────────────────────────────

"""
Frame encryptor (`DAVEEncryptorHandle`). Holds a reference to its key ratchet,
because libdave does not take ownership of it.
"""
mutable struct Encryptor
    handle::Ptr{Cvoid}
    ratchet::Union{KeyRatchet, Nothing}
    function Encryptor()
        h = ccall(_sym(:daveEncryptorCreate), Ptr{Cvoid}, ())
        h == C_NULL && error("daveEncryptorCreate failed")
        e = new(h, nothing)
        finalizer(destroy!, e)
    end
end

function destroy!(e::Encryptor)
    if e.handle != C_NULL
        ccall(_sym(:daveEncryptorDestroy), Cvoid, (Ptr{Cvoid},), e.handle)
        e.handle = C_NULL
    end
    nothing
end

function set_key_ratchet!(e::Encryptor, k::KeyRatchet)
    ccall(_sym(:daveEncryptorSetKeyRatchet), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), e.handle, k.handle)
    e.ratchet = k   # keep it alive while the encryptor uses it
    nothing
end

set_passthrough!(e::Encryptor, on::Bool) =
    ccall(_sym(:daveEncryptorSetPassthroughMode), Cvoid, (Ptr{Cvoid}, Bool), e.handle, on)

is_passthrough(e::Encryptor) =
    ccall(_sym(:daveEncryptorIsPassthroughMode), Bool, (Ptr{Cvoid},), e.handle)

has_key_ratchet(e::Encryptor) =
    ccall(_sym(:daveEncryptorHasKeyRatchet), Bool, (Ptr{Cvoid},), e.handle)

assign_opus_ssrc!(e::Encryptor, ssrc::Integer) =
    ccall(_sym(:daveEncryptorAssignSsrcToCodec), Cvoid, (Ptr{Cvoid}, UInt32, Cint),
          e.handle, ssrc, CODEC_OPUS)

"""
    encrypt(e, ssrc, frame) -> (code, bytes)

Encrypt one Opus frame. `code` is libdave's result code (0 on success).
"""
function encrypt(e::Encryptor, ssrc::Integer, frame::Vector{UInt8})
    cap = ccall(_sym(:daveEncryptorGetMaxCiphertextByteSize), Csize_t,
                (Ptr{Cvoid}, Cint, Csize_t), e.handle, MEDIA_AUDIO, length(frame))
    out = Vector{UInt8}(undef, cap)
    written = Ref{Csize_t}(0)
    code = ccall(_sym(:daveEncryptorEncrypt), Cint,
                 (Ptr{Cvoid}, Cint, UInt32, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t, Ptr{Csize_t}),
                 e.handle, MEDIA_AUDIO, ssrc, frame, length(frame), out, cap, written)
    resize!(out, code == ENCRYPT_SUCCESS ? written[] : 0)
    return code, out
end

# ── Decryptor ─────────────────────────────────────────────────────────────────

"""Frame decryptor for one remote sender (`DAVEDecryptorHandle`)."""
mutable struct Decryptor
    handle::Ptr{Cvoid}
    ratchet::Union{KeyRatchet, Nothing}
    function Decryptor()
        h = ccall(_sym(:daveDecryptorCreate), Ptr{Cvoid}, ())
        h == C_NULL && error("daveDecryptorCreate failed")
        d = new(h, nothing)
        finalizer(destroy!, d)
    end
end

function destroy!(d::Decryptor)
    if d.handle != C_NULL
        ccall(_sym(:daveDecryptorDestroy), Cvoid, (Ptr{Cvoid},), d.handle)
        d.handle = C_NULL
    end
    nothing
end

function transition_to_key_ratchet!(d::Decryptor, k::KeyRatchet)
    ccall(_sym(:daveDecryptorTransitionToKeyRatchet), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), d.handle, k.handle)
    d.ratchet = k
    nothing
end

transition_to_passthrough!(d::Decryptor, on::Bool) =
    ccall(_sym(:daveDecryptorTransitionToPassthroughMode), Cvoid, (Ptr{Cvoid}, Bool), d.handle, on)

"""
    decrypt(d, frame) -> (code, bytes)

Decrypt one DAVE audio frame. `code` is libdave's result code (0 on success).
"""
function decrypt(d::Decryptor, frame::Vector{UInt8})
    cap = ccall(_sym(:daveDecryptorGetMaxPlaintextByteSize), Csize_t,
                (Ptr{Cvoid}, Cint, Csize_t), d.handle, MEDIA_AUDIO, length(frame))
    out = Vector{UInt8}(undef, cap)
    written = Ref{Csize_t}(0)
    code = ccall(_sym(:daveDecryptorDecrypt), Cint,
                 (Ptr{Cvoid}, Cint, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t, Ptr{Csize_t}),
                 d.handle, MEDIA_AUDIO, frame, length(frame), out, cap, written)
    resize!(out, code == DECRYPT_SUCCESS ? written[] : 0)
    return code, out
end

end # module LibDave
