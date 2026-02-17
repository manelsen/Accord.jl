using Pkg
Pkg.activate(@__DIR__)

using Accord
using SQLite
using Dates

# Carrega módulos locais
include("src/core/types.jl")
include("src/core/database.jl")

# Carrega Features (Vertical Slices)
include("src/features/levels/mod.jl")
include("src/features/moderation/mod.jl")

using .CoreTypes
using .Database
using .Levels
using .Moderation

function main()
    token = get(ENV, "DISCORD_TOKEN", "")
    if isempty(token)
        println("Erro: DISCORD_TOKEN não definido.")
        exit(1)
    end

    # 1. Inicializa Core (DB)
    db_path = joinpath(@__DIR__, "data", "omni.db")
    db = Database.init_db(db_path)
    
    state = CoreTypes.OmniState(db, datetime2unix(now()))

    # 2. Inicializa Client com Estado
    client = Client(token;
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
        state = state
    )

    # 3. Instala Features (Plug-in architecture)
    Levels.install(client)
    Moderation.install(client)

    # 4. Eventos Globais
    on(client, ReadyEvent) do c, event
        @info "Accord-Omni online como $(event.user.username)"
        sync_commands!(c) # Registra comandos de todas as features instaladas
    end

    # 5. Start
    start(client)
end

main()
