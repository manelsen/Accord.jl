@testitem "REST Misc Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP, JSON3
    using Accord: Connection, Integration, WelcomeScreen, Onboarding, SoundboardSound, SKU, Entitlement, Subscription, parse_response, parse_response_array, url, API_BASE

    @testset "Emoji Endpoints" begin
        g_id = Snowflake(200)
        e_id = Snowflake(700)

        @testset "list_guild_emojis" begin
            handler, cap = capture_handler(mock_json([emoji_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_guild_emojis(rl, g_id; token)
                @test result isa Vector{Emoji}
                @test cap[][1] == "GET"
            end
        end

        @testset "get_guild_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_emoji(rl, g_id, e_id; token)
                @test result isa Emoji
                @test cap[][1] == "GET"
            end
        end

        @testset "create_guild_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_emoji(rl, g_id; token, body=Dict("name" => "test", "image" => "data:..."))
                @test result isa Emoji
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_guild_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_emoji(rl, g_id, e_id; token, body=Dict("name" => "renamed"))
                @test result isa Emoji
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_emoji" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_emoji(rl, g_id, e_id; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "list_application_emojis" begin
            handler, cap = capture_handler(mock_json(Dict("items" => [emoji_json()])))
            with_mock_rl(handler) do rl, token
                result = Accord.list_application_emojis(rl, Snowflake(1000); token)
                @test result isa Dict
                @test cap[][1] == "GET"
            end
        end

        @testset "get_application_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_application_emoji(rl, Snowflake(1000), e_id; token)
                @test result isa Emoji
                @test cap[][1] == "GET"
            end
        end

        @testset "create_application_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_application_emoji(rl, Snowflake(1000); token, body=Dict("name" => "test", "image" => "data:..."))
                @test result isa Emoji
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_application_emoji" begin
            handler, cap = capture_handler(mock_json(emoji_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_application_emoji(rl, Snowflake(1000), e_id; token, body=Dict("name" => "renamed"))
                @test result isa Emoji
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_application_emoji" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_application_emoji(rl, Snowflake(1000), e_id; token)
                @test cap[][1] == "DELETE"
            end
        end
    end

    @testset "Sticker Endpoints" begin
        g_id = Snowflake(200)
        s_id = Snowflake(800)

        @testset "get_sticker" begin
            handler, cap = capture_handler(mock_json(sticker_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_sticker(rl, s_id; token)
                @test result isa Sticker
                @test cap[][1] == "GET"
            end
        end

        @testset "list_sticker_packs" begin
            handler, cap = capture_handler(mock_json(Dict("sticker_packs" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.list_sticker_packs(rl; token)
                @test result isa Dict
                @test cap[][1] == "GET"
            end
        end

        @testset "list_guild_stickers" begin
            handler, cap = capture_handler(mock_json([sticker_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_guild_stickers(rl, g_id; token)
                @test result isa Vector{Sticker}
                @test cap[][1] == "GET"
            end
        end

        @testset "get_guild_sticker" begin
            handler, cap = capture_handler(mock_json(sticker_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_sticker(rl, g_id, s_id; token)
                @test result isa Sticker
                @test cap[][1] == "GET"
            end
        end

        @testset "modify_guild_sticker" begin
            handler, cap = capture_handler(mock_json(sticker_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_sticker(rl, g_id, s_id; token, body=Dict("name" => "renamed"))
                @test result isa Sticker
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_sticker" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_sticker(rl, g_id, s_id; token)
                @test cap[][1] == "DELETE"
            end
        end
    end

    @testset "Invite Endpoints" begin
        @testset "get_invite" begin
            handler, cap = capture_handler(mock_json(invite_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_invite(rl, "abc123"; token)
                @test result isa Invite
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/invites/abc123")
            end
        end

        @testset "delete_invite" begin
            handler, cap = capture_handler(mock_json(invite_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.delete_invite(rl, "abc123"; token)
                @test result isa Invite
                @test cap[][1] == "DELETE"
            end
        end
    end

    @testset "Audit Log Endpoints" begin
        @testset "get_guild_audit_log" begin
            handler, cap = capture_handler(mock_json(audit_log_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_audit_log(rl, Snowflake(200); token)
                @test result isa AuditLog
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/guilds/200/audit-logs")
            end
        end
    end

    @testset "AutoMod Endpoints" begin
        g_id = Snowflake(200)
        rule_id = Snowflake(1100)

        @testset "list_auto_moderation_rules" begin
            handler, cap = capture_handler(mock_json([automod_rule_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_auto_moderation_rules(rl, g_id; token)
                @test result isa Vector{AutoModRule}
                @test cap[][1] == "GET"
            end
        end

        @testset "get_auto_moderation_rule" begin
            handler, cap = capture_handler(mock_json(automod_rule_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_auto_moderation_rule(rl, g_id, rule_id; token)
                @test result isa AutoModRule
                @test cap[][1] == "GET"
            end
        end

        @testset "create_auto_moderation_rule" begin
            handler, cap = capture_handler(mock_json(automod_rule_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_auto_moderation_rule(rl, g_id; token, body=Dict("name" => "rule"))
                @test result isa AutoModRule
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_auto_moderation_rule" begin
            handler, cap = capture_handler(mock_json(automod_rule_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_auto_moderation_rule(rl, g_id, rule_id; token, body=Dict("name" => "updated"))
                @test result isa AutoModRule
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_auto_moderation_rule" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_auto_moderation_rule(rl, g_id, rule_id; token)
                @test cap[][1] == "DELETE"
            end
        end
    end
end
