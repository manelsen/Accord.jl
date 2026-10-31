# Voice transport encryption via libsodium
#
# Internal module: Provides the two transport encryption modes Discord still
# accepts — AEAD AES-256-GCM and AEAD XChaCha20-Poly1305, both in their
# "rtpsize" form — using libsodium FFI bindings.
#
# The legacy xsalsa20_poly1305* and non-rtpsize modes were discontinued by
# Discord on 2024-11-18 and are intentionally not implemented.
#
# Note: this is *transport* encryption. Discord voice also requires the DAVE
# end-to-end encryption protocol (mandatory since 2026-03-01), which is
# handled separately.

using libsodium_jll

const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES = 32
const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES = 24
const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES = 16
const CRYPTO_AEAD_AES256GCM_KEYBYTES = 32
const CRYPTO_AEAD_AES256GCM_NPUBBYTES = 12
const CRYPTO_AEAD_AES256GCM_ABYTES = 16

# Size of the incrementing nonce appended to every rtpsize packet.
const RTPSIZE_NONCE_BYTES = 4

"""Available encryption modes in order of preference (Discord prefers AES-GCM)."""
const ENCRYPTION_MODES = [
    "aead_aes256_gcm_rtpsize",
    "aead_xchacha20_poly1305_rtpsize",
]

"""
    aes256gcm_available() -> Bool

Whether libsodium can use AES-256-GCM on this CPU (it needs hardware AES).
"""
aes256gcm_available() =
    ccall((:crypto_aead_aes256gcm_is_available, libsodium_jll.libsodium), Cint, ()) == 1

"""
    select_encryption_mode(server_modes) -> String

Select the best encryption mode offered by the voice server. AES-256-GCM is
skipped when the CPU lacks hardware AES support.
"""
function select_encryption_mode(server_modes::AbstractVector;
                                aes_available::Bool=aes256gcm_available())
    for mode in ENCRYPTION_MODES
        mode == "aead_aes256_gcm_rtpsize" && !aes_available && continue
        if mode in server_modes
            return mode
        end
    end
    error("No supported encryption mode found. Server supports: $(join(server_modes, ", "))")
end

"""
    rtpsize_nonce(counter, mode) -> Vector{UInt8}

Full-length nonce for an rtpsize mode: the 32-bit big-endian `counter`
followed by zeros (12 bytes for AES-GCM, 24 for XChaCha20).
"""
function rtpsize_nonce(counter::UInt32, mode::AbstractString)
    len = mode == "aead_aes256_gcm_rtpsize" ? CRYPTO_AEAD_AES256GCM_NPUBBYTES :
          mode == "aead_xchacha20_poly1305_rtpsize" ? CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES :
          error("Unsupported encryption mode: $mode")
    nonce = zeros(UInt8, len)
    nonce[1] = UInt8((counter >> 24) & 0xFF)
    nonce[2] = UInt8((counter >> 16) & 0xFF)
    nonce[3] = UInt8((counter >> 8) & 0xFF)
    nonce[4] = UInt8(counter & 0xFF)
    return nonce
end

"""
    encrypt_rtpsize(mode, key, counter, header, payload) -> Vector{UInt8}

Encrypt one voice payload for an rtpsize mode. The RTP `header` is the
additional authenticated data, and the 4-byte nonce counter is appended to
the ciphertext, as Discord expects: `ciphertext ‖ tag ‖ nonce[1:4]`.
"""
function encrypt_rtpsize(mode::AbstractString, key::Vector{UInt8}, counter::UInt32,
                         header::Vector{UInt8}, payload::Vector{UInt8})
    nonce = rtpsize_nonce(counter, mode)
    encrypted = if mode == "aead_aes256_gcm_rtpsize"
        aead_aes256gcm_encrypt(key, nonce, payload, header)
    else
        aead_xchacha20_poly1305_encrypt(key, nonce, payload, header)
    end
    return vcat(encrypted, nonce[1:RTPSIZE_NONCE_BYTES])
end

"""
    decrypt_rtpsize(mode, key, header, data) -> Vector{UInt8}

Inverse of [`encrypt_rtpsize`](@ref): strips the trailing 4-byte nonce from
`data`, rebuilds the full nonce and decrypts with `header` as AAD.
"""
function decrypt_rtpsize(mode::AbstractString, key::Vector{UInt8},
                         header::Vector{UInt8}, data::Vector{UInt8})
    length(data) >= RTPSIZE_NONCE_BYTES || error("Voice packet too short")
    tail = data[end-RTPSIZE_NONCE_BYTES+1:end]
    counter = (UInt32(tail[1]) << 24) | (UInt32(tail[2]) << 16) | (UInt32(tail[3]) << 8) | UInt32(tail[4])
    nonce = rtpsize_nonce(counter, mode)
    ciphertext = data[1:end-RTPSIZE_NONCE_BYTES]
    if mode == "aead_aes256_gcm_rtpsize"
        aead_aes256gcm_decrypt(key, nonce, ciphertext, header)
    else
        aead_xchacha20_poly1305_decrypt(key, nonce, ciphertext, header)
    end
end

"""
    aead_aes256gcm_encrypt(key, nonce, plaintext, aad) -> ciphertext

Encrypt using AEAD AES-256-GCM. Requires [`aes256gcm_available`](@ref).
"""
function aead_aes256gcm_encrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, plaintext::Vector{UInt8}, aad::Vector{UInt8})
    @assert length(key) == CRYPTO_AEAD_AES256GCM_KEYBYTES
    @assert length(nonce) == CRYPTO_AEAD_AES256GCM_NPUBBYTES

    ciphertext = Vector{UInt8}(undef, length(plaintext) + CRYPTO_AEAD_AES256GCM_ABYTES)
    clen = Ref{Culonglong}(0)

    ret = ccall((:crypto_aead_aes256gcm_encrypt, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{Culonglong}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Culonglong, Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}),
        ciphertext, clen, plaintext, length(plaintext), aad, length(aad), C_NULL, nonce, key)

    ret == 0 || error("crypto_aead_aes256gcm_encrypt failed: $ret")
    return ciphertext[1:clen[]]
end

"""
    aead_aes256gcm_decrypt(key, nonce, ciphertext, aad) -> plaintext

Decrypt using AEAD AES-256-GCM. Requires [`aes256gcm_available`](@ref).
"""
function aead_aes256gcm_decrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, ciphertext::Vector{UInt8}, aad::Vector{UInt8})
    @assert length(key) == CRYPTO_AEAD_AES256GCM_KEYBYTES
    @assert length(nonce) == CRYPTO_AEAD_AES256GCM_NPUBBYTES
    length(ciphertext) >= CRYPTO_AEAD_AES256GCM_ABYTES || error("crypto_aead_aes256gcm_decrypt failed: ciphertext too short")

    plaintext = Vector{UInt8}(undef, length(ciphertext) - CRYPTO_AEAD_AES256GCM_ABYTES)
    plen = Ref{Culonglong}(0)

    ret = ccall((:crypto_aead_aes256gcm_decrypt, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{Culonglong}, Ptr{Cvoid}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Ptr{UInt8}),
        plaintext, plen, C_NULL, ciphertext, length(ciphertext), aad, length(aad), nonce, key)

    ret == 0 || error("crypto_aead_aes256gcm_decrypt failed: decryption error")
    return plaintext[1:plen[]]
end

"""
    aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, aad) -> ciphertext

Encrypt using AEAD XChaCha20-Poly1305.
"""
function aead_xchacha20_poly1305_encrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, plaintext::Vector{UInt8}, aad::Vector{UInt8})
    @assert length(key) == CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES
    @assert length(nonce) == CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES

    ciphertext = Vector{UInt8}(undef, length(plaintext) + CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES)
    clen = Ref{Culonglong}(0)

    ret = ccall((:crypto_aead_xchacha20poly1305_ietf_encrypt, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{Culonglong}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Culonglong, Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}),
        ciphertext, clen, plaintext, length(plaintext), aad, length(aad), C_NULL, nonce, key)

    ret == 0 || error("crypto_aead_xchacha20poly1305_ietf_encrypt failed: $ret")
    return ciphertext[1:clen[]]
end

"""
    aead_xchacha20_poly1305_decrypt(key, nonce, ciphertext, aad) -> plaintext

Decrypt using AEAD XChaCha20-Poly1305.
"""
function aead_xchacha20_poly1305_decrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, ciphertext::Vector{UInt8}, aad::Vector{UInt8})
    @assert length(key) == CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES
    @assert length(nonce) == CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES
    length(ciphertext) >= CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES || error("crypto_aead_xchacha20poly1305_ietf_decrypt failed: ciphertext too short")

    plaintext = Vector{UInt8}(undef, length(ciphertext) - CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES)
    plen = Ref{Culonglong}(0)

    ret = ccall((:crypto_aead_xchacha20poly1305_ietf_decrypt, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{Culonglong}, Ptr{Cvoid}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Ptr{UInt8}),
        plaintext, plen, C_NULL, ciphertext, length(ciphertext), aad, length(aad), nonce, key)

    ret == 0 || error("crypto_aead_xchacha20poly1305_ietf_decrypt failed: decryption error")
    return plaintext[1:plen[]]
end

"""Generate a random nonce of the specified length."""
function random_nonce(len::Int=CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES)
    nonce = Vector{UInt8}(undef, len)
    ccall((:randombytes_buf, libsodium_jll.libsodium),
        Cvoid, (Ptr{UInt8}, Csize_t), nonce, len)
    return nonce
end

"""Initialize libsodium (must be called once)."""
function init_sodium()
    ret = ccall((:sodium_init, libsodium_jll.libsodium), Cint, ())
    ret >= 0 || error("sodium_init failed")
end
