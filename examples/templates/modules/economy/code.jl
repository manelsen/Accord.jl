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

    # Local helper functions
    function add_balance(user_id::String, amount::Int)
        DBInterface.execute(db, "INSERT INTO users (id, balance) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET balance = balance + ?", (user_id, amount, amount))
    end

    function get_balance(user_id::String)
        results = DBInterface.execute(db, "SELECT balance FROM users WHERE id = ?", (user_id,))
        for row in results
            return row.balance
        end
        return 0
    end

    @slash_command client "balance" "Check your current bank balance" do ctx
        user_id = string(ctx.interaction.member.user.id)
        bal = get_balance(user_id)
        respond(ctx, content="💰 Your current balance is: **$bal coins**.")
    end

    @slash_command client "daily" "Claim your daily reward" do ctx
        user_id = string(ctx.interaction.member.user.id)
        add_balance(user_id, 100)
        bal = get_balance(user_id)
        respond(ctx, content="🎁 You claimed 100 daily coins! New balance: **$bal coins**.")
    end

    println("💸 Economy module loaded.")
end
