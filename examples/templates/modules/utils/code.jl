# Utils Module
# Provides helpful utility commands for server and user information.

using Accord

function setup_utils(client::Client)

    @slash_command client "server_info" "Displays information about the current server" function(ctx)
        guild = get_guild(ctx.client, ctx.guild_id)

        e = Accord.embed(
            title="Server Information: $(guild.name)",
            color=0x5865F2,
            thumbnail=guild.icon isa String ?
                Dict("url" => "https://cdn.discordapp.com/icons/$(guild.id)/$(guild.icon).png") : nothing,
            fields=[
                Accord.embed_field("ID", string(guild.id); inline=true),
                Accord.embed_field("Owner ID", string(guild.owner_id); inline=true),
            ],
        )
        Accord.respond(ctx; embeds=[e])
    end

    @slash_command client "user_info" "Displays information about a user" [
        @option User "user" "The user to inspect" required=false
    ] function(ctx)
        user_id = Accord.get_option(ctx, "user")
        user = isnothing(user_id) ? ctx.user : get_user(ctx.client, Snowflake(user_id))

        e = Accord.embed(
            title="User Profile: $(user.username)",
            color=0x57F287,
            thumbnail=user.avatar isa String ?
                Dict("url" => "https://cdn.discordapp.com/avatars/$(user.id)/$(user.avatar).png") : nothing,
            fields=[
                Accord.embed_field("ID", string(user.id); inline=true),
                Accord.embed_field("Bot?", user.bot === true ? "yes" : "no"; inline=true),
            ],
        )
        Accord.respond(ctx; embeds=[e])
    end

    @slash_command client "poll" "Create a simple poll" [
        @option String "question" "The question to ask" required=true
        @option String "options" "Comma-separated options (max 10)" required=true
    ] function(ctx)
        question = Accord.get_option(ctx, "question")
        answers = filter(!isempty, String.(strip.(split(Accord.get_option(ctx, "options"), ","))))
        if !(1 <= length(answers) <= 10)
            return Accord.respond(ctx; content="❌ Give between 1 and 10 options.", ephemeral=true)
        end

        create_poll(ctx.client, ctx.channel_id; question, answers)
        Accord.respond(ctx; content="Poll created!", ephemeral=true)
    end

    println("🔧 Utils module loaded.")
end
