# Environment diagnostics and health checks

using Sockets
using ..Accord: ACCORD_VERSION

function doctor_impl()
    println("🩺 Accord.jl Doctor — Diagnostic Report")
    println("-"^40)
    
    # 1. Julia Version
    print("Julia Version:  ")
    if VERSION >= v"1.11"
        println("v$VERSION [OK]")
    else
        println("v$VERSION [WARNING: Recommended 1.11+]")
    end

    # 2. Accord Version
    println("Accord.jl:      v$ACCORD_VERSION")

    # 3. Environment Variables
    print("Discord Token:  ")
    if haskey(ENV, "DISCORD_TOKEN")
        token = ENV["DISCORD_TOKEN"]
        if startswith(token, "Bot ") || length(token) > 50
            println("Set [OK]")
        else
            println("Set [WARNING: Token format looks suspicious]")
        end
    else
        println("NOT SET [ERROR]")
    end

    # 4. Voice Dependencies
    print("FFmpeg:         ")
    ffmpeg_path = Sys.which("ffmpeg")
    if isnothing(ffmpeg_path)
        println("NOT FOUND [WARNING: Voice features will not work]")
    else
        println("Found at $ffmpeg_path [OK]")
    end

    # 5. Connectivity
    print("Discord API:    ")
    try
        # Simple DNS check
        getaddrinfo("discord.com")
        println("Connected [OK]")
    catch
        println("UNREACHABLE [ERROR: Check your internet connection]")
    end

    println("-"^40)
    println("Check complete.")
end
