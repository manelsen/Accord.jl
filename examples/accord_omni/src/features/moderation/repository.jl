module Repository

using FunSQL
using FunSQL: From, Where, Select, Sort, Limit, render, Get, Agg, SQLCatalog, SQLTable, Group, As
using DBInterface
using SQLite

# Define Schema
const CATALOG = SQLCatalog(
    :moderation_cases => SQLTable(:moderation_cases, columns=[:case_id, :guild_id, :user_id, :moderator_id, :type, :reason, :created_at]);
    dialect = :sqlite
)

const mod_cases = From(:moderation_cases)

# --- Métodos Públicos (Interface) ---

function init_tables(db::SQLite.DB)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS moderation_cases (
            case_id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id INTEGER,
            user_id INTEGER,
            moderator_id INTEGER,
            type TEXT, -- 'BAN', 'KICK', 'WARN', 'MUTE'
            reason TEXT,
            created_at REAL
        );
    """)
end

function add_case(db, guild_id::Int, user_id::Int, moderator_id::Int, type::String, reason::String, ts::Float64)
    DBInterface.execute(db, 
        "INSERT INTO moderation_cases (guild_id, user_id, moderator_id, type, reason, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        [guild_id, user_id, moderator_id, type, reason, ts]
    )
    return SQLite.last_insert_rowid(db)
end

function get_user_history(db, guild_id::Int, user_id::Int, limit::Int=10)
    # Sem Sort por enquanto para garantir estabilidade
    q = mod_cases |>
        Where(Get.guild_id .== guild_id) |>
        Where(Get.user_id .== user_id) |>
        Limit(limit) |>
        Select(Get.case_id, Get.type, Get.reason, Get.moderator_id, Get.created_at)
    
    # Materialização Explícita e Segura
    results = []
    # Nota: Iteramos sobre o cursor para forçar leitura e conversão
    for row in DBInterface.execute(db, render(CATALOG, q))
        push!(results, (
            case_id = row.case_id,
            type = coalesce(row.type, "UNKNOWN"), 
            reason = coalesce(row.reason, "No reason provided"),
            moderator_id = row.moderator_id,
            created_at = coalesce(row.created_at, 0.0)
        ))
    end
    return results
end

function count_warns(db, guild_id::Int, user_id::Int)
    q = mod_cases |>
        Where(Get.guild_id .== guild_id) |>
        Where(Get.user_id .== user_id) |>
        Where(Get.type .== "WARN") |>
        Group(count=Agg.count())
        
    res = DBInterface.execute(db, render(CATALOG, q))
    
    for row in res
        return row.count
    end
    return 0
end

end
