@testset "Snowflake" begin
    @testset "Construction" begin
        s1 = Snowflake(123456789)
        @test s1.value == 123456789

        s2 = Snowflake("123456789")
        @test s2.value == 123456789

        s3 = Snowflake(UInt64(999))
        @test s3.value == 999

        # Identity
        s4 = Snowflake(s1)
        @test s4 == s1
    end

    @testset "Comparison" begin
        a = Snowflake(100)
        b = Snowflake(200)
        @test a < b
        @test a == Snowflake(100)
        @test a != b
    end

    @testset "Hashing" begin
        s = Snowflake(12345)
        d = Dict(s => "test")
        @test d[Snowflake(12345)] == "test"
    end

    @testset "Timestamp extraction" begin
        # Discord epoch: 2015-01-01T00:00:00.000Z
        s = Snowflake(UInt64(0))
        ts = Accord.timestamp(s)
        @test Dates.year(ts) == 2015
        @test Dates.month(ts) == 1
        @test Dates.day(ts) == 1

        # A known snowflake: 175928847299117063 (created ~2016)
        s2 = Snowflake(175928847299117063)
        ts2 = Accord.timestamp(s2)
        @test Dates.year(ts2) == 2016
    end

    @testset "Worker/Process/Increment" begin
        s = Snowflake(175928847299117063)
        @test Accord.worker_id(s) isa Integer
        @test Accord.process_id(s) isa Integer
        @test Accord.increment(s) isa Integer
    end

    @testset "String conversion" begin
        s = Snowflake(12345)
        @test string(s) == "12345"
    end

    @testset "JSON round-trip" begin
        s = Snowflake(175928847299117063)
        json_str = JSON3.write(s)
        @test json_str == "\"175928847299117063\""

        s2 = JSON3.read(json_str, Snowflake)
        @test s2 == s
    end
end
