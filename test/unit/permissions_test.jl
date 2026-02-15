@testitem "Permissions" tags=[:unit] begin
    using Accord
    using Accord: compute_base_permissions, compute_channel_permissions, Overwrite

    # ── Helpers ──────────────────────────────────────────────────────────────────

    "Create a Role with the given permission bits."
    make_role(id, name, perms_val; position=1) = Role(
        id=Snowflake(id), name=name, color=0, hoist=false,
        position=position, permissions=string(perms_val),
        managed=false, mentionable=false, flags=0
    )

    "Create an Overwrite for a role (type=0) or member (type=1)."
    make_overwrite(id; type=0, allow=0, deny=0) = Overwrite(
        id=Snowflake(id), type=type, allow=string(allow), deny=string(deny)
    )

    const GUILD_ID = Snowflake(1)
    const OWNER_ID = Snowflake(999)

    # Standard test roles
    everyone_role() = make_role(1, "@everyone", PermViewChannel.value | PermSendMessages.value; position=0)
    admin_role()    = make_role(200, "Admin", PermAdministrator.value)
    mod_role()      = make_role(300, "Mod", PermManageMessages.value | PermKickMembers.value)
    dj_role()       = make_role(400, "DJ", PermConnect.value | PermSpeak.value)

    # ── compute_base_permissions ─────────────────────────────────────────────────

    @testset "Base — @everyone only" begin
        roles = [everyone_role()]
        perms = compute_base_permissions(Snowflake[], roles, OWNER_ID, Snowflake(50))
        @test has_flag(perms, PermViewChannel)
        @test has_flag(perms, PermSendMessages)
        @test !has_flag(perms, PermManageMessages)
        @test !has_flag(perms, PermAdministrator)
    end

    @testset "Base — role permissions OR'd" begin
        roles = [everyone_role(), mod_role(), dj_role()]
        member_roles = [Snowflake(300), Snowflake(400)]
        perms = compute_base_permissions(member_roles, roles, OWNER_ID, Snowflake(50))

        # @everyone perms
        @test has_flag(perms, PermViewChannel)
        @test has_flag(perms, PermSendMessages)
        # Mod perms
        @test has_flag(perms, PermManageMessages)
        @test has_flag(perms, PermKickMembers)
        # DJ perms
        @test has_flag(perms, PermConnect)
        @test has_flag(perms, PermSpeak)
        # Not granted
        @test !has_flag(perms, PermBanMembers)
        @test !has_flag(perms, PermAdministrator)
    end

    @testset "Base — Administrator grants all" begin
        roles = [everyone_role(), admin_role()]
        perms = compute_base_permissions([Snowflake(200)], roles, OWNER_ID, Snowflake(50))
        @test perms.value == typemax(UInt64)
    end

    @testset "Base — Guild owner gets all" begin
        roles = [everyone_role()]
        perms = compute_base_permissions(Snowflake[], roles, OWNER_ID, OWNER_ID)
        @test perms.value == typemax(UInt64)
    end

    @testset "Base — unknown role ID ignored" begin
        roles = [everyone_role()]
        perms = compute_base_permissions([Snowflake(9999)], roles, OWNER_ID, Snowflake(50))
        # Should still have @everyone perms, unknown role silently skipped
        @test has_flag(perms, PermViewChannel)
        @test !has_flag(perms, PermAdministrator)
    end

    # ── compute_channel_permissions ──────────────────────────────────────────────

    @testset "Channel — no overwrites returns base" begin
        base = PermViewChannel | PermSendMessages
        perms = compute_channel_permissions(base, Snowflake[], Overwrite[], GUILD_ID, Snowflake(50))
        @test perms == base
    end

    @testset "Channel — @everyone overwrite deny" begin
        base = PermViewChannel | PermSendMessages
        overwrites = [make_overwrite(1; deny=PermSendMessages.value)]  # deny SendMessages for @everyone
        perms = compute_channel_permissions(base, Snowflake[], overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermViewChannel)
        @test !has_flag(perms, PermSendMessages)  # Denied by @everyone overwrite
    end

    @testset "Channel — @everyone overwrite allow adds permission" begin
        base = PermViewChannel  # Only VIEW_CHANNEL in base
        overwrites = [make_overwrite(1; allow=PermEmbedLinks.value)]
        perms = compute_channel_permissions(base, Snowflake[], overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermViewChannel)
        @test has_flag(perms, PermEmbedLinks)  # Added by @everyone overwrite
    end

    @testset "Channel — role overwrite overrides @everyone deny" begin
        base = PermViewChannel | PermSendMessages
        overwrites = [
            make_overwrite(1; deny=PermSendMessages.value),        # @everyone: deny SendMessages
            make_overwrite(300; type=0, allow=PermSendMessages.value),  # Mod role: allow SendMessages
        ]
        member_roles = [Snowflake(300)]
        perms = compute_channel_permissions(base, member_roles, overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermSendMessages)  # Role allow overrides @everyone deny
    end

    @testset "Channel — role overwrite deny" begin
        base = PermViewChannel | PermSendMessages | PermEmbedLinks
        overwrites = [
            make_overwrite(300; type=0, deny=PermEmbedLinks.value),  # Mod role: deny EmbedLinks
        ]
        member_roles = [Snowflake(300)]
        perms = compute_channel_permissions(base, member_roles, overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermSendMessages)
        @test !has_flag(perms, PermEmbedLinks)  # Denied by role overwrite
    end

    @testset "Channel — multiple role overwrites combined" begin
        base = PermViewChannel
        overwrites = [
            make_overwrite(300; type=0, allow=PermSendMessages.value),  # Mod: allow Send
            make_overwrite(400; type=0, allow=PermEmbedLinks.value),    # DJ: allow Embed
        ]
        member_roles = [Snowflake(300), Snowflake(400)]
        perms = compute_channel_permissions(base, member_roles, overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermSendMessages)
        @test has_flag(perms, PermEmbedLinks)
    end

    @testset "Channel — member overwrite highest priority" begin
        base = PermViewChannel | PermSendMessages
        overwrites = [
            make_overwrite(1; deny=PermSendMessages.value),          # @everyone: deny Send
            make_overwrite(300; type=0, deny=PermSendMessages.value), # Mod role: also deny Send
            make_overwrite(50; type=1, allow=PermSendMessages.value), # Member: allow Send
        ]
        member_roles = [Snowflake(300)]
        perms = compute_channel_permissions(base, member_roles, overwrites, GUILD_ID, Snowflake(50))

        @test has_flag(perms, PermSendMessages)  # Member overwrite wins
    end

    @testset "Channel — member overwrite deny overrides role allow" begin
        base = PermViewChannel | PermSendMessages
        overwrites = [
            make_overwrite(300; type=0, allow=PermSendMessages.value),  # Role: allow
            make_overwrite(50; type=1, deny=PermSendMessages.value),    # Member: deny
        ]
        member_roles = [Snowflake(300)]
        perms = compute_channel_permissions(base, member_roles, overwrites, GUILD_ID, Snowflake(50))

        @test !has_flag(perms, PermSendMessages)  # Member deny wins over role allow
    end

    @testset "Channel — Administrator bypasses all overwrites" begin
        base = Permissions(typemax(UInt64))  # Admin has all perms
        overwrites = [
            make_overwrite(1; deny=PermSendMessages.value),          # @everyone deny
            make_overwrite(50; type=1, deny=PermViewChannel.value),  # Member deny
        ]
        perms = compute_channel_permissions(base, Snowflake[], overwrites, GUILD_ID, Snowflake(50))

        @test perms.value == typemax(UInt64)  # Admin ignores all overwrites
    end

    @testset "Channel — complex scenario (read-only announcements channel)" begin
        # Scenario: #announcements channel where only mods can send
        base = PermViewChannel | PermSendMessages | PermReadMessageHistory
        overwrites = [
            make_overwrite(1; deny=PermSendMessages.value),             # @everyone: deny Send
            make_overwrite(300; type=0, allow=PermSendMessages.value),  # Mod: allow Send
        ]

        # Regular user
        regular_perms = compute_channel_permissions(base, Snowflake[], overwrites, GUILD_ID, Snowflake(50))
        @test has_flag(regular_perms, PermViewChannel)
        @test has_flag(regular_perms, PermReadMessageHistory)
        @test !has_flag(regular_perms, PermSendMessages)

        # Mod
        mod_perms = compute_channel_permissions(base, [Snowflake(300)], overwrites, GUILD_ID, Snowflake(60))
        @test has_flag(mod_perms, PermViewChannel)
        @test has_flag(mod_perms, PermSendMessages)
    end

    # ── Permission flag operations ───────────────────────────────────────────────

    @testset "Flag combinations" begin
        p = PermSendMessages | PermEmbedLinks | PermAttachFiles
        @test has_flag(p, PermSendMessages)
        @test has_flag(p, PermEmbedLinks)
        @test has_flag(p, PermAttachFiles)
        @test !has_flag(p, PermManageMessages)

        # Remove a permission
        p2 = Permissions(p.value & ~PermEmbedLinks.value)
        @test has_flag(p2, PermSendMessages)
        @test !has_flag(p2, PermEmbedLinks)
        @test has_flag(p2, PermAttachFiles)
    end
end
