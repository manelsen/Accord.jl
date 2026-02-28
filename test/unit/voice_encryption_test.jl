@testitem "Voice encryption (libsodium)" tags=[:unit] begin
    using Accord
    import Accord: xsalsa20_poly1305_encrypt, xsalsa20_poly1305_decrypt,
                   aead_xchacha20_poly1305_encrypt, aead_xchacha20_poly1305_decrypt,
                   random_nonce, select_encryption_mode, ENCRYPTION_MODES,
                   CRYPTO_SECRETBOX_KEYBYTES, CRYPTO_SECRETBOX_NONCEBYTES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES,
                   CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES

    @testset "xsalsa20_poly1305 encrypt/decrypt" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("Hello, Discord voice!")

        encrypted = xsalsa20_poly1305_encrypt(key, nonce, plaintext)
        @test length(encrypted) == length(plaintext) + 16  # 16 bytes MAC
        @test encrypted != plaintext

        decrypted = xsalsa20_poly1305_decrypt(key, nonce, encrypted)
        @test decrypted == plaintext
    end

    @testset "xsalsa20_poly1305 different nonces" begin
        key = zeros(UInt8, 32)
        plaintext = Vector{UInt8}("Same message")

        nonce1 = zeros(UInt8, 24)
        nonce1[1] = 0x01
        nonce2 = zeros(UInt8, 24)
        nonce2[1] = 0x02

        encrypted1 = xsalsa20_poly1305_encrypt(key, nonce1, plaintext)
        encrypted2 = xsalsa20_poly1305_encrypt(key, nonce2, plaintext)

        @test encrypted1 != encrypted2

        decrypted1 = xsalsa20_poly1305_decrypt(key, nonce1, encrypted1)
        decrypted2 = xsalsa20_poly1305_decrypt(key, nonce2, encrypted2)
        @test decrypted1 == plaintext
        @test decrypted2 == plaintext
    end

    @testset "xsalsa20_poly1305 wrong nonce fails" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("Secret message")

        encrypted = xsalsa20_poly1305_encrypt(key, nonce, plaintext)

        wrong_nonce = zeros(UInt8, 24)
        wrong_nonce[1] = 0xFF

        @test_throws ErrorException xsalsa20_poly1305_decrypt(key, wrong_nonce, encrypted)
    end

    @testset "xsalsa20_poly1305 wrong key fails" begin
        key1 = zeros(UInt8, 32)
        key2 = ones(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("Secret message")

        encrypted = xsalsa20_poly1305_encrypt(key1, nonce, plaintext)
        @test_throws ErrorException xsalsa20_poly1305_decrypt(key2, nonce, encrypted)
    end

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
        aad1 = Vector{UInt8}("Correct AAD")
        aad2 = Vector{UInt8}("Wrong AAD")

        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, aad1)
        @test_throws ErrorException aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, aad2)
    end

    @testset "random_nonce" begin
        nonce1 = random_nonce(24)
        nonce2 = random_nonce(24)

        @test length(nonce1) == 24
        @test length(nonce2) == 24
        @test nonce1 != nonce2  # Very unlikely to collide
        @test all(x -> x in UInt8(0):UInt8(255), nonce1)
    end

    @testset "random_nonce custom length" begin
        nonce = random_nonce(16)
        @test length(nonce) == 16
    end

    @testset "select_encryption_mode" begin
        server_modes = ["aead_xchacha20_poly1305_rtpsize", "xsalsa20_poly1305_lite", "xsalsa20_poly1305_suffix", "xsalsa20_poly1305"]

        mode = select_encryption_mode(server_modes)
        @test mode == "aead_xchacha20_poly1305_rtpsize"  # Prefers AEAD
    end

    @testset "select_encryption_mode fallback" begin
        server_modes = ["xsalsa20_poly1305_suffix", "xsalsa20_poly1305"]

        mode = select_encryption_mode(server_modes)
        @test mode == "xsalsa20_poly1305_suffix"  # Second preference
    end

    @testset "select_encryption_mode last resort" begin
        server_modes = ["xsalsa20_poly1305"]

        mode = select_encryption_mode(server_modes)
        @test mode == "xsalsa20_poly1305"
    end

    @testset "select_encryption_mode no supported modes" begin
        server_modes = ["unknown_mode", "another_unknown"]

        @test_throws ErrorException select_encryption_mode(server_modes)
    end

    @testset "encrypt empty data" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = UInt8[]

        encrypted = xsalsa20_poly1305_encrypt(key, nonce, plaintext)
        @test length(encrypted) == 16  # Only MAC

        decrypted = xsalsa20_poly1305_decrypt(key, nonce, encrypted)
        @test decrypted == plaintext
    end

    @testset "encrypt large data" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = rand(UInt8, 100000)  # 100KB

        encrypted = xsalsa20_poly1305_encrypt(key, nonce, plaintext)
        @test length(encrypted) == length(plaintext) + 16

        decrypted = xsalsa20_poly1305_decrypt(key, nonce, encrypted)
        @test decrypted == plaintext
    end

    @testset "aead empty AAD" begin
        key = zeros(UInt8, 32)
        nonce = zeros(UInt8, 24)
        plaintext = Vector{UInt8}("Data with empty AAD")
        aad = UInt8[]

        encrypted = aead_xchacha20_poly1305_encrypt(key, nonce, plaintext, aad)
        decrypted = aead_xchacha20_poly1305_decrypt(key, nonce, encrypted, aad)
        @test decrypted == plaintext
    end

    @testset "key and nonce length validation" begin
        key = zeros(UInt8, 32)
        wrong_key = zeros(UInt8, 16)
        nonce = zeros(UInt8, 24)
        wrong_nonce = zeros(UInt8, 16)
        plaintext = Vector{UInt8}("test")

        @test_throws AssertionError xsalsa20_poly1305_encrypt(wrong_key, nonce, plaintext)
        @test_throws AssertionError xsalsa20_poly1305_encrypt(key, wrong_nonce, plaintext)
    end

    @testset "AEAD key and nonce length validation" begin
        key = zeros(UInt8, 32)
        wrong_key = zeros(UInt8, 16)
        nonce = zeros(UInt8, 24)
        wrong_nonce = zeros(UInt8, 16)
        plaintext = Vector{UInt8}("test")
        aad = UInt8[]

        @test_throws AssertionError aead_xchacha20_poly1305_encrypt(wrong_key, nonce, plaintext, aad)
        @test_throws AssertionError aead_xchacha20_poly1305_encrypt(key, wrong_nonce, plaintext, aad)
    end
end
