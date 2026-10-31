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
    # Adjust intents based on the modules you use. Message Content is privileged:
    # enable it in the Developer Portal, or drop it if no module reads messages.
    client = Client(token;
        intents = IntentGuilds | IntentGuildMessages | IntentMessageContent |
                  Accord.IntentGuildMessageReactions | Accord.IntentGuildVoiceStates
    )

    # 2. Setup core event handlers
    Accord.on(client, ReadyEvent) do c, event
        println("Bot is ready! Logged in as: $(event.user.username)")
        # Synchronize application commands with Discord
        sync_commands!(c, c.command_tree)
    end

    # === Module Setups ===
    {{MODULE_SETUPS}}

    # 3. Start the gateway connection; this blocks until the bot is stopped (Ctrl-C)
    println("Starting Accord.jl client...")
    Accord.start(client)
end

end # module
