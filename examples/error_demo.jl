# error_demo.jl — Showcase for Accord.jl's Elm-like Diagnostics
# Run this script to see the friendly error boxes in action!
# Usage: julia --project=. examples/error_demo.jl <error_name>

using Accord
using Accord.HTTP
using Accord.JSON3

const TEST_TOKEN = "Bot MOCK_TOKEN_FOR_TESTING"

function print_usage()
    println("Usage: julia --project=. examples/error_demo.jl <case>")
    println("\nAvailable cases:")
    println("  missing_token    -> Client(\"\")")
    println("  invalid_token    -> Client(\"Bot token with spaces\")")
    println("  unknown_channel  -> 404 Unknown Channel (via mock request)")
    println("  auth_failed      -> 4004 Authentication Failed (via mock socket)")
    println("  missing_perms    -> 50013 Missing Permissions (via mock request)")
end

function run_demo(case)
    println("🔥 TRIGGERING ERROR: $case 🔥\n")

    try
        if case == "missing_token"
            Client("")
        elseif case == "invalid_token"
            Client("Bot token with spaces")
        elseif case == "unknown_channel"
            # Simulate a 404 from Discord API
            throw(HTTP.StatusError(404, "GET", "/channels/123", HTTP.Response(404, "{\"code\": 10003, \"message\": \"Unknown Channel\"}")))
        elseif case == "missing_perms"
            # Simulate a 50013 from Discord API
            throw(HTTP.StatusError(403, "POST", "/channels/123/messages", HTTP.Response(403, "{\"code\": 50013, \"message\": \"Missing Permissions\"}"))) 
        elseif case == "auth_failed"
            # Simulate a 4004 from Gateway (WebSocket Close)
            # We construct the error manually as if it came from WS
            ws_err = HTTP.WebSockets.WebSocketError(HTTP.WebSockets.CloseFrameBody(4004, "Authentication Failed"))
            throw(ws_err)
        else
            println("Unknown case: $case")
            print_usage()
        end
    catch e
        # In a real app, this happens inside the event loop or http client.
        # Here we manually invoke the reporter to show what it looks like.
        Accord.Diagnoser.report(e, catch_backtrace())
    end
end

if isempty(ARGS)
    print_usage()
else
    run_demo(ARGS[1])
end
