@testitem "Voice encryption (libsodium)" tags=[:unit] begin
    using Accord
    import Accord: aead_xchacha20_poly1305_encrypt, aead_xchacha20_poly1305_decrypt,
                   aead_aes256gcm_encrypt, aead_aes256gcm_decrypt, aes256gcm_available,
                   encrypt_rtpsize, decrypt_rtpsize, rtpsize_nonce, rtp_header,
                   random_nonce, select_encryption_mode, ENCRYPTION_MODES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES

    @testset "aead_xchacha20_poly1305 encrypt/decrypt" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("AEAD protected voice data")
        aad = Vector{UInt8}("RTP header as AAD")

        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, aad)
        @test length(encrypted) == length(plaintext) + 16  # 16 bytes auth tag
        @test encrypted != plaintext

        decrypted = aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, aad)
        @test decrypted == plaintext
    end

    @testset "aead_xchacha20_poly1305 wrong AAD fails" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("Protected message")

        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, Vector{UInt8}("Correct AAD"))
        @test_throws ErrorException aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, Vector{UInt8}("Wrong AAD"))
    end

    @testset "aead_xchacha20_poly1305 wrong key fails" begin
        nonce = zeros(UInt8, 24)
        encrypted = aead_xchacha20_poly1305_encrypt(zeros(UInt8, 32), nonce, Vector{UInt8}("x"), UInt8[])
        @test_throws ErrorException aead_xchacha20_poly1305_decrypt(ones(UInt8, 32), nonce, encrypted, UInt8[])
    end

    @testset "aead_aes256gcm encrypt/decrypt (when hardware supports it)" begin
        if aes256gcm_available()
            key = rand(UInt8, 32)
            nonce = zeros(UInt8, 12)
            plaintext = Vector{UInt8}("AES-GCM voice data")
            aad = Vector{UInt8}("header")

            encrypted = aead_aes256gcm_encrypt(key, nonce, plaintext, aad)
            @test length(encrypted) == length(plaintext) + 16
            @test aead_aes256gcm_decrypt(key, nonce, encrypted, aad) == plaintext
            @test_throws ErrorException aead_aes256gcm_decrypt(key, nonce, encrypted, Vector{UInt8}("other"))
        else
            @test_skip "AES-256-GCM not available on this CPU"
        end
    end

    @testset "rtpsize nonce layout" begin
        n = rtpsize_nonce(UInt32(0x01020304), "aead_xchacha20_poly1305_rtpsize")
        @test length(n) == 24
        @test n[1:4] == UInt8[0x01, 0x02, 0x03, 0x04]
        @test all(iszero, n[5:end])

        n = rtpsize_nonce(UInt32(7), "aead_aes256_gcm_rtpsize")
        @test length(n) == 12
        @test n[1:4] == UInt8[0, 0, 0, 7]

        @test_throws ErrorException rtpsize_nonce(UInt32(1), "xsalsa20_poly1305")
    end

    @testset "rtpsize packet round trip" begin
        modes = aes256gcm_available() ? ENCRYPTION_MODES : ["aead_xchacha20_poly1305_rtpsize"]
        for mode in modes
            key = rand(UInt8, 32)
            header = rtp_header(UInt16(10), UInt32(9600), UInt32(42))
            payload = rand(UInt8, 120)

            packet = encrypt_rtpsize(mode, key, UInt32(0xdeadbeef), header, payload)
            @test length(packet) == length(payload) + 16 + 4
            @test packet[end-3:end] == UInt8[0xde, 0xad, 0xbe, 0xef]
            @test decrypt_rtpsize(mode, key, header, packet) == payload

            # The header is authenticated: tampering with it must fail
            bad_header = copy(header); bad_header[2] ⊻= 0x01
            @test_throws ErrorException decrypt_rtpsize(mode, key, bad_header, packet)
        end
    end

    @testset "random_nonce" begin
        nonce1 = random_nonce(24)
        nonce2 = random_nonce(24)
        @test length(nonce1) == 24
        @test nonce1 != nonce2  # Very unlikely to collide
        @test length(random_nonce(16)) == 16
    end

    @testset "select_encryption_mode" begin
        offered = ["aead_aes256_gcm_rtpsize", "aead_xchacha20_poly1305_rtpsize", "xsalsa20_poly1305"]
        @test select_encryption_mode(offered; aes_available=true) == "aead_aes256_gcm_rtpsize"
        @test select_encryption_mode(offered; aes_available=false) == "aead_xchacha20_poly1305_rtpsize"
        @test select_encryption_mode(["aead_xchacha20_poly1305_rtpsize"]; aes_available=true) ==
              "aead_xchacha20_poly1305_rtpsize"
    end

    @testset "select_encryption_mode rejects discontinued modes" begin
        @test_throws ErrorException select_encryption_mode(["xsalsa20_poly1305_lite", "xsalsa20_poly1305"])
        @test_throws ErrorException select_encryption_mode(["unknown_mode"])
    end

    @testset "aead empty AAD and empty payload" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, UInt8[], UInt8[])
        @test length(encrypted) == 16
        @test aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, UInt8[]) == UInt8[]
    end

    @testset "encrypt large data" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = rand(UInt8, 100000)  # 100KB
        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, UInt8[])
        @test aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, UInt8[]) == plaintext
    end

    @testset "AEAD key and nonce length validation" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("test")
        @test_throws AssertionError aead_xchacha20_poly1305_encrypt(zeros(UInt8, 16), nonce, plaintext, UInt8[])
        @test_throws AssertionError aead_xchacha20_poly1305_encrypt(key, zeros(UInt8, 16), plaintext, UInt8[])
        @test_throws AssertionError aead_aes256gcm_encrypt(key, zeros(UInt8, 24), plaintext, UInt8[])
    end
end
