# Economy Module
# Provides a simple SQLite-backed economy system.

using Accord
using SQLite
using DBInterface

function setup_economy(client::Client)
    # Ensure database exists
    db = SQLite.DB("economy.sqlite")
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            balance INTEGER DEFAULT 0
        )
    """)
    # Handlers run in parallel, and one SQLite connection must not be used by two threads at once
    db_lock = ReentrantLock()

    add_balance(user_id::String, amount::Int) = lock(db_lock) do
        DBInterface.execute(db,
            "INSERT INTO users (id, balance) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET balance = balance + ?",
            (user_id, amount, amount))
    end

    get_balance(user_id::String) = lock(db_lock) do
        for row in DBInterface.execute(db, "SELECT balance FROM users WHERE id = ?", (user_id,))
            return row.balance
        end
        return 0
    end

    @slash_command client "balance" "Check your current bank balance" function(ctx)
        bal = get_balance(string(ctx.user.id))
        Accord.respond(ctx; content="💰 Your current balance is: **$bal coins**.")
    end

    @slash_command client "daily" "Claim your daily reward" function(ctx)
        user_id = string(ctx.user.id)
        add_balance(user_id, 100)
        bal = get_balance(user_id)
        Accord.respond(ctx; content="🎁 You claimed 100 daily coins! New balance: **$bal coins**.")
    end

    println("💸 Economy module loaded.")
end
