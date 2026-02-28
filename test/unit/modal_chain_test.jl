@testitem "Modal chaining guard (M2)" tags=[:unit] begin
    using Accord

    # Build a minimal mock context with responded/deferred refs
    function _mock_ctx(; responded=false, deferred=false)
        # Use a real client instance to satisfy InteractionContext typing.
        client_stub = Client("mock_token")
        interaction = Interaction(id=Snowflake(1), type=InteractionTypes.APPLICATION_COMMAND,
                                  token="tok", application_id=Snowflake(2))
        ctx = InteractionContext(client_stub, interaction, Ref(responded), Ref(deferred))
        ctx
    end

    @testset "show_modal throws if already responded" begin
        ctx = _mock_ctx(responded=true)
        @test_throws ArgumentError show_modal(ctx;
            title="T", custom_id="c", components=[])
    end

    @testset "show_modal throws if already deferred" begin
        ctx = _mock_ctx(deferred=true)
        @test_throws ArgumentError show_modal(ctx;
            title="T", custom_id="c", components=[])
    end

    @testset "show_modal guard messages are descriptive" begin
        ctx = _mock_ctx(responded=true)
        err = try show_modal(ctx; title="T", custom_id="c", components=[]); nothing
              catch e; e; end
        @test err isa ArgumentError
        @test occursin("already responded", err.msg)

        ctx2 = _mock_ctx(deferred=true)
        err2 = try show_modal(ctx2; title="T", custom_id="c", components=[]); nothing
               catch e; e; end
        @test err2 isa ArgumentError
        @test occursin("deferred", err2.msg)
    end
end
