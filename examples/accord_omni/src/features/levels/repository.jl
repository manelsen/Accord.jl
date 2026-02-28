module Repository

using FunSQL
using FunSQL: From, Where, Select, Agg, render, Get, SQLCatalog, SQLTable, Group, As
using DBInterface
using SQLite

# Define the Schema manually
const CATALOG = SQLCatalog(
    :user_xp => SQLTable(:user_xp, columns=[:user_id, :guild_id, :xp, :last_message_ts]);
    dialect = :sqlite
)

const user_xp = From(:user_xp)

# --- Métodos Públicos (Interface) ---

function init_tables(db::SQLite.DB)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS user_xp (
            user_id INTEGER,
            guild_id INTEGER,
            xp INTEGER DEFAULT 0,
            last_message_ts REAL DEFAULT 0,
            PRIMARY KEY (user_id, guild_id)
        );
    """)
end

function get_entry(db, user_id::Int, guild_id::Int)
    # Pipeline de Where
    q = user_xp |>
        Where(Get.user_id .== user_id) |>
        Where(Get.guild_id .== guild_id) |>
        Select(Get.xp, Get.last_message_ts)
    
    # Renderiza com catálogo explícito
    sql = render(CATALOG, q)
    
    res = DBInterface.execute(db, sql)
    for row in res
        return (xp=row.xp, last_ts=row.last_message_ts)
    end
    return nothing
end

function update_xp(db, user_id::Int, guild_id::Int, new_xp::Int, new_ts::Float64)
    # Para UPDATE simples, mantemos SQL direto
    DBInterface.execute(db, 
        "UPDATE user_xp SET xp = ?, last_message_ts = ? WHERE user_id = ? AND guild_id = ?",
        [new_xp, new_ts, user_id, guild_id]
    )
end

function create_entry(db, user_id::Int, guild_id::Int, initial_xp::Int, ts::Float64)
    DBInterface.execute(db,
        "INSERT INTO user_xp (user_id, guild_id, xp, last_message_ts) VALUES (?, ?, ?, ?)",
        [user_id, guild_id, initial_xp, ts]
    )
end

function get_rank(db, user_id::Int, guild_id::Int)
    entry = get_entry(db, user_id, guild_id)
    if isnothing(entry) return (0, 0) end
    
    # Group() vazio cria agregação global
    q = user_xp |>
        Where(Get.guild_id .== guild_id) |>
        Where(Get.xp .> entry.xp) |>
        Group() |>
        Select(Agg.count() |> As(:cnt))
        
    res = DBInterface.execute(db, render(CATALOG, q))
    rank_above = 0
    for row in res
        rank_above = row.cnt
    end
    
    return (entry.xp, rank_above + 1)
end

end
