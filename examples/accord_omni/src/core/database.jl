module Database

using SQLite
using DBInterface

function init_db(path::String)
    db = SQLite.DB(path)
    
    # Habilita chaves estrangeiras
    DBInterface.execute(db, "PRAGMA foreign_keys = ON;")
    
    # Cria tabela de configuração de guildas (Exemplo Core)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS guild_configs (
            guild_id INTEGER PRIMARY KEY,
            prefix TEXT DEFAULT '!',
            language TEXT DEFAULT 'en'
        );
    """)
    
    return db
end

end
