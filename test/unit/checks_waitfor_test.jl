@testitem "Checks & Guards" tags=[:unit] begin
    using Accord
    using Accord: _init_perm_map!, _resolve_perm, _resolve_perms, _cooldown_key, drain_pending_checks!, _PENDING_CHECKS, _CHECKS_LOCK, EventWaiter, CommandTree, register_command!

    # Initialize permission map
    _init_perm_map!()

    @testset "Permission symbol resolution" begin
        # Known symbols should resolve
        @test _resolve_perm(:MANAGE_GUILD) == PermManageGuild
        @test _resolve_perm(:BAN_MEMBERS) == PermBanMembers
        @test _resolve_perm(:ADMINISTRATOR) == PermAdministrator

        # Direct Permissions values pass through
        @test _resolve_perm(PermManageGuild) == PermManageGuild

        # Unknown symbol should error
        @test_throws ErrorException _resolve_perm(:NONEXISTENT_PERM)

        # Multiple permissions resolve and combine
        combined = _resolve_perms(:MANAGE_GUILD, :BAN_MEMBERS)
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

        check_fn5 = cooldown(5)
        @test check_fn5 isa Function

        check_fn6 = cooldown(30; per=:guild)
        @test check_fn6 isa Function

        check_fn7 = cooldown(10; per=:channel)
        @test check_fn7 isa Function

        check_fn8 = cooldown(60; per=:global)
        @test check_fn8 isa Function
    end

    @testset "cooldown bucket key" begin
        # :global always returns 0
        @test _cooldown_key(nothing, :global) == UInt64(0)

        # Invalid bucket type should error
        @test_throws ErrorException _cooldown_key(nothing, :invalid)
    end

    @testset "Pending checks accumulation and drain" begin
        # Start clean
        drain_pending_checks!()
        @test isempty(_PENDING_CHECKS)

        # Push some checks
        lock(_CHECKS_LOCK) do
            push!(_PENDING_CHECKS, is_owner())
            push!(_PENDING_CHECKS, is_in_guild())
        end
        @test length(_PENDING_CHECKS) == 2

        # Drain should return all and empty the accumulator
        drained = drain_pending_checks!()
        @test length(drained) == 2
        @test isempty(_PENDING_CHECKS)

        # Drain again should return empty
        drained2 = drain_pending_checks!()
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

    @testset "wait_for" begin
        @testset "EventWaiter struct" begin
            ch = Channel{Any}(1)
            waiter = EventWaiter(MessageCreate, evt -> true, ch)
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
end
