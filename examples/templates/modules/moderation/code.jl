# Moderation Module
# Provides keyword filtering and kick/ban commands.

using Accord

function setup_moderation(client::Client)
    # Simple word filter
    const BANNED_WORDS = ["spam", "scam", "badword"]

    on_message(client) do ctx
        msg = ctx.event.message
        ismissing(msg.content) && return
        
        content_lower = lowercase(msg.content)
        for word in BANNED_WORDS
            if occursin(word, content_lower)
                # Delete the message
                try
                    # Requires MANAGE_MESSAGES permission
                    delete_message(ctx.client.ratelimiter, msg.channel_id, msg.id; token=ctx.client.token)
                    # Warn the user
                    create_message(ctx.client.ratelimiter, msg.channel_id; 
                        token=ctx.client.token, 
                        content="<@\$(msg.author.id)>, please watch your language."
                    )
                catch e
                    @warn "Failed to delete message (check permissions)" exception=e
                end
                break
            end
        end
    end

    @slash_command client begin
        name = "kick"
        description = "Kicks a user from the server"
        default_member_permissions = "2" # PermKickMembers
        
        @option user User "The user to kick" required=true
        @option reason String "Reason for kicking" required=false
    end
    function kick_command(ctx)
        target_user = get_option(ctx, "user")
        reason = get_option(ctx, "reason", "No reason provided")
        
        try
            # Requires KICK_MEMBERS permission
            Accord.remove_guild_member(ctx.client.ratelimiter, ctx.interaction.guild_id, target_user; 
                token=ctx.client.token, reason=reason)
            respond(ctx, content="Successfully kicked <@\$target_user>.")
        catch e
            respond(ctx, content="Failed to kick user. Check my role hierarchy and permissions.", flags=MsgFlagEphemeral)
        end
    end

    println("🛡️ Moderation module loaded.")
end
