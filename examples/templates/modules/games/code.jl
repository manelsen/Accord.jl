# Games Module
# Provides game-related utilities like server status and LFG (Looking for Group).

using Accord
using HTTP
using JSON3

function setup_games(client::Client)

    @slash_command client begin
        name = "mc_status"
        description = "Checks the status of a Minecraft server"
        @option host String "Server IP or hostname" required=true
    end
    function mc_status_cmd(ctx)
        host = get_option(ctx, "host")
        defer(ctx)

        try
            # Use public API for MC status
            resp = HTTP.get("https://api.mcsrvstat.us/2/\$host")
            data = JSON3.read(resp.body)
            
            if data.online
                e = embed(
                    title="Minecraft Server: \$host",
                    description=get(data, :motd, Dict(:clean => ["No MOTD"]))[:clean][1],
                    color=0x57F287, # Green
                    thumbnail=thumbnail(url="https://api.mcsrvstat.us/icon/\$host")
                )
                push!(e.fields, embed_field(name="Players", value="\$(data.players.online) / \$(data.players.max)", inline=true))
                push!(e.fields, embed_field(name="Version", value=string(data.version), inline=true))
                followup(ctx, embeds=[e])
            else
                followup(ctx, content="❌ Server **\$host** is offline.")
            end
        catch e
            followup(ctx, content="❌ Could not fetch status for **\$host**.")
        end
    end

    @slash_command client begin
        name = "lfg"
        description = "Create a Looking for Group post"
        @option game String "Game name" required=true
        @option description String "Details (time, rank, etc.)" required=true
    end
    function lfg_cmd(ctx)
        game = get_option(ctx, "game")
        desc = get_option(ctx, "description")
        user = ctx.interaction.member.user.username

        e = embed(
            title="🎮 LFG: \$game",
            description=desc,
            color=0x5865F2,
            author=embed_author(name="Requested by \$user")
        )
        
        btn = button(label="Join Group", style=ButtonStyles.SUCCESS, custom_id="lfg_join")
        respond(ctx, embeds=[e], components=[action_row([btn])])
    end

    @button_handler client "lfg_join" begin
    end
    function on_lfg_join(ctx)
        # Just a simple acknowledgment
        user = ctx.interaction.member.user.username
        respond(ctx, content="📢 **\$user** wants to join the group!", flags=MsgFlagEphemeral)
    end

    println("🎮 Games module loaded.")
end
