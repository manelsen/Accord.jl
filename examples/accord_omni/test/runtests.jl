using Test
using SQLite
using Dates
using Accord

# Load project modules (adjusting relative paths)
include("../run.jl")

# Wrap in modules to avoid name collisions (since both use "Repository" and "Service")
module TestLevels
    using Test
    using SQLite
    using Dates
    using Accord
    include("../src/features/levels/mod.jl")
    
    # Setup: In-memory DB for fast and isolated tests
    db = SQLite.DB()
    
    @testset "Levels System" begin
        Levels.Repository.init_tables(db)
        
        # 1. First XP
        new_xp = Levels.Service.process_xp(db, 123, 456)
        @test new_xp == 15
        
        # 2. Cooldown
        @test isnothing(Levels.Service.process_xp(db, 123, 456))
        
        # 3. DB Hack to skip time (Testing Repository directly)
        Levels.Repository.update_user_xp(db, 123, 456, 15, 0.0)
        
        # 4. XP after Cooldown
        @test Levels.Service.process_xp(db, 123, 456) == 30
        
        # 5. Ranking
        Levels.Repository.update_user_xp(db, 999, 456, 100, datetime2unix(now()))
        xp, pos = Levels.Service.get_user_rank(db, 123, 456)
        @test xp == 30
        @test pos == 2
    end
end

@testset "Omni System Integration" begin
    # Test if features install correctly without errors
    db = SQLite.DB()
    client = Client("token"; state=CoreTypes.OmniState(db, 0.0))
    
    @test_nowarn Levels.install(client)
    @test_nowarn Moderation.install(client)
end
