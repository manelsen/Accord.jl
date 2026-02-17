using Test
using SQLite
using Dates

# Carrega os módulos do projeto (ajustando paths relativos)
include("../src/core/types.jl")
include("../src/core/database.jl")

# Envelopa em módulos para evitar colisão de nomes (já que ambos usam "Repository" e "Service")
module Levels
    include("../src/features/levels/repository.jl")
    include("../src/features/levels/service.jl")
end

module Moderation
    include("../src/features/moderation/repository.jl")
    include("../src/features/moderation/service.jl")
end

# Atalhos
using .Levels
using .Moderation

@testset "Accord-Omni Architecture Tests" begin

    # Setup: Banco em memória para testes rápidos e isolados
    db = SQLite.DB(":memory:")
    
    # Inicializa Schemas
    Levels.Repository.init_tables(db)
    Moderation.Repository.init_tables(db)

    @testset "Feature: Levels" begin
        user_id = 123
        guild_id = 456
        
        # 1. Primeiro XP
        xp = Levels.Service.process_xp(db, user_id, guild_id)
        @test xp == 15
        
        # 2. Cooldown (Imediato)
        xp_cooldown = Levels.Service.process_xp(db, user_id, guild_id)
        @test isnothing(xp_cooldown) # Deve retornar nothing por estar em cooldown
        
        # 3. Hack no DB para pular o tempo (Testando Repositório direto)
        Levels.Repository.update_xp(db, user_id, guild_id, 15, datetime2unix(now() - Second(70)))
        
        # 4. XP após Cooldown
        xp_new = Levels.Service.process_xp(db, user_id, guild_id)
        @test xp_new == 30
        
        # 5. Rank
        entry = Levels.Repository.get_rank(db, user_id, guild_id)
        @test entry[1] == 30 # XP Total
        @test entry[2] == 1  # Rank #1
    end

    @testset "Feature: Moderation" begin
        guild_id = 1001
        user_id = 2002
        mod_id = 3003
        
        # 1. Automod Logic
        @test Moderation.Service.check_automod("Hello world") == false
        @test Moderation.Service.check_automod("Don't spam please") == true
        
        # 2. Log Action
        case_id = Moderation.Service.log_action(db, guild_id, user_id, mod_id, "WARN", "Spamming")
        @test case_id == 1
        
        # 3. Retrieve History
        history = Moderation.Service.get_history(db, guild_id, user_id) |> collect
        
        @test length(history) == 1
        @test history[1].reason == "Spamming"
        @test history[1].type == "WARN"
    end
    
    close(db)
end
