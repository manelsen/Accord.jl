# Utils Module
# Provides helpful utility commands for server and user information.

using Accord
using Dates

function setup_utils(client::Client)

    @slash_command client begin
        name = "server_info"
        description = "Displays information about the current server"
    end
    function server_info_cmd(ctx)
        guild = fetch_guild(ctx.client, ctx.interaction.guild_id)
        
        e = embed(
            title="Server Information: \$(guild.name)",
            color=0x5865F2,
            thumbnail=thumbnail(url="https://cdn.discordapp.com/icons/\$(guild.id)/\$(guild.icon).png")
        )
        
        push!(e.fields, embed_field(name="ID", value=string(guild.id), inline=true))
        push!(e.fields, embed_field(name="Owner ID", value=string(guild.owner_id), inline=true))
        push!(e.fields, embed_field(name="Members", value=string(get(guild.approximate_member_count, "N/A")), inline=true))
        
        respond(ctx, embeds=[e])
    end

    @slash_command client begin
        name = "user_info"
        description = "Displays information about a user"
        @option user User "The user to inspect" required=false
    end
    function user_info_cmd(ctx)
        target_user = get_option(ctx, "user", ctx.interaction.member.user)
        
        e = embed(
            title="User Profile: \$(target_user.username)",
            color=0x57F287,
            thumbnail=thumbnail(url="https://cdn.discordapp.com/avatars/\$(target_user.id)/\$(target_user.avatar).png")
        )
        
        push!(e.fields, embed_field(name="ID", value=string(target_user.id), inline=true))
        push!(e.fields, embed_field(name="Bot?", value=string(get(target_user.bot, false)), inline=true))
        
        respond(ctx, embeds=[e])
    end

    @slash_command client begin
        name = "poll"
        description = "Create a simple poll"
        @option question String "The question to ask" required=true
        @option options String "Comma-separated options (max 5)" required=true
    end
    function poll_cmd(ctx)
        question = get_option(ctx, "question")
        raw_options = split(get_option(ctx, "options"), ",")
        
        opts = map(strip, raw_options)
        if length(opts) > 5
            return respond(ctx, content="❌ Maximum 5 options allowed.", flags=MsgFlagEphemeral)
        end

        # Discord Polls (native)
        poll_obj = Accord.Poll(
            question = Accord.PollMedia(text=question),
            answers = [Accord.PollAnswer(i, Accord.PollMedia(text=opt)) for (i, opt) in enumerate(opts)],
            allow_multiselect = false,
            layout_type = 1
        )

        # Native polls are sent via create_message
        create_message(ctx.client.ratelimiter, ctx.interaction.channel_id; 
            token=ctx.client.token, poll=poll_obj)
        
        # Ack the interaction
        respond(ctx, content="Poll created!", flags=MsgFlagEphemeral)
    end

    println("🔧 Utils module loaded.")
end
