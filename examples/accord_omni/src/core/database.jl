module Database

using Accord
using SQLite

function init_db(path::String)
    db = SQLite.DB(path)
    
    # Create guild configuration table (Core Example)
    SQLite.execute(db, """
        CREATE TABLE IF NOT EXISTS guild_config (
            guild_id INTEGER PRIMARY KEY,
            prefix TEXT DEFAULT '!',
            welcome_channel_id INTEGER
        )
    """)
    
    return db
end

end
