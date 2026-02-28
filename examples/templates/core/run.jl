# Main entry point for the bot

using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using DotEnv
DotEnv.config()

include("src/{{BOT_NAME}}.jl")

# Read token from environment
token = get(ENV, "DISCORD_TOKEN", "")
if isempty(token) || token == "your_token_here"
    error("Please set a valid DISCORD_TOKEN in the .env file or environment.")
end

# Start the bot
{{BOT_NAME}}.run(token)
