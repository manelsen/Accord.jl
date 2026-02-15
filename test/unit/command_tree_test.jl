@testitem "CommandTree" tags=[:unit] begin
    using Accord, Logging, HTTP
    using Accord: CommandTree, CommandDefinition, register_command!, register_component!,
        register_modal!, register_autocomplete!, dispatch_interaction!, sync_commands!,
        InteractionContext, get_options, get_option, custom_id, selected_values, modal_values,
        target, respond, defer, edit_response, followup, show_modal,
        run_checks, drain_pending_checks!, _PENDING_CHECKS, _CHECKS_LOCK,
        has_permissions, is_owner, is_in_guild, cooldown,
        InteractionDataOption, ResolvedData, CheckFailedError,
        compute_base_permissions, has_flag, _cooldown_key, _is_present,
        Store, State, RateLimiter, start_ratelimiter!, stop_ratelimiter!

    # ── Helpers ──────────────────────────────────────────────────────────────────

    """Create a minimal mock Client (no gateway connection needed)."""
    function mock_client(; state_data=nothing, application_id=nothing)
        c = Client("Bot test_token_fake"; state=state_data)
        c.application_id = application_id
        # Set up a mock request handler so no real HTTP happens
        c.ratelimiter.request_handler = (m, u, h, b) -> HTTP.Response(200, "{}")
        return c
    end

    """Create an Interaction for an APPLICATION_COMMAND (slash command)."""
    function slash_interaction(; name="test", options=missing, guild_id=missing,
                                member=missing, user=missing, target_id=missing,
                                resolved=missing, cmd_type=missing)
        data = InteractionData(
            name=name,
            type=cmd_type,
            options=options,
            custom_id=missing,
            values=missing,
            components=missing,
            target_id=target_id,
            resolved=resolved,
        )
        Interaction(
            id=Snowflake(1),
            application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND,
            data=data,
            guild_id=guild_id,
            channel_id=Snowflake(200),
            member=member,
            user=user,
            token="interaction_token",
            version=1,
        )
    end

    """Create an Interaction for a MESSAGE_COMPONENT."""
    function component_interaction(; custom_id_val="btn_click", values=missing,
                                    guild_id=missing, member=missing, user=missing)
        data = InteractionData(
            custom_id=custom_id_val,
            values=values,
            components=missing,
        )
        Interaction(
            id=Snowflake(2),
            application_id=Snowflake(100),
            type=InteractionTypes.MESSAGE_COMPONENT,
            data=data,
            guild_id=guild_id,
            channel_id=Snowflake(200),
            member=member,
            user=user,
            token="interaction_token",
            version=1,
        )
    end

    """Create an Interaction for APPLICATION_COMMAND_AUTOCOMPLETE."""
    function autocomplete_interaction(; name="test", options=missing)
        data = InteractionData(name=name, options=options)
        Interaction(
            id=Snowflake(3),
            application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND_AUTOCOMPLETE,
            data=data,
            token="interaction_token",
            version=1,
        )
    end

    """Create an Interaction for MODAL_SUBMIT."""
    function modal_interaction(; custom_id_val="my_modal", components=missing)
        data = InteractionData(custom_id=custom_id_val, components=components)
        Interaction(
            id=Snowflake(4),
            application_id=Snowflake(100),
            type=InteractionTypes.MODAL_SUBMIT,
            data=data,
            token="interaction_token",
            version=1,
        )
    end

    """Create a minimal User."""
    function mock_user(; id=Snowflake(999))
        User(id=id, username="testuser", discriminator="0001")
    end

    """Create a minimal Member with a user."""
    function mock_member(; user_id=Snowflake(999), roles=Snowflake[])
        Member(user=mock_user(id=user_id), roles=roles)
    end

    # ── CommandTree Constructor ──────────────────────────────────────────────────

    @testset "Constructor" begin
        tree = CommandTree()
        @test isempty(tree.commands)
        @test isempty(tree.component_handlers)
        @test isempty(tree.modal_handlers)
        @test isempty(tree.autocomplete_handlers)
    end

    # ── Registration ─────────────────────────────────────────────────────────────

    @testset "register_command!" begin
        tree = CommandTree()
        handler = ctx -> nothing

        register_command!(tree, "ping", "Pong!", handler)
        @test haskey(tree.commands, "ping")
        cmd = tree.commands["ping"]
        @test cmd.name == "ping"
        @test cmd.description == "Pong!"
        @test cmd.type == ApplicationCommandTypes.CHAT_INPUT
        @test isempty(cmd.options)
        @test ismissing(cmd.guild_id)
        @test isempty(cmd.checks)
        @test cmd.handler === handler
    end

    @testset "register_command! with options" begin
        tree = CommandTree()
        opts = [Dict{String,Any}("name" => "count", "type" => 4, "description" => "Number")]
        register_command!(tree, "roll", "Roll dice", ctx -> nothing;
            options=opts, guild_id=Snowflake(555))
        cmd = tree.commands["roll"]
        @test length(cmd.options) == 1
        @test cmd.guild_id == Snowflake(555)
    end

    @testset "register_command! with checks" begin
        tree = CommandTree()
        check1 = ctx -> true
        check2 = ctx -> false
        register_command!(tree, "admin", "Admin cmd", ctx -> nothing;
            checks=[check1, check2])
        cmd = tree.commands["admin"]
        @test length(cmd.checks) == 2
    end

    @testset "register_command! with USER type" begin
        tree = CommandTree()
        register_command!(tree, "User Info", "", ctx -> nothing;
            type=ApplicationCommandTypes.USER)
        cmd = tree.commands["User Info"]
        @test cmd.type == ApplicationCommandTypes.USER
    end

    @testset "register_component!" begin
        tree = CommandTree()
        handler = ctx -> nothing
        register_component!(tree, "btn_confirm", handler)
        @test haskey(tree.component_handlers, "btn_confirm")
        @test tree.component_handlers["btn_confirm"] === handler
    end

    @testset "register_modal!" begin
        tree = CommandTree()
        handler = ctx -> nothing
        register_modal!(tree, "feedback_modal", handler)
        @test haskey(tree.modal_handlers, "feedback_modal")
        @test tree.modal_handlers["feedback_modal"] === handler
    end

    @testset "register_autocomplete!" begin
        tree = CommandTree()
        handler = ctx -> nothing
        register_autocomplete!(tree, "search", handler)
        @test haskey(tree.autocomplete_handlers, "search")
        @test tree.autocomplete_handlers["search"] === handler
    end

    @testset "overwrite registration" begin
        tree = CommandTree()
        h1 = ctx -> "first"
        h2 = ctx -> "second"
        register_command!(tree, "test", "v1", h1)
        register_command!(tree, "test", "v2", h2)
        @test tree.commands["test"].handler === h2
        @test tree.commands["test"].description == "v2"
    end

    # ── Dispatch: APPLICATION_COMMAND ────────────────────────────────────────────

    @testset "dispatch APPLICATION_COMMAND" begin
        tree = CommandTree()
        called = Ref(false)
        register_command!(tree, "greet", "Say hi", ctx -> (called[] = true))

        client = mock_client()
        interaction = slash_interaction(name="greet")
        dispatch_interaction!(tree, client, interaction)
        @test called[]
    end

    @testset "dispatch APPLICATION_COMMAND unknown command" begin
        tree = CommandTree()
        client = mock_client()
        interaction = slash_interaction(name="nonexistent")
        # Should not error, just warn
        with_logger(NullLogger()) do
            dispatch_interaction!(tree, client, interaction)
        end
        @test true  # no error thrown
    end

    @testset "dispatch APPLICATION_COMMAND missing data" begin
        tree = CommandTree()
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1),
            application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND,
            data=missing,
            token="tok",
            version=1,
        )
        dispatch_interaction!(tree, client, interaction)
        @test true  # no error
    end

    @testset "dispatch APPLICATION_COMMAND handler error caught" begin
        tree = CommandTree()
        register_command!(tree, "crash", "Crash", ctx -> error("boom"))

        client = mock_client()
        interaction = slash_interaction(name="crash")
        # Should not throw — error is caught and logged
        with_logger(NullLogger()) do
            dispatch_interaction!(tree, client, interaction)
        end
        @test true
    end

    @testset "dispatch APPLICATION_COMMAND with checks passing" begin
        tree = CommandTree()
        called = Ref(false)
        register_command!(tree, "ok", "Ok", ctx -> (called[] = true);
            checks=[ctx -> true, ctx -> true])
        client = mock_client()
        dispatch_interaction!(tree, client, slash_interaction(name="ok"))
        @test called[]
    end

    @testset "dispatch APPLICATION_COMMAND with checks failing" begin
        tree = CommandTree()
        called = Ref(false)
        register_command!(tree, "nope", "Nope", ctx -> (called[] = true);
            checks=[ctx -> true, ctx -> false])
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            dispatch_interaction!(tree, client, slash_interaction(name="nope"))
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
        @test !called[]
    end

    # ── Dispatch: MESSAGE_COMPONENT ──────────────────────────────────────────────

    @testset "dispatch MESSAGE_COMPONENT exact match" begin
        tree = CommandTree()
        called = Ref(false)
        register_component!(tree, "btn_ok", ctx -> (called[] = true))

        client = mock_client()
        interaction = component_interaction(custom_id_val="btn_ok")
        dispatch_interaction!(tree, client, interaction)
        @test called[]
    end

    @testset "dispatch MESSAGE_COMPONENT prefix match" begin
        tree = CommandTree()
        called = Ref(false)
        register_component!(tree, "btn_", ctx -> (called[] = true))

        client = mock_client()
        interaction = component_interaction(custom_id_val="btn_delete_42")
        dispatch_interaction!(tree, client, interaction)
        @test called[]
    end

    @testset "dispatch MESSAGE_COMPONENT no match" begin
        tree = CommandTree()
        client = mock_client()
        interaction = component_interaction(custom_id_val="unknown_id")
        dispatch_interaction!(tree, client, interaction)
        @test true  # no error
    end

    @testset "dispatch MESSAGE_COMPONENT missing data" begin
        tree = CommandTree()
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(2),
            application_id=Snowflake(100),
            type=InteractionTypes.MESSAGE_COMPONENT,
            data=missing,
            token="tok",
            version=1,
        )
        dispatch_interaction!(tree, client, interaction)
        @test true
    end

    @testset "dispatch MESSAGE_COMPONENT handler error caught" begin
        tree = CommandTree()
        register_component!(tree, "err", ctx -> error("component boom"))
        client = mock_client()
        with_logger(NullLogger()) do
            dispatch_interaction!(tree, client, component_interaction(custom_id_val="err"))
        end
        @test true
    end

    # ── Dispatch: AUTOCOMPLETE ───────────────────────────────────────────────────

    @testset "dispatch AUTOCOMPLETE" begin
        tree = CommandTree()
        called = Ref(false)
        register_autocomplete!(tree, "search", ctx -> (called[] = true))

        client = mock_client()
        interaction = autocomplete_interaction(name="search")
        dispatch_interaction!(tree, client, interaction)
        @test called[]
    end

    @testset "dispatch AUTOCOMPLETE unknown command" begin
        tree = CommandTree()
        client = mock_client()
        dispatch_interaction!(tree, client, autocomplete_interaction(name="nope"))
        @test true
    end

    @testset "dispatch AUTOCOMPLETE missing data" begin
        tree = CommandTree()
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(3),
            application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND_AUTOCOMPLETE,
            data=missing,
            token="tok",
            version=1,
        )
        dispatch_interaction!(tree, client, interaction)
        @test true
    end

    @testset "dispatch AUTOCOMPLETE handler error caught" begin
        tree = CommandTree()
        register_autocomplete!(tree, "err", ctx -> error("ac boom"))
        client = mock_client()
        with_logger(NullLogger()) do
            dispatch_interaction!(tree, client, autocomplete_interaction(name="err"))
        end
        @test true
    end

    # ── Dispatch: MODAL_SUBMIT ───────────────────────────────────────────────────

    @testset "dispatch MODAL_SUBMIT" begin
        tree = CommandTree()
        called = Ref(false)
        register_modal!(tree, "feedback", ctx -> (called[] = true))

        client = mock_client()
        interaction = modal_interaction(custom_id_val="feedback")
        dispatch_interaction!(tree, client, interaction)
        @test called[]
    end

    @testset "dispatch MODAL_SUBMIT unknown" begin
        tree = CommandTree()
        client = mock_client()
        dispatch_interaction!(tree, client, modal_interaction(custom_id_val="???"))
        @test true
    end

    @testset "dispatch MODAL_SUBMIT missing data" begin
        tree = CommandTree()
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(4),
            application_id=Snowflake(100),
            type=InteractionTypes.MODAL_SUBMIT,
            data=missing,
            token="tok",
            version=1,
        )
        dispatch_interaction!(tree, client, interaction)
        @test true
    end

    @testset "dispatch MODAL_SUBMIT handler error caught" begin
        tree = CommandTree()
        register_modal!(tree, "err", ctx -> error("modal boom"))
        client = mock_client()
        with_logger(NullLogger()) do
            dispatch_interaction!(tree, client, modal_interaction(custom_id_val="err"))
        end
        @test true
    end

    # ── InteractionContext ───────────────────────────────────────────────────────

    @testset "InteractionContext constructor" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        @test ctx.responded[] == false
        @test ctx.deferred[] == false
        @test ctx.client === client
        @test ctx.interaction === interaction
    end

    @testset "InteractionContext .user from member" begin
        u = mock_user(id=Snowflake(42))
        m = Member(user=u, roles=Snowflake[])
        client = mock_client()
        interaction = slash_interaction(member=m)
        ctx = InteractionContext(client, interaction)
        @test ctx.user.id == Snowflake(42)
        @test ctx.author.id == Snowflake(42)  # alias
    end

    @testset "InteractionContext .user fallback to interaction.user" begin
        u = mock_user(id=Snowflake(77))
        client = mock_client()
        interaction = slash_interaction(user=u)
        ctx = InteractionContext(client, interaction)
        @test ctx.user.id == Snowflake(77)
    end

    @testset "InteractionContext .user returns nothing when absent" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        @test ctx.user === nothing
    end

    @testset "InteractionContext .guild_id" begin
        client = mock_client()
        interaction = slash_interaction(guild_id=Snowflake(888))
        ctx = InteractionContext(client, interaction)
        @test ctx.guild_id == Snowflake(888)
    end

    @testset "InteractionContext .channel_id" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        @test ctx.channel_id == Snowflake(200)
    end

    @testset "InteractionContext .state" begin
        client = mock_client(state_data="my_state")
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        @test ctx.state == "my_state"
    end

    # ── get_options / get_option ─────────────────────────────────────────────────

    @testset "get_options with values" begin
        opts = [
            InteractionDataOption(name="count", type=4, value=5),
            InteractionDataOption(name="name", type=3, value="hello"),
        ]
        client = mock_client()
        interaction = slash_interaction(options=opts)
        ctx = InteractionContext(client, interaction)
        result = get_options(ctx)
        @test result["count"] == 5
        @test result["name"] == "hello"
    end

    @testset "get_options empty" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        result = get_options(ctx)
        @test isempty(result)
    end

    @testset "get_options with missing data" begin
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND, data=missing,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test isempty(get_options(ctx))
    end

    @testset "get_option found" begin
        opts = [InteractionDataOption(name="x", type=4, value=42)]
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction(options=opts))
        @test get_option(ctx, "x") == 42
    end

    @testset "get_option default" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        @test get_option(ctx, "missing_opt", "fallback") == "fallback"
    end

    # ── custom_id ────────────────────────────────────────────────────────────────

    @testset "custom_id" begin
        client = mock_client()
        interaction = component_interaction(custom_id_val="btn_42")
        ctx = InteractionContext(client, interaction)
        @test custom_id(ctx) == "btn_42"
    end

    @testset "custom_id missing data" begin
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.MESSAGE_COMPONENT, data=missing,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test custom_id(ctx) === nothing
    end

    @testset "custom_id missing custom_id field" begin
        client = mock_client()
        data = InteractionData()  # all fields default to missing
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.MESSAGE_COMPONENT, data=data,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test custom_id(ctx) === nothing
    end

    # ── selected_values ──────────────────────────────────────────────────────────

    @testset "selected_values" begin
        client = mock_client()
        interaction = component_interaction(custom_id_val="sel", values=["a", "b"])
        ctx = InteractionContext(client, interaction)
        @test selected_values(ctx) == ["a", "b"]
    end

    @testset "selected_values empty" begin
        client = mock_client()
        interaction = component_interaction(custom_id_val="sel")
        ctx = InteractionContext(client, interaction)
        @test isempty(selected_values(ctx))
    end

    @testset "selected_values missing data" begin
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.MESSAGE_COMPONENT, data=missing,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test isempty(selected_values(ctx))
    end

    # ── modal_values ─────────────────────────────────────────────────────────────

    @testset "modal_values" begin
        inner1 = Component(type=4, custom_id="field1", value="hello")
        inner2 = Component(type=4, custom_id="field2", value="world")
        row1 = Component(type=1, components=[inner1])
        row2 = Component(type=1, components=[inner2])

        client = mock_client()
        interaction = modal_interaction(custom_id_val="form", components=[row1, row2])
        ctx = InteractionContext(client, interaction)
        vals = modal_values(ctx)
        @test vals["field1"] == "hello"
        @test vals["field2"] == "world"
    end

    @testset "modal_values empty" begin
        client = mock_client()
        interaction = modal_interaction(custom_id_val="form")
        ctx = InteractionContext(client, interaction)
        @test isempty(modal_values(ctx))
    end

    @testset "modal_values missing data" begin
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.MODAL_SUBMIT, data=missing,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test isempty(modal_values(ctx))
    end

    # ── target (context menu) ───────────────────────────────────────────────────

    @testset "target returns nothing when no data" begin
        client = mock_client()
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND, data=missing,
            token="tok", version=1,
        )
        ctx = InteractionContext(client, interaction)
        @test target(ctx) === nothing
    end

    @testset "target returns nothing when no target_id" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        @test target(ctx) === nothing
    end

    @testset "target returns nothing when no resolved" begin
        client = mock_client()
        interaction = slash_interaction(
            target_id=Snowflake(123),
            cmd_type=ApplicationCommandTypes.USER,
        )
        ctx = InteractionContext(client, interaction)
        @test target(ctx) === nothing
    end

    @testset "target USER command" begin
        u = mock_user(id=Snowflake(123))
        resolved = ResolvedData(users=Dict("123" => u))
        client = mock_client()
        interaction = slash_interaction(
            target_id=Snowflake(123),
            cmd_type=ApplicationCommandTypes.USER,
            resolved=resolved,
        )
        ctx = InteractionContext(client, interaction)
        t = target(ctx)
        @test t isa User
        @test t.id == Snowflake(123)
    end

    @testset "target MESSAGE command" begin
        msg = Message(id=Snowflake(456), channel_id=Snowflake(200))
        resolved = ResolvedData(messages=Dict("456" => msg))
        client = mock_client()
        interaction = slash_interaction(
            target_id=Snowflake(456),
            cmd_type=ApplicationCommandTypes.MESSAGE,
            resolved=resolved,
        )
        ctx = InteractionContext(client, interaction)
        t = target(ctx)
        @test t isa Message
        @test t.id == Snowflake(456)
    end

    # ── _is_present helper ───────────────────────────────────────────────────────

    @testset "_is_present" begin
        @test _is_present("hello") == true
        @test _is_present(42) == true
        @test _is_present(missing) == false
        @test _is_present(nothing) == false
    end

    # ── Checks ───────────────────────────────────────────────────────────────────

    @testset "run_checks all pass" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        @test run_checks([ctx -> true, ctx -> true], ctx) == true
    end

    @testset "run_checks one fails" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            ctx = InteractionContext(client, slash_interaction())
            @test run_checks([ctx -> true, ctx -> false], ctx) == false
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "run_checks exception in check" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            ctx = InteractionContext(client, slash_interaction())
            with_logger(NullLogger()) do
                @test run_checks([ctx -> error("check error")], ctx) == false
            end
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "run_checks empty" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        @test run_checks(Function[], ctx) == true
    end

    # ── drain_pending_checks! ───────────────────────────────────────────────────

    @testset "drain_pending_checks!" begin
        lock(_CHECKS_LOCK) do
            empty!(_PENDING_CHECKS)
            push!(_PENDING_CHECKS, ctx -> true)
            push!(_PENDING_CHECKS, ctx -> false)
        end
        drained = drain_pending_checks!()
        @test length(drained) == 2
        # Should be empty after drain
        @test isempty(drain_pending_checks!())
    end

    # ── is_in_guild ──────────────────────────────────────────────────────────────

    @testset "is_in_guild pass" begin
        client = mock_client()
        interaction = slash_interaction(guild_id=Snowflake(111))
        ctx = InteractionContext(client, interaction)
        check = is_in_guild()
        @test check(ctx) == true
    end

    @testset "is_in_guild fail (DM)" begin
        client = mock_client()
        interaction = slash_interaction()  # guild_id=missing
        ctx = InteractionContext(client, interaction)
        check = is_in_guild()
        @test check(ctx) == false
    end

    # ── is_owner ─────────────────────────────────────────────────────────────────

    @testset "is_owner pass" begin
        client = mock_client()
        guild_id = Snowflake(111)
        user_id = Snowflake(42)

        # Put guild in cache with owner_id
        guild = Guild(id=guild_id, owner_id=user_id)
        client.state.guilds[guild_id] = guild

        u = mock_user(id=user_id)
        m = Member(user=u, roles=Snowflake[])
        interaction = slash_interaction(guild_id=guild_id, member=m)
        ctx = InteractionContext(client, interaction)

        check = is_owner()
        @test check(ctx) == true
    end

    @testset "is_owner fail" begin
        client = mock_client()
        guild_id = Snowflake(111)

        guild = Guild(id=guild_id, owner_id=Snowflake(999))
        client.state.guilds[guild_id] = guild

        u = mock_user(id=Snowflake(42))
        m = Member(user=u, roles=Snowflake[])
        interaction = slash_interaction(guild_id=guild_id, member=m)
        ctx = InteractionContext(client, interaction)

        check = is_owner()
        @test check(ctx) == false
    end

    @testset "is_owner fail (no guild in cache)" begin
        client = mock_client()
        u = mock_user(id=Snowflake(42))
        m = Member(user=u, roles=Snowflake[])
        interaction = slash_interaction(guild_id=Snowflake(111), member=m)
        ctx = InteractionContext(client, interaction)
        check = is_owner()
        @test check(ctx) == false
    end

    @testset "is_owner fail (DM)" begin
        client = mock_client()
        interaction = slash_interaction()
        ctx = InteractionContext(client, interaction)
        check = is_owner()
        @test check(ctx) == false
    end

    # ── cooldown ─────────────────────────────────────────────────────────────────

    @testset "cooldown per user" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            u = mock_user(id=Snowflake(42))
            m = Member(user=u, roles=Snowflake[])
            interaction = slash_interaction(guild_id=Snowflake(111), member=m)

            check = cooldown(100.0; per=:user)  # long cooldown so second call fails
            ctx1 = InteractionContext(client, interaction)
            @test check(ctx1) == true  # first call passes

            ctx2 = InteractionContext(client, interaction)
            @test check(ctx2) == false  # second call blocked
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown per guild" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            u = mock_user(id=Snowflake(42))
            m = Member(user=u, roles=Snowflake[])
            interaction = slash_interaction(guild_id=Snowflake(111), member=m)

            check = cooldown(100.0; per=:guild)
            ctx1 = InteractionContext(client, interaction)
            @test check(ctx1) == true

            ctx2 = InteractionContext(client, interaction)
            @test check(ctx2) == false
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown per channel" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            interaction = slash_interaction()
            check = cooldown(100.0; per=:channel)
            ctx1 = InteractionContext(client, interaction)
            @test check(ctx1) == true
            ctx2 = InteractionContext(client, interaction)
            @test check(ctx2) == false
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown per global" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            interaction = slash_interaction()
            check = cooldown(100.0; per=:global)
            ctx1 = InteractionContext(client, interaction)
            @test check(ctx1) == true
            ctx2 = InteractionContext(client, interaction)
            @test check(ctx2) == false
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown invalid bucket" begin
        @test_throws ErrorException cooldown(5; per=:invalid)
    end

    @testset "cooldown expiry allows re-use" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            u = mock_user(id=Snowflake(42))
            m = Member(user=u, roles=Snowflake[])
            interaction = slash_interaction(guild_id=Snowflake(111), member=m)

            check = cooldown(0.1; per=:user)  # 100ms cooldown
            ctx1 = InteractionContext(client, interaction)
            @test check(ctx1) == true

            ctx2 = InteractionContext(client, interaction)
            @test check(ctx2) == false  # Still in cooldown

            sleep(0.2)  # Wait for cooldown to expire

            ctx3 = InteractionContext(client, interaction)
            @test check(ctx3) == true  # Cooldown expired, should pass
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown concurrent access is safe" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            check = cooldown(100.0; per=:global)  # Long cooldown, global bucket

            # Launch many tasks concurrently — exactly one should pass
            n_tasks = 20
            results = Vector{Bool}(undef, n_tasks)
            @sync for i in 1:n_tasks
                Threads.@spawn begin
                    u = mock_user(id=Snowflake(i))
                    m = Member(user=u, roles=Snowflake[])
                    interaction = slash_interaction(guild_id=Snowflake(111), member=m)
                    ctx = InteractionContext(client, interaction)
                    results[i] = check(ctx)
                end
            end

            # Exactly one task should have passed the cooldown
            @test count(results) == 1
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    @testset "cooldown per-user different users independent" begin
        client = mock_client(application_id=Snowflake(100))
        start_ratelimiter!(client.ratelimiter)
        try
            check = cooldown(100.0; per=:user)

            # User A
            u_a = mock_user(id=Snowflake(1))
            m_a = Member(user=u_a, roles=Snowflake[])
            int_a = slash_interaction(guild_id=Snowflake(111), member=m_a)
            ctx_a = InteractionContext(client, int_a)
            @test check(ctx_a) == true  # User A first call

            # User B — different user, should not be affected by A's cooldown
            u_b = mock_user(id=Snowflake(2))
            m_b = Member(user=u_b, roles=Snowflake[])
            int_b = slash_interaction(guild_id=Snowflake(111), member=m_b)
            ctx_b = InteractionContext(client, int_b)
            @test check(ctx_b) == true  # User B first call

            # User A again — should be blocked
            ctx_a2 = InteractionContext(client, int_a)
            @test check(ctx_a2) == false
        finally
            stop_ratelimiter!(client.ratelimiter)
        end
    end

    # ── _cooldown_key ────────────────────────────────────────────────────────────

    @testset "_cooldown_key user" begin
        client = mock_client()
        u = mock_user(id=Snowflake(42))
        m = Member(user=u, roles=Snowflake[])
        ctx = InteractionContext(client, slash_interaction(member=m))
        @test _cooldown_key(ctx, :user) == UInt64(42)
    end

    @testset "_cooldown_key guild" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction(guild_id=Snowflake(111)))
        @test _cooldown_key(ctx, :guild) == UInt64(111)
    end

    @testset "_cooldown_key channel" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        @test _cooldown_key(ctx, :channel) == UInt64(200)  # channel_id=200 from helper
    end

    @testset "_cooldown_key global" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        @test _cooldown_key(ctx, :global) == UInt64(0)
    end

    @testset "_cooldown_key user nil" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        # No member/user → returns 0
        @test _cooldown_key(ctx, :user) == UInt64(0)
    end

    # ── CheckFailedError ─────────────────────────────────────────────────────────

    @testset "CheckFailedError" begin
        err = CheckFailedError("perm_check")
        @test err.check_name == "perm_check"
        @test err.message == "Check 'perm_check' failed."

        err2 = CheckFailedError("test", "custom message")
        @test err2.message == "custom message"
    end

    # ── has_permissions ──────────────────────────────────────────────────────────

    @testset "has_permissions with admin role" begin
        client = mock_client()
        guild_id = Snowflake(111)
        user_id = Snowflake(42)
        role_id = Snowflake(300)

        # Create a role with ADMINISTRATOR permission
        role = Role(id=role_id, name="Admin", permissions=string(UInt64(PermAdministrator.value)))
        role_store = Store{Role}()
        role_store[role_id] = role
        client.state.roles[guild_id] = role_store

        # Create guild (non-owner)
        guild = Guild(id=guild_id, owner_id=Snowflake(999))
        client.state.guilds[guild_id] = guild

        u = mock_user(id=user_id)
        m = Member(user=u, roles=[role_id])
        interaction = slash_interaction(guild_id=guild_id, member=m)
        ctx = InteractionContext(client, interaction)

        check = has_permissions(PermManageGuild)
        @test check(ctx) == true  # ADMINISTRATOR implies all perms
    end

    @testset "has_permissions fail (no matching perm)" begin
        client = mock_client()
        guild_id = Snowflake(111)
        user_id = Snowflake(42)
        role_id = Snowflake(300)

        # Role with only SEND_MESSAGES
        role = Role(id=role_id, name="Chatter", permissions=string(UInt64(PermSendMessages.value)))
        role_store = Store{Role}()
        role_store[role_id] = role
        client.state.roles[guild_id] = role_store

        guild = Guild(id=guild_id, owner_id=Snowflake(999))
        client.state.guilds[guild_id] = guild

        u = mock_user(id=user_id)
        m = Member(user=u, roles=[role_id])
        interaction = slash_interaction(guild_id=guild_id, member=m)
        ctx = InteractionContext(client, interaction)

        check = has_permissions(PermManageGuild)
        @test check(ctx) == false
    end

    @testset "has_permissions fail (DM)" begin
        client = mock_client()
        ctx = InteractionContext(client, slash_interaction())
        check = has_permissions(PermManageGuild)
        @test check(ctx) == false
    end

    @testset "has_permissions with symbol" begin
        # Just verify it doesn't error
        check = has_permissions(:MANAGE_GUILD)
        @test check isa Function
    end

    @testset "has_permissions with multiple symbols" begin
        check = has_permissions(:MANAGE_GUILD, :BAN_MEMBERS)
        @test check isa Function
    end

    @testset "has_permissions unknown symbol" begin
        @test_throws ErrorException has_permissions(:NONEXISTENT_PERM)
    end

    # ── Handler receives correct context ────────────────────────────────────────

    @testset "handler receives InteractionContext" begin
        tree = CommandTree()
        received_ctx = Ref{Any}(nothing)
        register_command!(tree, "info", "Info", ctx -> (received_ctx[] = ctx))

        client = mock_client()
        interaction = slash_interaction(name="info", guild_id=Snowflake(555))
        dispatch_interaction!(tree, client, interaction)

        ctx = received_ctx[]
        @test ctx isa InteractionContext
        @test ctx.guild_id == Snowflake(555)
        @test ctx.client === client
    end

    @testset "component handler receives context with custom_id" begin
        tree = CommandTree()
        received_cid = Ref{Any}(nothing)
        register_component!(tree, "sel_color", ctx -> (received_cid[] = custom_id(ctx)))

        client = mock_client()
        interaction = component_interaction(custom_id_val="sel_color")
        dispatch_interaction!(tree, client, interaction)
        @test received_cid[] == "sel_color"
    end

    @testset "modal handler receives context with modal_values" begin
        tree = CommandTree()
        received_vals = Ref{Any}(nothing)
        register_modal!(tree, "form", ctx -> (received_vals[] = modal_values(ctx)))

        inner = Component(type=4, custom_id="name", value="Alice")
        row = Component(type=1, components=[inner])

        client = mock_client()
        interaction = modal_interaction(custom_id_val="form", components=[row])
        dispatch_interaction!(tree, client, interaction)
        @test received_vals[]["name"] == "Alice"
    end

    # ── Multiple commands in tree ────────────────────────────────────────────────

    @testset "multiple commands dispatch correctly" begin
        tree = CommandTree()
        called_ping = Ref(false)
        called_pong = Ref(false)
        register_command!(tree, "ping", "Ping", ctx -> (called_ping[] = true))
        register_command!(tree, "pong", "Pong", ctx -> (called_pong[] = true))

        client = mock_client()
        dispatch_interaction!(tree, client, slash_interaction(name="ping"))
        @test called_ping[]
        @test !called_pong[]

        dispatch_interaction!(tree, client, slash_interaction(name="pong"))
        @test called_pong[]
    end
end
