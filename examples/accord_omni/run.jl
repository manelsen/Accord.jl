using Pkg
Pkg.activate(@__DIR__)

using Accord
using SQLite
using Dates

# Load local modules
include("src/core/types.jl")
include("src/core/database.jl")

# Load Features (Vertical Slices)
include("src/features/levels/mod.jl")
include("src/features/moderation/mod.jl")

using .CoreTypes
using .Database
using .Levels
using .Moderation

function main()
    token = get(ENV, "DISCORD_TOKEN", "")
    if isempty(token)
        println("Error: DISCORD_TOKEN not defined.")
        exit(1)
    end

    # 1. Initialize Core (DB)
    db_path = joinpath(@__DIR__, "data", "omni.db")
    db = Database.init_db(db_path)
    
    state = CoreTypes.OmniState(db, datetime2unix(now()))

    # 2. Initialize Client with State
    client = Client(token;
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
        state = state
    )

    # 3. Install Features (Plug-in architecture)
    Levels.install(client)
    Moderation.install(client)

    # 4. Global Events
    on(client, ReadyEvent) do c, event
        @info "Accord-Omni online as $(event.user.username)"
        sync_commands!(c) # Register commands from all installed features
    end

    # 5. Start
    start(client)
end

main()
