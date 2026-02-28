@testitem "Fault Injection: Rate Limiter" tags=[:unit, :fault_injection] begin
    using Accord, HTTP, JSON3, Dates
    # Access internal symbols via Accord
    using Accord: RateLimiter, Route, submit_rest, RestJob, url, start_ratelimiter!, stop_ratelimiter!

    # Helper: Build an HTTP.Response with rate limit headers
    function rl_response(status=200; remaining=nothing, reset=nothing,
                         reset_after=nothing, bucket=nothing,
                         global_rl=false, retry_after=nothing, body="{}")
        headers = Pair{String,String}[]
        !isnothing(remaining)   && push!(headers, "X-RateLimit-Remaining" => string(remaining))
        !isnothing(reset)       && push!(headers, "X-RateLimit-Reset" => string(reset))
        !isnothing(reset_after) && push!(headers, "X-RateLimit-Reset-After" => string(reset_after))
        !isnothing(bucket)      && push!(headers, "X-RateLimit-Bucket" => bucket)
        global_rl               && push!(headers, "X-RateLimit-Global" => "true")
        !isnothing(retry_after) && push!(headers, "Retry-After" => string(retry_after))
        HTTP.Response(status, headers; body=Vector{UInt8}(body))
    end

    @testset "Retry-After 429 (Bucket)" begin
        rl = RateLimiter(; global_limit=10)
        start_ratelimiter!(rl)
        
        route = Route("POST", "/channels/{channel_id}/messages", "channel_id" => "fault_1")
        
        call_count = Ref(0)
        handler = (method, url, headers, body) -> begin
            call_count[] += 1
            if call_count[] == 1
                return rl_response(429; retry_after=0.5, body="{\"message\": \"Too Many Requests\", \"retry_after\": 0.5}")
            else
                return HTTP.Response(200, ["Content-Type" => "application/json"], body="{\"id\": \"123\"}")
            end
        end
        rl.request_handler = handler

        try
            job = RestJob(route, "POST", url(route), ["Authorization" => "Bot test"], "{\"content\": \"hi\"}", Channel{Any}(1))
            
            t_start = time()
            resp = submit_rest(rl, job)
            t_end = time()
            
            @test resp isa HTTP.Response
            @test resp.status == 200
            @test call_count[] == 2
            @test (t_end - t_start) >= 0.5
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "Global Rate Limit 429" begin
        rl = RateLimiter(; global_limit=10)
        start_ratelimiter!(rl)
        
        route = Route("GET", "/users/@me")
        
        call_count = Ref(0)
        handler = (method, url, headers, body) -> begin
            call_count[] += 1
            if call_count[] == 1
                return rl_response(429; global_rl=true, retry_after=0.3, body="{\"global\": true, \"retry_after\": 0.3}")
            else
                return HTTP.Response(200, body="{}")
            end
        end
        rl.request_handler = handler

        try
            job = RestJob(route, "GET", url(route), ["Authorization" => "Bot test"], nothing, Channel{Any}(1))
            
            t_start = time()
            resp = submit_rest(rl, job)
            t_end = time()
            
            @test resp.status == 200
            @test call_count[] == 2
            @test (t_end - t_start) >= 0.3
        finally
            stop_ratelimiter!(rl)
        end
    end
end

@testitem "Fault Injection: Gateway" tags=[:unit, :fault_injection] begin
    using Accord, HTTP, JSON3, Dates
    # Import internal symbols for testing
    using Accord: start_heartbeat, HeartbeatState, stop_heartbeat!

    mutable struct MockWebSocket
        sent::Vector{String}
        closed::Bool
    end
    MockWebSocket() = MockWebSocket(String[], false)
    HTTP.WebSockets.send(ws::MockWebSocket, msg) = push!(ws.sent, msg)
    HTTP.WebSockets.close(ws::MockWebSocket) = (ws.closed = true)

    @testset "Missed Heartbeat ACK → Session Failure" begin
        ws = MockWebSocket()
        seq_ref = Ref{Union{Int,Nothing}}(nothing)
        stop = Base.Event()
        
        interval = 100 # ms
        
        task, state = start_heartbeat(ws, interval, seq_ref, stop)
        
        # 1. Wait for first heartbeat to be sent
        timeout = 2.0
        start_t = time()
        while isempty(ws.sent) && (time() - start_t < timeout)
            sleep(0.01)
        end
        @test !isempty(ws.sent)
        @test state.ack_received == false
        
        # 2. We DO NOT call heartbeat_ack!(state).
        # 3. Next iteration (after ~100ms) will see ack_received == false, close the ws, and exit.
        
        wait_t = time()
        while !istaskdone(task) && (time() - wait_t < timeout)
            sleep(0.01)
        end
        
        @test istaskdone(task)
        @test ws.closed == true
        @test state.running == false
    end
end
