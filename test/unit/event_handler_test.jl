@testitem "Event Handler" tags=[:unit] begin
    using Accord
    using Accord: EventHandler, register_handler!, register_middleware!, dispatch_event!,
        AbstractEvent, MessageCreate, Message, User, Snowflake

    # Mock Event for testing if needed, or reuse MessageCreate
    struct TestEvent <: AbstractEvent
        data::String
    end

    # Minimal mock client
    struct MockEHClient end

    @testset "Basic Dispatch" begin
        eh = EventHandler()
        client = MockEHClient()
        called = false
        
        register_handler!(eh, TestEvent, (c, e) -> (called = true))
        
        evt = TestEvent("test")
        dispatch_event!(eh, client, evt)
        
        @test called == true
    end

    @testset "Multiple Handlers" begin
        eh = EventHandler()
        client = MockEHClient()
        count = Ref(0)
        
        register_handler!(eh, TestEvent, (c, e) -> (count[] += 1))
        register_handler!(eh, TestEvent, (c, e) -> (count[] += 2))
        
        dispatch_event!(eh, client, TestEvent("test"))
        
        @test count[] == 3
    end

    @testset "Middleware - Pass Through" begin
        eh = EventHandler()
        client = MockEHClient()
        mw_called = false
        handler_called = false
        
        register_middleware!(eh, (c, e) -> begin
            mw_called = true
            return e
        end)
        
        register_handler!(eh, TestEvent, (c, e) -> (handler_called = true))
        
        dispatch_event!(eh, client, TestEvent("test"))
        
        @test mw_called == true
        @test handler_called == true
    end

    @testset "Middleware - Modify Event" begin
        eh = EventHandler()
        client = MockEHClient()
        
        register_middleware!(eh, (c, e) -> begin
            return TestEvent(e.data * "_modified")
        end)
        
        captured_data = ""
        register_handler!(eh, TestEvent, (c, e) -> (captured_data = e.data))
        
        dispatch_event!(eh, client, TestEvent("original"))
        
        @test captured_data == "original_modified"
    end

    @testset "Middleware - Cancel Event" begin
        eh = EventHandler()
        client = MockEHClient()
        handler_called = false
        
        register_middleware!(eh, (c, e) -> nothing) # Return nothing to cancel
        
        register_handler!(eh, TestEvent, (c, e) -> (handler_called = true))
        
        dispatch_event!(eh, client, TestEvent("test"))
        
        @test handler_called == false
    end

    @testset "Error Handling" begin
        eh = EventHandler()
        client = MockEHClient()
        error_captured = Ref{Any}(nothing)
        
        # Custom error handler
        eh.error_handler = (c, e, err) -> (error_captured[] = err)
        
        register_handler!(eh, TestEvent, (c, e) -> error("Boom!"))
        
        dispatch_event!(eh, client, TestEvent("test"))
        
        @test error_captured[] isa Exception
        @test error_captured[].msg == "Boom!"
    end

    @testset "Catch-All Handler (AbstractEvent)" begin
        eh = EventHandler()
        client = MockEHClient()
        caught_event = Ref{Any}(nothing)
        
        register_handler!(eh, AbstractEvent, (c, e) -> (caught_event[] = e))
        
        evt = TestEvent("specific")
        dispatch_event!(eh, client, evt)
        
        @test caught_event[] === evt
    end

    @testset "handler defined after the dispatch loop started" begin
        eh = EventHandler()
        errors = Ref(0)
        eh.error_handler = (c, e, err) -> (errors[] += 1)
        events = Channel{Any}(1)
        done = Channel{Bool}(1)
        # A long-lived task runs in the world it started in, like the client's event loop
        loop = Threads.@spawn for ev in events
            dispatch_event!(eh, MockEHClient(), ev)
            put!(done, true)
        end
        # Defining a method afterwards, as at the REPL, makes it too new for that task
        make_handler = Core.eval(@__MODULE__, :(hits -> (c, e) -> (hits[] += 1)))
        hits = Ref(0)
        register_handler!(eh, TestEvent, Base.invokelatest(make_handler, hits))
        put!(events, TestEvent("late"))
        take!(done)
        close(events)
        wait(loop)
        @test hits[] == 1
        @test errors[] == 0
    end
end
