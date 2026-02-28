using Accord
using DotEnv

# Load environment variables from .env file (if it exists)
DotEnv.config()

# Bot Token
const TOKEN = get(ENV, "DISCORD_TOKEN", "")

if isempty(TOKEN)
    println("Error: DISCORD_TOKEN not found. Create a .env file or set the environment variable.")
    exit(1)
end

# Initialize Client
# Basic Intents: Guilds (for slash commands)
client = Client(TOKEN; intents = IntentGuilds)

# --- Events ---

on(client, ReadyEvent) do c, event
    @info "Bot connected! Logged in as $(event.user.username)"
    
    # Register slash commands defined below
    # In production, you might want to register globally (may take 1h)
    # or per guild (immediate) by passing guild_id=...
    sync_commands!(c)
end

# --- Commands ---

@slash_command client "ping" "Check bot latency" function(ctx)
    # Respond to interaction
    respond(ctx; content="Pong! 🏓")
end

@slash_command client "hello" "Say hello to the user" function(ctx)
    user = ctx.user
    respond(ctx; content="Hello, **$(user.username)**! Welcome to Accord.jl.")
end

# --- Execution ---

@info "Starting the bot..."
start(client)
