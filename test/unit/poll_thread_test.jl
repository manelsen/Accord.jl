@testitem "create_poll and modify_thread (M3)" tags=[:unit] begin
    include("../integration/rest_test_utils.jl")
    using Accord
    import Accord: create_poll, modify_thread

    # ── create_poll contract tests (no HTTP needed) ──────────────────────────

    @testset "create_poll: empty answers raises ArgumentError" begin
        rl = RateLimiter()
        @test_throws ArgumentError create_poll(rl, Snowflake(1);
            token="Bot x", question="Q?", answers=String[])
    end

    @testset "create_poll: duration_hours < 1 raises ArgumentError" begin
        rl = RateLimiter()
        @test_throws ArgumentError create_poll(rl, Snowflake(1);
            token="Bot x", question="Q?", answers=["A"], duration_hours=0)
    end

    @testset "create_poll: duration_hours > 168 raises ArgumentError" begin
        rl = RateLimiter()
        @test_throws ArgumentError create_poll(rl, Snowflake(1);
            token="Bot x", question="Q?", answers=["A"], duration_hours=169)
    end

    # ── modify_thread contract tests (no HTTP needed) ────────────────────────

    @testset "modify_thread: no keywords raises ArgumentError" begin
        rl = RateLimiter()
        @test_throws ArgumentError modify_thread(rl, Snowflake(1); token="Bot x")
    end

    @testset "modify_thread: accepts name keyword" begin
        handler, _ = capture_handler(mock_json(channel_json()))
        with_mock_rl(handler) do rl, token
            result = modify_thread(rl, Snowflake(1); token, name="new-name")
            @test result isa DiscordChannel
        end
    end

    @testset "modify_thread: accepts archived keyword" begin
        handler, _ = capture_handler(mock_json(channel_json()))
        with_mock_rl(handler) do rl, token
            result = modify_thread(rl, Snowflake(1); token, archived=true)
            @test result isa DiscordChannel
        end
    end
end
