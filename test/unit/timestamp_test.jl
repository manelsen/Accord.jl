@testitem "Timestamp auto-conversion (M1)" tags=[:unit] begin
    using Accord
    import Accord: parse_timestamp
    using Dates

    @testset "parse_timestamp: millisecond precision" begin
        dt = parse_timestamp("2024-01-15T10:30:00.123456+00:00")
        @test dt isa DateTime
        @test year(dt) == 2024
        @test month(dt) == 1
        @test day(dt) == 15
        @test hour(dt) == 10
        @test minute(dt) == 30
        @test second(dt) == 0
        @test millisecond(dt) == 123  # sub-ms precision truncated
    end

    @testset "parse_timestamp: no fractions" begin
        dt = parse_timestamp("2024-06-01T08:00:00+00:00")
        @test dt isa DateTime
        @test dt == DateTime(2024, 6, 1, 8, 0, 0)
    end

    @testset "parse_timestamp: Z suffix" begin
        dt = parse_timestamp("2024-01-15T10:30:00Z")
        @test dt isa DateTime
        @test dt == DateTime(2024, 1, 15, 10, 30, 0)
    end

    @testset "parse_timestamp: missing input" begin
        @test parse_timestamp(missing) === missing
    end

    @testset "parse_timestamp: empty string" begin
        @test parse_timestamp("") === missing
    end

    @testset "parse_timestamp: malformed string" begin
        result = parse_timestamp("not-a-timestamp")
        @test result === missing
    end

    @testset "Message.timestamp returns DateTime" begin
        msg = Message(timestamp="2024-01-15T10:30:00.000000+00:00")
        @test msg.timestamp isa DateTime
        @test msg.timestamp == DateTime(2024, 1, 15, 10, 30, 0)
    end

    @testset "Message.edited_timestamp returns DateTime" begin
        msg = Message(edited_timestamp="2024-03-20T12:00:00+00:00")
        @test msg.edited_timestamp isa DateTime
    end

    @testset "Message.timestamp missing when not set" begin
        msg = Message()
        @test ismissing(msg.timestamp)
    end

    @testset "Member.joined_at returns DateTime" begin
        m = Member(joined_at="2023-05-10T15:00:00.000000+00:00")
        @test m.joined_at isa DateTime
        @test year(m.joined_at) == 2023
    end

    @testset "Poll.expiry returns DateTime" begin
        poll = Poll(expiry="2025-12-31T23:59:59.000000+00:00")
        @test poll.expiry isa DateTime
    end

    @testset "Poll.expiry missing when not set" begin
        poll = Poll()
        @test ismissing(poll.expiry)
    end

    @testset "JSON roundtrip: raw field stays String, access returns DateTime" begin
        import JSON3
        json = """{"id":"123","channel_id":"456","timestamp":"2024-01-15T10:30:00.000000+00:00","type":0}"""
        msg = JSON3.read(json, Message)
        # Internal storage: still a String (JSON3 uses getfield, not getproperty)
        @test getfield(msg, :timestamp) isa String
        # User-facing access: DateTime
        @test msg.timestamp isa DateTime
        @test msg.timestamp == DateTime(2024, 1, 15, 10, 30, 0)
    end

    @testset "JSON roundtrip: serialization preserves ISO8601 String" begin
        import JSON3
        msg = Message(timestamp="2024-01-15T10:30:00.000000+00:00")
        json = JSON3.write(msg)
        @test occursin("2024-01-15T10:30:00", json)
    end
end
