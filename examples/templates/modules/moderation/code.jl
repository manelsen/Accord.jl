# Moderation Module
# Provides keyword filtering and kick/ban commands.

using Accord

function setup_moderation(client::Client)
    # Simple word filter
    const BANNED_WORDS = ["spam", "scam", "badword"]

    on_message(client) do c, msg
        # ctx here is actually (client, message) because of @on_message implementation
        # let's use positional for now
        content_lower = lowercase(msg.content)
        for word in BANNED_WORDS
            if occursin(word, content_lower)
                try
                    delete_message(c.ratelimiter, msg.channel_id, msg.id; token=c.token)
                    create_message(c.ratelimiter, msg.channel_id; 
                        token=c.token, 
                        content="<@$(msg.author.id)>, please watch your language."
                    )
                catch e
                    @warn "Failed to delete message" exception=e
                end
                break
            end
        end
    end

    @slash_command client "kick" "Kicks a user from the server" [
        @option User "user" "The user to kick" required=true
        @option String "reason" "Reason for kicking" required=false
    ] do ctx
        target_user = get_option(ctx, "user")
        reason = get_option(ctx, "reason", "No reason provided")
        
        try
            Accord.remove_guild_member(ctx.client.ratelimiter, ctx.interaction.guild_id, target_user; 
                token=ctx.client.token, reason=reason)
            respond(ctx, content="Successfully kicked <@$target_user>.")
        catch e
            respond(ctx, content="Failed to kick user. Check my permissions.", flags=MsgFlagEphemeral)
        end
    end

    println("🛡️ Moderation module loaded.")
end
