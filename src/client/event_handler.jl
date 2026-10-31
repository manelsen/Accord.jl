# Event handler dispatch system
#
# Internal module: Stores and dispatches registered event handlers and middleware.
# Supports per-event-type handlers and catch-all AbstractEvent handlers.

"""
    EventHandler

Use this internal struct to manage event handlers and middleware for the client.

Stores registered event handlers for the client.

# Example
```julia
eh = EventHandler()  # fresh handler with no handlers registered
```
"""
mutable struct EventHandler
    handlers::Dict{Type{<:AbstractEvent}, Vector{Function}}
    middleware::Vector{Function}
    error_handler::Function
    lock::ReentrantLock  # registration may happen while handlers run on other threads
end

function EventHandler()
    EventHandler(
        Dict{Type{<:AbstractEvent}, Vector{Function}}(),
        Function[],
        _default_error_handler,
        ReentrantLock(),
    )
end

function _default_error_handler(client, event, error)
    # DIAGNOSTICS: Try to present a friendly error report
    try
        Diagnoser.report(error, catch_backtrace())
    catch e
        @error "Failed to report diagnostic" exception=e
    end
end

"""
    register_handler!(eh::EventHandler, event_type, handler)

Use this internal function to add an event handler for a specific gateway event type.

Register a handler function for a specific event type.
The handler should accept (client, event).

# Example
```julia
register_handler!(eh, MessageCreate, (client, event) -> println(event.message.content))
```
"""
function register_handler!(eh::EventHandler, ::Type{T}, handler::Function) where T <: AbstractEvent
    lock(eh.lock) do
        push!(get!(eh.handlers, T, Function[]), handler)
    end
end

"""
    register_middleware!(eh::EventHandler, middleware)

Use this internal function to add middleware that processes events before handlers.

Register middleware that runs before event handlers.
Middleware should accept (client, event) and return the event (or nothing to cancel).

# Example
```julia
register_middleware!(eh, (client, event) -> begin
    @info "Event received" type=typeof(event)
    event  # return event to continue, or nothing to cancel
end)
```
"""
function register_middleware!(eh::EventHandler, middleware::Function)
    lock(() -> push!(eh.middleware, middleware), eh.lock)
end

"""
    dispatch_event!(eh::EventHandler, client, event)

Use this internal function to route an incoming event to all applicable handlers.

Dispatch an event to all registered handlers.

# Example
```julia
event = MessageCreate(message)
dispatch_event!(client.event_handler, client, event)
```
"""
function dispatch_event!(eh::EventHandler, client, event::AbstractEvent)
    # Snapshot the registrations so handlers can be added while events flow
    middleware, handlers, abstract_handlers = lock(eh.lock) do
        (copy(eh.middleware),
         copy(get(eh.handlers, typeof(event), Function[])),
         copy(get(eh.handlers, AbstractEvent, Function[])))
    end

    # Run middleware
    current_event = event
    for mw in middleware
        try
            result = Base.invokelatest(mw, client, current_event)
            if isnothing(result)
                return  # Middleware cancelled the event
            end
            current_event = result
        catch e
            Base.invokelatest(eh.error_handler, client, current_event, e)
            return
        end
    end

    # Dispatch to type-specific handlers (middleware may have replaced the event)
    event_type = typeof(current_event)
    if event_type !== typeof(event)
        handlers = lock(() -> copy(get(eh.handlers, event_type, Function[])), eh.lock)
    end

    for handler in handlers
        try
            Base.invokelatest(handler, client, current_event)
        catch e
            Base.invokelatest(eh.error_handler, client, current_event, e)
        end
    end

    # Also dispatch to AbstractEvent handlers (catch-all)
    if event_type != AbstractEvent
        for handler in abstract_handlers
            try
                Base.invokelatest(handler, client, current_event)
            catch e
                Base.invokelatest(eh.error_handler, client, current_event, e)
            end
        end
    end
end
