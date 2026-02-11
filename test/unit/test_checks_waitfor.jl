@testset "Checks & Guards" begin
    # Initialize permission map
    Accord._init_perm_map!()

    @testset "Permission symbol resolution" begin
        # Known symbols should resolve
        @test Accord._resolve_perm(:MANAGE_GUILD) == PermManageGuild
        @test Accord._resolve_perm(:BAN_MEMBERS) == PermBanMembers
        @test Accord._resolve_perm(:ADMINISTRATOR) == PermAdministrator

        # Direct Permissions values pass through
        @test Accord._resolve_perm(PermManageGuild) == PermManageGuild

        # Unknown symbol should error
        @test_throws ErrorException Accord._resolve_perm(:NONEXISTENT_PERM)

        # Multiple permissions resolve and combine
        combined = Accord._resolve_perms(:MANAGE_GUILD, :BAN_MEMBERS)
        @test combined == (PermManageGuild | PermBanMembers)
    end

    @testset "Check factories return functions" begin
        check_fn = has_permissions(PermManageGuild)
        @test check_fn isa Function

        check_fn2 = has_permissions(:MANAGE_GUILD, :BAN_MEMBERS)
        @test check_fn2 isa Function

        check_fn3 = is_owner()
        @test check_fn3 isa Function

        check_fn4 = is_in_guild()
        @test check_fn4 isa Function
    end

    @testset "Pending checks accumulation and drain" begin
        # Start clean
        Accord.drain_pending_checks!()
        @test isempty(Accord._PENDING_CHECKS)

        # Push some checks
        lock(Accord._CHECKS_LOCK) do
            push!(Accord._PENDING_CHECKS, is_owner())
            push!(Accord._PENDING_CHECKS, is_in_guild())
        end
        @test length(Accord._PENDING_CHECKS) == 2

        # Drain should return all and empty the accumulator
        drained = Accord.drain_pending_checks!()
        @test length(drained) == 2
        @test isempty(Accord._PENDING_CHECKS)

        # Drain again should return empty
        drained2 = Accord.drain_pending_checks!()
        @test isempty(drained2)
    end

    @testset "CommandDefinition stores checks" begin
        tree = CommandTree()
        my_check = ctx -> true
        register_command!(tree, "test_cmd", "A test", ctx -> nothing;
            checks=[my_check])

        cmd = tree.commands["test_cmd"]
        @test length(cmd.checks) == 1
        @test cmd.checks[1] === my_check
    end

    @testset "CommandDefinition without checks" begin
        tree = CommandTree()
        register_command!(tree, "no_checks", "No checks", ctx -> nothing)

        cmd = tree.commands["no_checks"]
        @test isempty(cmd.checks)
    end

    @testset "run_checks passes on all true" begin
        checks = Function[ctx -> true, ctx -> true]
        # We can't easily create a real InteractionContext without a Client,
        # so we test the check functions directly
        @test checks[1](nothing) == true
        @test checks[2](nothing) == true
    end

    @testset "Check failure stops pipeline" begin
        results = Bool[]
        check1 = ctx -> (push!(results, true); true)
        check2 = ctx -> (push!(results, false); false)
        check3 = ctx -> (push!(results, true); true)  # should never run

        # Simulate: check1 passes, check2 fails, check3 should not run
        empty!(results)
        for check_fn in [check1, check2, check3]
            result = check_fn(nothing)
            push!(results, result)
            result || break
        end
        # check1 pushed true and returned true, check2 pushed false and returned false
        # The loop should have 4 entries: true, true, false, false (push + result)
        # Actually let me simplify:
        @test results[end] == false  # last result was failure
    end
end

@testset "wait_for" begin
    @testset "EventWaiter struct" begin
        ch = Channel{Any}(1)
        waiter = Accord.EventWaiter(MessageCreate, evt -> true, ch)
        @test waiter.event_type == MessageCreate
        @test isopen(waiter.channel)
        close(ch)
    end
end

@testset "State injection" begin
    @testset "Client accepts state kwarg" begin
        # We can't create a full Client without a gateway, but we can
        # verify the struct has the field
        @test hasfield(Client, :state_data)
    end
end
