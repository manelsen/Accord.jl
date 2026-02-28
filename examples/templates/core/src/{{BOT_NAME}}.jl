module {{BOT_NAME}}

using Accord

# === Module Injections ===
{{MODULE_INCLUDES}}

"""
    run(token::String)

Initializes and starts the Discord bot.
"""
function run(token::String)
    # 1. Create the client with necessary intents
    # Adjust intents based on the modules you use
    client = Client(token; 
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent | IntentGuildMembers
    )

    # 2. Setup core event handlers
    on(client, ReadyEvent) do c, event
        println("Bot is ready! Logged in as: \$(event.user.username)")
        # Synchronize application commands with Discord
        sync_commands!(c, c.command_tree)
    end

    # === Module Setups ===
    {{MODULE_SETUPS}}

    # 3. Start the gateway connection
    println("Starting Accord.jl client...")
    start(client)
    
    # Wait indefinitely (to keep the main thread alive)
    wait(client.ready)
    # To keep process alive after ready
    wait()
end

end # module
