# =========================================================================================
# CHAOS BOT — Intentionally triggers errors to test the Diagnoser
# =========================================================================================
# Usage:
#   julia --project=. examples/chaos_bot.jl <test_case>
#
# Test Cases:
#   1. missing_token
#   2. invalid_token
#   3. sharding_error
#   4. unknown_channel
#   5. empty_message
# =========================================================================================

using Accord
using Logging

# Mock enviroment / Simple client setup
const TEST_TOKEN = get(ENV, "DISCORD_TOKEN", "mock_token")

function run_chaos(test_case)
    println("🔥 RUNNING CHAOS TEST: $test_case 🔥\n")

    try
        if test_case == "missing_token"
            c = Client("")
            # Non-blocking start so we don't hang on fatal error
            start(c; blocking=false)
            sleep(5) # Wait for gateway connection attempt
        elseif test_case == "invalid_token"
            c = Client("Bot my token has spaces")
            start(c; blocking=false)
            sleep(2)
        elseif test_case == "sharding_error"
            # Force invalid sharding
            c = Client(TEST_TOKEN)
            Accord.start_shard(Accord.ShardInfo(0, 500, Channel{Any}(1)), TEST_TOKEN, UInt32(0)) 
            # Note: This is a bit harder to trigger purely via Client API without mocking, 
            # but usually it throws ArgumentError inside start() if we had validation there.
            # For now mimicking the error via manual throw to test the matcher:
            throw(ArgumentError("Invalid shard configuration: Sharding required for >2500 guilds"))
        elseif test_case == "unknown_channel"
            c = Client(TEST_TOKEN)
            # We need a RateLimiter and Route to hit the API
            # This will fail with 401 if token is mock, but let's try to hit a 404
            # We mock the response to trigger the diagnostic logic without hitting real API
            throw(Accord.HTTP.StatusError(404, "GET", "/channels/123", Accord.HTTP.Response(404, "{\"code\": 10003, \"message\": \"Unknown Channel\"}")))
        elseif test_case == "empty_message"
             throw(Accord.HTTP.StatusError(400, "POST", "/messages", Accord.HTTP.Response(400, "{\"code\": 50006, \"message\": \"Cannot send an empty message\"}")))
        else
            println("Unknown test case")
        end
    catch e
        # Manually invoke the report function as if it happened in the event loop
        Accord.Diagnoser.report(e, catch_backtrace())
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if isempty(ARGS)
        println("Usage: julia chaos_bot.jl <test_case>")
        exit(1)
    end
    run_chaos(ARGS[1])
end
