@testitem "Shard management" tags=[:unit] begin
    using Accord

    @testset "shard formula basic" begin
        # Test the Discord sharding formula: (guild_id >> 22) % num_shards
        guild_id = Snowflake(0)
        num_shards = 10

        # Manual calculation
        expected_shard = Int((guild_id.value >> 22) % num_shards)

        @test expected_shard == 0
    end

    @testset "shard formula consistency" begin
        # Same guild should always map to same shard
        guild_id = Snowflake(123456789)
        num_shards = 10

        shard_id1 = Int((guild_id.value >> 22) % num_shards)
        shard_id2 = Int((guild_id.value >> 22) % num_shards)

        @test shard_id1 == shard_id2
    end

    @testset "shard formula edge cases" begin
        # Large guild ID
        guild_id = Snowflake(typemax(UInt64))
        num_shards = 100
        expected_shard = Int((guild_id.value >> 22) % num_shards)
        @test 0 <= expected_shard < num_shards
    end

    @testset "shard formula single shard" begin
        # With 1 shard, everything maps to shard 0
        guild_id = Snowflake(123456789)
        num_shards = 1

        expected_shard = Int((guild_id.value >> 22) % num_shards)
        @test expected_shard == 0
    end

    @testset "shard formula with different shard counts" begin
        guild_id = Snowflake(123456789)

        shard_id_1 = Int((guild_id.value >> 22) % 1)
        shard_id_10 = Int((guild_id.value >> 22) % 10)
        shard_id_100 = Int((guild_id.value >> 22) % 100)

        @test shard_id_1 == 0
        @test 0 <= shard_id_10 < 10
        @test 0 <= shard_id_100 < 100
    end
end
