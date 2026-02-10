# Voice encryption via libsodium

using libsodium_jll

const CRYPTO_SECRETBOX_KEYBYTES = 32
const CRYPTO_SECRETBOX_NONCEBYTES = 24
const CRYPTO_SECRETBOX_MACBYTES = 16
const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES = 32
const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES = 24
const CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES = 16

"""Available encryption modes in order of preference."""
const ENCRYPTION_MODES = [
    "aead_xchacha20_poly1305_rtpsize",
    "xsalsa20_poly1305_lite",
    "xsalsa20_poly1305_suffix",
    "xsalsa20_poly1305",
]

"""Select the best encryption mode from the server's supported modes."""
function select_encryption_mode(server_modes::Vector{String})
    for mode in ENCRYPTION_MODES
        if mode in server_modes
            return mode
        end
    end
    error("No supported encryption mode found. Server supports: $(join(server_modes, ", "))")
end

"""
    xsalsa20_poly1305_encrypt(key, nonce, plaintext) -> ciphertext

Encrypt using xsalsa20_poly1305 (crypto_secretbox).
"""
function xsalsa20_poly1305_encrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, plaintext::Vector{UInt8})
    @assert length(key) == CRYPTO_SECRETBOX_KEYBYTES
    @assert length(nonce) == CRYPTO_SECRETBOX_NONCEBYTES

    ciphertext = Vector{UInt8}(undef, length(plaintext) + CRYPTO_SECRETBOX_MACBYTES)

    ret = ccall((:crypto_secretbox_easy, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Ptr{UInt8}),
        ciphertext, plaintext, length(plaintext), nonce, key)

    ret == 0 || error("crypto_secretbox_easy failed: $ret")
    return ciphertext
end

"""
    xsalsa20_poly1305_decrypt(key, nonce, ciphertext) -> plaintext

Decrypt using xsalsa20_poly1305 (crypto_secretbox).
"""
function xsalsa20_poly1305_decrypt(key::Vector{UInt8}, nonce::Vector{UInt8}, ciphertext::Vector{UInt8})
    @assert length(key) == CRYPTO_SECRETBOX_KEYBYTES
    @assert length(nonce) == CRYPTO_SECRETBOX_NONCEBYTES

    plaintext = Vector{UInt8}(undef, length(ciphertext) - CRYPTO_SECRETBOX_MACBYTES)

    ret = ccall((:crypto_secretbox_open_easy, libsodium_jll.libsodium),
        Cint,
        (Ptr{UInt8}, Ptr{UInt8}, Culonglong, Ptr{UInt8}, Ptr{UInt8}),
        plaintext, ciphertext, length(ciphertext), nonce, key)

    ret == 0 || error("crypto_secretbox_open_easy failed: decryption error")
    return plaintext
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
function random_nonce(len::Int=CRYPTO_SECRETBOX_NONCEBYTES)
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
