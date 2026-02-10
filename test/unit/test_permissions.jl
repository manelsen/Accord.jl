@testset "Permissions" begin
    @testset "compute_base_permissions" begin
        # Create test roles
        everyone_role = Role(
            id=Snowflake(100), name="@everyone", color=0, hoist=false,
            position=0, permissions="1024", managed=false, mentionable=false, flags=0
        )  # VIEW_CHANNEL only

        admin_role = Role(
            id=Snowflake(200), name="Admin", color=0, hoist=false,
            position=1, permissions="8", managed=false, mentionable=false, flags=0
        )  # ADMINISTRATOR

        mod_role = Role(
            id=Snowflake(300), name="Mod", color=0, hoist=false,
            position=1, permissions="$(1 << 13)", managed=false, mentionable=false, flags=0
        )  # MANAGE_MESSAGES

        roles = [everyone_role, admin_role, mod_role]

        # Regular member with no extra roles
        base = compute_base_permissions(Snowflake[], roles, Snowflake(1), Snowflake(50))
        @test has_flag(base, PermViewChannel)
        @test !has_flag(base, PermAdministrator)

        # Admin member
        admin_perms = compute_base_permissions([Snowflake(200)], roles, Snowflake(1), Snowflake(50))
        @test admin_perms.value == typemax(UInt64)  # Administrator grants all

        # Guild owner
        owner_perms = compute_base_permissions(Snowflake[], roles, Snowflake(50), Snowflake(50))
        @test owner_perms.value == typemax(UInt64)  # Owner has all
    end

    @testset "Permission flag combinations" begin
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
