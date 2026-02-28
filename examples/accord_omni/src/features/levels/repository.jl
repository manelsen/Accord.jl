module Repository

using SQLite
using DBInterface

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

# --- Public Methods (Interface) ---

function get_user_xp(db, user_id, guild_id)
    row = DBInterface.execute(db, "SELECT xp FROM user_xp WHERE user_id = ? AND guild_id = ?", [user_id, guild_id]) |> first
    return ismissing(row) ? 0 : row.xp
end

function get_user_last_msg_ts(db, user_id, guild_id)
    row = DBInterface.execute(db, "SELECT last_message_ts FROM user_xp WHERE user_id = ? AND guild_id = ?", [user_id, guild_id]) |> first
    return ismissing(row) ? 0.0 : row.last_message_ts
end

function update_user_xp(db, user_id, guild_id, xp, ts)
    DBInterface.execute(db, """
        INSERT OR REPLACE INTO user_xp (user_id, guild_id, xp, last_message_ts)
        VALUES (?, ?, ?, ?)
    """, [user_id, guild_id, xp, ts])
end

function get_rank_position(db, guild_id, user_xp)
    # Count how many users have more XP in this guild
    row = DBInterface.execute(db, "SELECT COUNT(*) as rank FROM user_xp WHERE guild_id = ? AND xp > ?", [guild_id, user_xp]) |> first
    return row.rank + 1
end

end
