@testitem "REST Monetization and Template Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP, JSON3
    using Accord: Connection, Integration, WelcomeScreen, Onboarding, SoundboardSound, SKU, Entitlement, Subscription, parse_response, parse_response_array, url, API_BASE

    @testset "SKU/Entitlement/Subscription Endpoints" begin
        app_id = Snowflake(1000)
        sku_id = Snowflake(1700)
        ent_id = Snowflake(1800)

        @testset "list_skus" begin
            handler, cap = capture_handler(mock_json([sku_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_skus(rl, app_id; token)
                @test result isa Vector{SKU}
                @test cap[][1] == "GET"
            end
        end

        @testset "list_entitlements" begin
            handler, cap = capture_handler(mock_json([entitlement_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_entitlements(rl, app_id; token)
                @test result isa Vector{Entitlement}
                @test cap[][1] == "GET"
            end
        end

        @testset "create_test_entitlement" begin
            handler, cap = capture_handler(mock_json(entitlement_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_test_entitlement(rl, app_id; token, body=Dict("sku_id" => "1700", "owner_id" => "100", "owner_type" => 2))
                @test result isa Entitlement
                @test cap[][1] == "POST"
            end
        end

        @testset "delete_test_entitlement" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_test_entitlement(rl, app_id, ent_id; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "consume_entitlement" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.consume_entitlement(rl, app_id, ent_id; token)
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/consume")
            end
        end

        @testset "get_entitlement" begin
            handler, cap = capture_handler(mock_json(entitlement_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_entitlement(rl, app_id, ent_id; token)
                @test result isa Entitlement
                @test cap[][1] == "GET"
            end
        end

        @testset "list_sku_subscriptions" begin
            handler, cap = capture_handler(mock_json([subscription_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_sku_subscriptions(rl, sku_id; token)
                @test result isa Vector{Subscription}
                @test cap[][1] == "GET"
            end
        end

        @testset "get_sku_subscription" begin
            handler, cap = capture_handler(mock_json(subscription_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_sku_subscription(rl, sku_id, Snowflake(1900); token)
                @test result isa Subscription
                @test cap[][1] == "GET"
            end
        end
    end

    @testset "Guild Template Endpoints" begin
        g_id = Snowflake(200)

        @testset "get_guild_templates" begin
            handler, cap = capture_handler(mock_json([guild_template_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_templates(rl, g_id; token)
                @test result isa Vector{GuildTemplate}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/templates")
            end
        end

        @testset "create_guild_template" begin
            handler, cap = capture_handler(mock_json(guild_template_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_template(rl, g_id; token, body=Dict("name" => "Template"))
                @test result isa GuildTemplate
                @test cap[][1] == "POST"
            end
        end

        @testset "sync_guild_template" begin
            handler, cap = capture_handler(mock_json(guild_template_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.sync_guild_template(rl, g_id, "abc"; token)
                @test result isa GuildTemplate
                @test cap[][1] == "PUT"
            end
        end

        @testset "modify_guild_template" begin
            handler, cap = capture_handler(mock_json(guild_template_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_template(rl, g_id, "abc"; token, body=Dict("name" => "Updated"))
                @test result isa GuildTemplate
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_template" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_template(rl, g_id, "abc"; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "create_guild_from_template" begin
            handler, cap = capture_handler(mock_json(guild_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_from_template(rl, "abc"; token, body=Dict("name" => "New Guild"))
                @test result isa Guild
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/guilds/templates/abc")
            end
        end
    end
end
