@testitem "Forum tag management (M4)" tags=[:unit] begin
    include("../integration/rest_test_utils.jl")
    using Accord
    import Accord: create_forum_tag, modify_forum_tag, delete_forum_tag

    @testset "modify_forum_tag: no keywords raises ArgumentError" begin
        rl = RateLimiter()
        @test_throws ArgumentError modify_forum_tag(rl, Snowflake(1), Snowflake(99);
            token="Bot x")
    end

    @testset "modify_forum_tag: accepts name keyword" begin
        handler, cap = capture_handler(mock_json(channel_json()))
        with_mock_rl(handler) do rl, token
            modify_forum_tag(rl, Snowflake(1), Snowflake(99); token, name="new-name")
        end
        @test cap[][1] == "PATCH"
    end

    @testset "create_forum_tag: reaches HTTP (not ArgumentError)" begin
        handler, cap = capture_handler(mock_json(channel_json()))
        with_mock_rl(handler) do rl, token
            create_forum_tag(rl, Snowflake(1); token, name="my-tag")
        end
        @test cap[][1] == "PATCH"
    end

    @testset "delete_forum_tag: reaches HTTP (not ArgumentError)" begin
        handler, cap = capture_handler(mock_json(channel_json()))
        with_mock_rl(handler) do rl, token
            delete_forum_tag(rl, Snowflake(1), Snowflake(99); token)
        end
        @test cap[][1] == "PATCH"
    end
end
