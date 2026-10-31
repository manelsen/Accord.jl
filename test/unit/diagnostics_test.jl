@testitem "Diagnostics for HTTP responses" tags=[:unit] begin
    using Accord, HTTP, JSON3
    const D = Accord.Diagnoser

    @testset "known Discord error codes are diagnosed from a response" begin
        resp = HTTP.Response(403, JSON3.write(Dict("code" => 50013, "message" => "Missing Permissions")))
        diag = D.diagnose(resp, nothing)
        @test diag isa D.Diagnostic
        @test occursin("50013", diag.title)

        resp = HTTP.Response(400, JSON3.write(Dict("code" => 50035, "errors" => Dict("content" => "too long"))))
        @test occursin("50035", D.diagnose(resp, nothing).title)
    end

    @testset "429 responses are diagnosed" begin
        resp = HTTP.Response(429, JSON3.write(Dict("retry_after" => 2.5)))
        diag = D.diagnose(resp, nothing)
        @test diag isa D.Diagnostic
        @test occursin("429", diag.title)
    end

    @testset "unknown errors and non-object bodies are ignored" begin
        @test D.diagnose(HTTP.Response(500, "Internal Server Error"), nothing) === nothing
        @test D.diagnose(HTTP.Response(400, "[1,2,3]"), nothing) === nothing
        @test D.diagnose(HTTP.Response(404, ""), nothing) === nothing
    end
end
