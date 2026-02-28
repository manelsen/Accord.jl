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

    # Helper function
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

    @slash_command client begin
        name = "balance"
        description = "Check your current bank balance"
    end
    function balance_command(ctx)
        user_id = string(ctx.interaction.member.user.id)
        bal = get_balance(user_id)
        respond(ctx, content="💰 Your current balance is: **\$bal coins**.")
    end

    @slash_command client begin
        name = "daily"
        description = "Claim your daily reward"
    end
    function daily_command(ctx)
        # Check cooldown to prevent spam (requires state management, simplified here)
        user_id = string(ctx.interaction.member.user.id)
        
        # Add 100 coins
        add_balance(user_id, 100)
        bal = get_balance(user_id)
        
        respond(ctx, content="🎁 You claimed 100 daily coins! New balance: **\$bal coins**.")
    end

    println("💸 Economy module loaded.")
end
