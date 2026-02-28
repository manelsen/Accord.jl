module Repository

using SQLite
using DBInterface
using Dates

function init_tables(db::SQLite.DB)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS mod_logs (
            case_id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id INTEGER,
            user_id INTEGER,
            moderator_id INTEGER,
            type TEXT, -- BAN, KICK, WARN
            reason TEXT,
            created_at INTEGER
        )
    """)
end

# --- Public Methods (Interface) ---

function insert_log(db, guild_id, user_id, moderator_id, type, reason)
    ts = Int(datetime2unix(now()))
    DBInterface.execute(db, """
        INSERT INTO mod_logs (guild_id, user_id, moderator_id, type, reason, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, [guild_id, user_id, moderator_id, type, reason, ts])
    
    return Int(SQLite.last_insert_rowid(db))
end

function fetch_logs(db, guild_id, user_id)
    cursor = DBInterface.execute(db, """
        SELECT * FROM mod_logs WHERE guild_id = ? AND user_id = ?
        ORDER BY created_at DESC
    """, [guild_id, user_id])
    
    # Safe and Explicit Materialization
    # Note: We iterate over the cursor to force reading and conversion
    return collect(cursor)
end

end
