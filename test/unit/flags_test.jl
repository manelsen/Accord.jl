@testitem "Flags" tags=[:unit] begin
    using Accord, JSON3
    using Accord: has_flag

    @testset "Intents" begin
        @test IntentGuilds.value == 1 << 0
        @test IntentGuildMembers.value == 1 << 1
        @test IntentMessageContent.value == 1 << 15

        # Combine intents
        combined = IntentGuilds | IntentGuildMessages
        @test has_flag(combined, IntentGuilds)
        @test has_flag(combined, IntentGuildMessages)
        @test !has_flag(combined, IntentGuildMembers)

        # All non-privileged should not include privileged
        @test !has_flag(IntentAllNonPrivileged, IntentGuildMembers)
        @test !has_flag(IntentAllNonPrivileged, IntentGuildPresences)
        @test !has_flag(IntentAllNonPrivileged, IntentMessageContent)

        # All should include privileged
        @test has_flag(IntentAll, IntentGuildMembers)
        @test has_flag(IntentAll, IntentGuildPresences)
        @test has_flag(IntentAll, IntentMessageContent)
    end

    @testset "Permissions" begin
        @test PermAdministrator.value == 1 << 3
        @test PermSendMessages.value == 1 << 11
        @test PermManageGuild.value == 1 << 5

        combined = PermSendMessages | PermEmbedLinks | PermAttachFiles
        @test has_flag(combined, PermSendMessages)
        @test has_flag(combined, PermEmbedLinks)
        @test has_flag(combined, PermAttachFiles)
        @test !has_flag(combined, PermAdministrator)

        # Permissions use string JSON
        json_str = JSON3.write(PermAdministrator)
        @test json_str == "\"8\""

        p2 = JSON3.read("\"8\"", Permissions)
        @test p2 == PermAdministrator
    end

    @testset "MessageFlags" begin
        @test MsgFlagEphemeral.value == 1 << 6
        @test MsgFlagSuppressEmbeds.value == 1 << 2

        combined = MsgFlagEphemeral | MsgFlagSuppressEmbeds
        @test has_flag(combined, MsgFlagEphemeral)
    end

    @testset "Bitwise operations" begin
        a = IntentGuilds | IntentGuildMessages
        b = IntentGuilds | IntentGuildMembers

        # AND
        c = a & b
        @test has_flag(c, IntentGuilds)
        @test !has_flag(c, IntentGuildMessages)
        @test !has_flag(c, IntentGuildMembers)

        # XOR
        d = xor(a, b)
        @test !has_flag(d, IntentGuilds)
        @test has_flag(d, IntentGuildMessages)
        @test has_flag(d, IntentGuildMembers)

        # Zero
        z = zero(Intents)
        @test iszero(z)
    end
end
