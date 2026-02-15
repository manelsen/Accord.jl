@testitem "HTTP Client" tags=[:unit] begin
    using Accord, HTTP, JSON3
    using Accord: discord_request, parse_response, parse_response_array, RateLimiter, Route,
        start_ratelimiter!, stop_ratelimiter!, USER_AGENT, RestJob

    # ── Mock Rate Limiter Helper ─────────────────────────────────────────────────

    function with_capture_rl(f)
        rl = RateLimiter()
        captured = Ref{Any}(nothing)
        
        # Mock handler that captures the arguments passed to HTTP.request
        # signature: (method, url, headers, body) -> Response
        rl.request_handler = (m, u, h, b) -> begin
            captured[] = (method=m, url=u, headers=h, body=b)
            return HTTP.Response(200, "{}")
        end
        
        start_ratelimiter!(rl)
        try
            f(rl, captured)
        finally
            stop_ratelimiter!(rl)
        end
    end

    @testset "Headers & Auth" begin
        with_capture_rl() do rl, cap
            route = Route("GET", "/test")
            discord_request(rl, route; token="Bot mytoken")
            
            req = cap[]
            headers = Dict(req.headers)
            
            @test headers["Authorization"] == "Bot mytoken"
            @test headers["User-Agent"] == USER_AGENT
            @test !haskey(headers, "X-Audit-Log-Reason")
        end
    end

    @testset "Audit Log Reason" begin
        with_capture_rl() do rl, cap
            route = Route("POST", "/ban")
            reason = "Spamming & Trolling" # Needs escaping
            discord_request(rl, route; token="tok", reason=reason)
            
            req = cap[]
            headers = Dict(req.headers)
            
            @test haskey(headers, "X-Audit-Log-Reason")
            # Should be URL encoded: space -> %20 or +
            @test headers["X-Audit-Log-Reason"] == "Spamming%20%26%20Trolling"
        end
    end

    @testset "Query Parameters" begin
        with_capture_rl() do rl, cap
            route = Route("GET", "/messages")
            q = Dict("limit" => 50, "after" => "123", "null_val" => nothing)
            discord_request(rl, route; token="tok", query=q)
            
            req = cap[]
            url = req.url
            
            @test contains(url, "?")
            @test contains(url, "limit=50")
            @test contains(url, "after=123")
            @test !contains(url, "null_val")
        end
    end

    @testset "JSON Body" begin
        with_capture_rl() do rl, cap
            route = Route("POST", "/msg")
            body = Dict("content" => "hello")
            discord_request(rl, route; token="tok", body=body)
            
            req = cap[]
            headers = Dict(req.headers)
            
            @test headers["Content-Type"] == "application/json"
            @test JSON3.read(req.body).content == "hello"
        end
    end

    @testset "Multipart Upload" begin
        with_capture_rl() do rl, cap
            route = Route("POST", "/upload")
            body = Dict("content" => "look at this")
            files = [
                ("image.png", UInt8[1, 2, 3], "image/png"),
                ("text.txt", "some text", "text/plain")
            ]
            discord_request(rl, route; token="tok", body=body, files=files)
            
            req = cap[]
            # HTTP.jl Forms handling is complex to inspect directly, 
            # but we can check the object type
            @test req.body isa HTTP.Forms.Form
            # We trust HTTP.Forms to do the right thing if constructed correctly
        end
    end

    @testset "Response Parsing - Success" begin
        resp = HTTP.Response(200, """{"id": "123", "name": "foo"}""")
        
        # Parse Object
        obj = parse_response(Dict{String, Any}, resp)
        @test obj["id"] == "123"
        
        # Parse Array
        resp_arr = HTTP.Response(200, """[1, 2, 3]""")
        arr = parse_response_array(Int, resp_arr)
        @test length(arr) == 3
        @test arr[1] == 1
    end

    @testset "Response Parsing - Errors" begin
        # 400 Bad Request
        resp_400 = HTTP.Response(400, """{"code": 50001, "message": "Missing Access"}""")
        @test_throws ErrorException parse_response(Dict, resp_400)
        
        # 404 Not Found
        resp_404 = HTTP.Response(404, "Not Found")
        @test_throws ErrorException parse_response(Dict, resp_404)
        
        # 500 Server Error
        resp_500 = HTTP.Response(500, "Server Error")
        @test_throws ErrorException parse_response(Dict, resp_500)
    end
end
