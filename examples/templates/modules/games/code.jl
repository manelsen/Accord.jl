# Games Module
# Provides game-related utilities like server status and LFG (Looking for Group).

using Accord
using HTTP
using JSON3

function setup_games(client::Client)

    @slash_command client "mc_status" "Checks the status of a Minecraft server" [
        @option String "host" "Server IP" required=true
    ] function(ctx)
        host = Accord.get_option(ctx, "host")
        Accord.defer(ctx)

        try
            data = JSON3.read(HTTP.get("https://api.mcsrvstat.us/3/$(HTTP.escapeuri(host))").body)
            if data.online
                e = Accord.embed(
                    title="Minecraft Server: $host",
                    color=0x57F287,
                    thumbnail=Dict("url" => "https://api.mcsrvstat.us/icon/$(HTTP.escapeuri(host))"),
                    fields=[Accord.embed_field("Players", "$(data.players.online) / $(data.players.max)"; inline=true)],
                )
                Accord.respond(ctx; embeds=[e])
            else
                Accord.respond(ctx; content="❌ Server **$host** is offline.")
            end
        catch e
            @error "Minecraft status request failed" exception=e
            Accord.respond(ctx; content="❌ Could not fetch status.")
        end
    end

    @slash_command client "lfg" "Create a Looking for Group post" [
        @option String "game" "Game name" required=true
        @option String "description" "Details" required=true
    ] function(ctx)
        game = Accord.get_option(ctx, "game")
        desc = Accord.get_option(ctx, "description")

        e = Accord.embed(
            title="🎮 LFG: $game",
            description=desc,
            color=0x5865F2,
            author=Accord.embed_author("Requested by $(ctx.user.username)"),
        )
        btn = Accord.button(label="Join Group", style=ButtonStyles.SUCCESS, custom_id="lfg_join")
        Accord.respond(ctx; embeds=[e], components=[Accord.action_row([btn])])
    end

    @button_handler client "lfg_join" function(ctx)
        # `respond` would replace the LFG post; acknowledge the click and post a new message instead
        Accord.defer(ctx)
        Accord.followup(ctx; content="📢 **$(ctx.user.username)** wants to join!")
    end

    println("🎮 Games module loaded.")
end
