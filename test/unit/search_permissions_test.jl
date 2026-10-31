@testitem "Message search and computed permissions" tags=[:unit] begin
    using Accord, HTTP, JSON3
    using Accord: has_flag, PermViewChannel, PermSendMessages, PermAdministrator

    # A client whose requests go to `respond(method, url)` instead of Discord
    function with_client(f, respond)
        client = Client("Bot test_token_fake")
        calls = Tuple{String, String}[]
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            push!(calls, (m, u))
            respond(m, u)
        end
        Accord.start_ratelimiter!(client.ratelimiter)
        try
            f(client, calls)
        finally
            Accord.stop_ratelimiter!(client.ratelimiter)
        end
    end

    perms_json = """{"permissions": "$(PermViewChannel.value | PermSendMessages.value)"}"""

    @testset "computed permission endpoints" begin
        with_client((m, u) -> HTTP.Response(200, perms_json)) do client, calls
            g, c, u, r = Snowflake(1), Snowflake(2), Snowflake(3), Snowflake(4)
            p = Accord.get_guild_member_permissions(client, g, u)
            @test p isa Permissions
            @test has_flag(p, PermSendMessages) && !has_flag(p, PermAdministrator)
            Accord.get_guild_role_permissions(client, g, r)
            Accord.get_channel_member_permissions(client, c, u)
            Accord.get_channel_role_permissions(client, c, r; implicit=false)
            paths = [last(split(url, "/v10")) for (_, url) in calls]
            @test paths == ["/guilds/1/permissions/member/3", "/guilds/1/permissions/role/4",
                            "/channels/2/permissions/member/3", "/channels/2/permissions/role/4?implicit=false"]
            @test all(m == "GET" for (m, _) in calls)
        end
        with_client((m, u) -> HTTP.Response(403, """{"message": "Missing Access"}""")) do client, _
            @test_throws ErrorException Accord.get_guild_member_permissions(client, Snowflake(1), Snowflake(3))
        end
    end

    search_json = """
        {"doing_deep_historical_index": false, "total_results": 2,
         "messages": [[{"id": "10", "channel_id": "20", "content": "release notes v1"}],
                      [{"id": "11", "channel_id": "21", "content": "release notes v2"}]],
         "threads": [{"id": "21", "type": 11, "parent_id": "20"}], "members": []}"""

    @testset "search builds the query and flattens results" begin
        with_client((m, u) -> HTTP.Response(200, search_json)) do client, calls
            res = Accord.search_guild_messages(client, Snowflake(1); content="release notes",
                author_type="-bot", channel_id=[Snowflake(20), Snowflake(21)], has=["link", "-file"],
                pinned=false, sort_by="relevance", offset=25, max_id=nothing)
            @test res isa MessageSearchResults
            @test res.total_results == 2 && ismissing(res.retry_after)
            @test [m.content for m in Accord.found_messages(res)] == ["release notes v1", "release notes v2"]
            @test only(res.threads).id == Snowflake(21)

            url = only(calls)[2]
            @test startswith(url, Accord.API_BASE * "/guilds/1/messages/search?limit=25&")
            q = HTTP.URIs.queryparampairs(HTTP.URI(url))
            @test ("content" => "release notes") in q
            @test ("author_type" => "-bot") in q
            @test filter(p -> p.first == "channel_id", q) == ["channel_id" => "20", "channel_id" => "21"]
            @test filter(p -> p.first == "has", q) == ["has" => "link", "has" => "-file"]
            @test ("pinned" => "false") in q && ("sort_by" => "relevance") in q && ("offset" => "25") in q
            @test !any(p -> p.first == "max_id", q)
        end
    end

    @testset "unknown filters are rejected before any request" begin
        with_client((m, u) -> HTTP.Response(200, search_json)) do client, calls
            @test_throws ArgumentError Accord.search_guild_messages(client, Snowflake(1); author="x")
            @test isempty(calls)
        end
    end

    not_ready = """{"message": "Index not yet available. Try again later", "code": 110000,
                    "documents_indexed": 0, "retry_after": 0.01}"""

    @testset "index not ready: retried, then reported" begin
        n = Ref(0)
        with_client((m, u) -> (n[] += 1; n[] < 3 ? HTTP.Response(202, not_ready) : HTTP.Response(200, search_json))) do client, calls
            res = Accord.search_guild_messages(client, Snowflake(1); content="x")
            @test length(calls) == 3
            @test res.total_results == 2 && ismissing(res.retry_after)
        end
        with_client((m, u) -> HTTP.Response(202, not_ready)) do client, calls
            res = Accord.search_guild_messages(client, Snowflake(1); content="x", retries=1)
            @test length(calls) == 2
            @test res.retry_after == 0.01
            @test isempty(Accord.found_messages(res)) && res.total_results == 0
        end
    end
end
