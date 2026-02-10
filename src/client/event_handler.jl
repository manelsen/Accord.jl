# Event handler dispatch system

"""
    EventHandler

Stores registered event handlers for the client.
"""
mutable struct EventHandler
    handlers::Dict{Type{<:AbstractEvent}, Vector{Function}}
    middleware::Vector{Function}
    error_handler::Function
end

function EventHandler()
    EventHandler(
        Dict{Type{<:AbstractEvent}, Vector{Function}}(),
        Function[],
        _default_error_handler,
    )
end

function _default_error_handler(client, event, error)
    @error "Error in event handler" event_type=typeof(event) exception=(error, catch_backtrace())
end

"""
    register_handler!(eh::EventHandler, event_type, handler)

Register a handler function for a specific event type.
The handler should accept (client, event).
"""
function register_handler!(eh::EventHandler, ::Type{T}, handler::Function) where T <: AbstractEvent
    handlers = get!(eh.handlers, T, Function[])
    push!(handlers, handler)
end

"""
    register_middleware!(eh::EventHandler, middleware)

Register middleware that runs before event handlers.
Middleware should accept (client, event) and return the event (or nothing to cancel).
"""
function register_middleware!(eh::EventHandler, middleware::Function)
    push!(eh.middleware, middleware)
end

"""
    dispatch_event!(eh::EventHandler, client, event)

Dispatch an event to all registered handlers.
"""
function dispatch_event!(eh::EventHandler, client, event::AbstractEvent)
    # Run middleware
    current_event = event
    for mw in eh.middleware
        try
            result = mw(client, current_event)
            if isnothing(result)
                return  # Middleware cancelled the event
            end
            current_event = result
        catch e
            eh.error_handler(client, current_event, e)
            return
        end
    end

    # Dispatch to type-specific handlers
    event_type = typeof(current_event)
    handlers = get(eh.handlers, event_type, Function[])

    for handler in handlers
        try
            handler(client, current_event)
        catch e
            eh.error_handler(client, current_event, e)
        end
    end

    # Also dispatch to AbstractEvent handlers (catch-all)
    if event_type != AbstractEvent
        abstract_handlers = get(eh.handlers, AbstractEvent, Function[])
        for handler in abstract_handlers
            try
                handler(client, current_event)
            catch e
                eh.error_handler(client, current_event, e)
            end
        end
    end
end
