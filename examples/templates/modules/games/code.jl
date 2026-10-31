# Games Module
# Provides game-related utilities like server status and LFG (Looking for Group).

using Accord
using HTTP
using JSON3

function setup_games(client::Client)

    @slash_command client "mc_status" "Checks the status of a Minecraft server" [
        @option String "host" "Server IP" required=true
    ] do ctx
        host = Accord.get_option(ctx, "host")
        Accord.defer(ctx)

        try
            resp = HTTP.get("https://api.mcsrvstat.us/2/$host")
            data = JSON3.read(resp.body)
            
            if data.online
                e = Accord.embed(
                    title="Minecraft Server: $host",
                    color=0x57F287,
                    thumbnail=Accord.thumbnail(url="https://api.mcsrvstat.us/icon/$host")
                )
                push!(e.fields, Accord.embed_field(name="Players", value="$(data.players.online) / $(data.players.max)", inline=true))
                Accord.followup(ctx, embeds=[e])
            else
                Accord.followup(ctx, content="❌ Server **$host** is offline.")
            end
        catch e
            Accord.followup(ctx, content="❌ Could not fetch status.")
        end
    end

    @slash_command client "lfg" "Create a Looking for Group post" [
        @option String "game" "Game name" required=true
        @option String "description" "Details" required=true
    ] do ctx
        game = Accord.get_option(ctx, "game")
        desc = Accord.get_option(ctx, "description")
        user = ctx.interaction.member.user.username

        e = Accord.embed(
            title="🎮 LFG: $game",
            description=desc,
            color=0x5865F2,
            author=Accord.embed_author(name="Requested by $user")
        )
        
        btn = Accord.button(label="Join Group", style=ButtonStyles.SUCCESS, custom_id="lfg_join")
        Accord.respond(ctx, embeds=[e], components=[Accord.action_row([btn])])
    end

    @button_handler client "lfg_join" function(ctx)
        user = ctx.interaction.member.user.username
        Accord.respond(ctx, content="📢 **$user** wants to join!", flags=MsgFlagEphemeral)
    end

    println("🎮 Games module loaded.")
end
