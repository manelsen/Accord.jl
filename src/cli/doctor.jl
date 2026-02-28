# Environment diagnostics and health checks

using Sockets
using HTTP
using JSON3
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

    # 3. Environment & Token Validation
    print("Discord Token:  ")
    if haskey(ENV, "DISCORD_TOKEN")
        token = ENV["DISCORD_TOKEN"]
        # Ensure token has Bot prefix for the check
        actual_token = startswith(token, "Bot ") ? token : "Bot $token"
        
        try
            resp = HTTP.get("https://discord.com/api/v10/users/@me", 
                ["Authorization" => actual_token])
            user = JSON3.read(resp.body)
            println("VALID [OK]")
            println("  └─ Bot User:  $(user.username) ($(user.id))")
            println("  └─ Verified:  $(get(user, :verified, false))")
        catch e
            if e isa HTTP.ExceptionRequest.StatusError && e.status == 401
                println("INVALID [ERROR: 401 Unauthorized]")
            else
                println("Set [OK (Connectivity check failed)]")
            end
        end
    else
        println("NOT SET [ERROR]")
        if !isfile(".env")
            print("\n💡 Found missing .env file. Create one? [y/N]: ")
            ans = readline()
            if lowercase(strip(ans)) == "y"
                write(".env", "DISCORD_TOKEN=\"your_token_here\"\n")
                println("✅ Created .env template. Please fill it with your token.")
            end
        end
    end

    # 4. Voice Dependencies (Advanced)
    print("FFmpeg:         ")
    ffmpeg_path = Sys.which("ffmpeg")
    if isnothing(ffmpeg_path)
        println("NOT FOUND [WARNING: Voice features will not work]")
        println("  └─ Fix: Install ffmpeg (e.g., `sudo apt install ffmpeg` or `brew install ffmpeg`)")
    else
        # Check for libopus support
        try
            version_out = read(`ffmpeg -version`, String)
            if occursin("--enable-libopus", version_out) || occursin("libopus", version_out)
                println("Found at $ffmpeg_path [OK (libopus detected)]")
            else
                println("Found at $ffmpeg_path [WARNING: libopus support missing]")
            end
        catch
            println("Found at $ffmpeg_path [OK]")
        end
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

    # 6. Intent Reminder
    println("\n⚠️  Note: Remember to enable 'Privileged Gateway Intents'")
    println("   (Presence, Server Members, Message Content) in the Discord Developer Portal")
    println("   if your bot requires them.")

    println("-"^40)
    println("Check complete.")
end
