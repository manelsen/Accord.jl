@testitem "API surface" tags=[:unit] begin
    using Accord, HTTP, JSON3

    @testset "generic names are public but not exported" begin
        for name in (:start, :stop, :on, :respond, :defer, :followup, :target,
                     :button, :embed, :section, :container, :separator, :timestamp,
                     :connect!, :play!, :Optional, :Nullable, Symbol("@on"), Symbol("@embed"))
            @test !Base.isexported(Accord, name)
            @test Base.ispublic(Accord, name)
        end
    end

    @testset "Discord-specific names and the command DSL stay exported" begin
        for name in (:Client, :Snowflake, :MessageCreate, :create_message, :wait_for,
                     :edit_response, :show_modal, :sync_commands!,
                     Symbol("@slash_command"), Symbol("@option"), Symbol("@check"))
            @test Base.isexported(Accord, name)
        end
    end

    @testset "every REST endpoint is part of the public API" begin
        @test length(Accord.REST_ENDPOINTS) > 150
        for name in Accord.REST_ENDPOINTS
            @test Base.ispublic(Accord, name)
        end
    end

    @testset "every REST endpoint accepts a Client" begin
        for name in Accord.REST_ENDPOINTS
            f = getfield(Accord, name)
            @test hasmethod(f, Tuple{Client, Vararg{Any}})
        end
    end

    @testset "Client methods forward the rate limiter and token" begin
        client = Client("Bot fwd_token")
        captured = Ref{Any}(nothing)
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            captured[] = (method=m, url=u, headers=Dict(h))
            HTTP.Response(200, "[]")
        end
        Accord.start_ratelimiter!(client.ratelimiter)
        try
            rules = Accord.list_auto_moderation_rules(client, Snowflake(4242))
            @test rules isa Vector
            @test captured[].method == "GET"
            @test endswith(captured[].url, "/guilds/4242/auto-moderation/rules")
            @test captured[].headers["Authorization"] == "Bot fwd_token"
        finally
            Accord.stop_ratelimiter!(client.ratelimiter)
        end
    end
end
