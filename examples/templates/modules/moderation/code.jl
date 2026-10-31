# Moderation Module
# Provides keyword filtering and a kick command.
# The word filter needs the privileged Message Content intent.

using Accord

function setup_moderation(client::Client)
    # Simple word filter
    banned_words = ["spam", "scam", "badword"]

    @on_message client function(c, msg)
        content_lower = lowercase(msg.content)
        any(w -> occursin(w, content_lower), banned_words) || return
        try
            Accord.delete_message(c, msg.channel_id, msg.id)
            create_message(c, msg.channel_id; content="<@$(msg.author.id)>, please watch your language.")
        catch e
            @warn "Failed to delete message" exception=e
        end
    end

    @slash_command client "kick" "Kicks a user from the server" [
        @option User "user" "The user to kick" required=true
        @option String "reason" "Reason for kicking" required=false
    ] function(ctx)
        user_id = Snowflake(Accord.get_option(ctx, "user"))
        reason = Accord.get_option(ctx, "reason", "No reason provided")

        try
            Accord.remove_guild_member(ctx.client, ctx.guild_id, user_id; reason)
            Accord.respond(ctx; content="Successfully kicked <@$user_id>.")
        catch e
            @error "Failed to kick user" exception=e
            Accord.respond(ctx; content="Failed to kick user. Check my permissions.", ephemeral=true)
        end
    end

    println("🛡️ Moderation module loaded.")
end
