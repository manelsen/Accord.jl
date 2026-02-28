# Bridge Module
# Provides a simple way to receive external notifications via webhooks.

using Accord

function setup_bridge(client::Client)

    @slash_command client begin
        name = "webhook_setup"
        description = "Configures a bridge webhook for this channel"
        default_member_permissions = "32" # PermManageMessages
    end
    function webhook_setup_cmd(ctx)
        ch_id = ctx.interaction.channel_id
        
        try
            # Create a real Discord webhook for this channel
            wh = create_webhook(ctx.client.ratelimiter, ch_id; 
                token=ctx.client.token, name="Accord Bridge")
            
            e = embed(
                title="Bridge Configured",
                description="Use the following URL to send data from external apps (GitHub, Zapier, etc.):",
                color=0x57F287
            )
            push!(e.fields, embed_field(name="Webhook URL", value="`\$(wh.url)`"))
            
            respond(ctx, embeds=[e], flags=MsgFlagEphemeral)
        catch e
            respond(ctx, content="❌ Failed to create webhook. Ensure I have `MANAGE_WEBHOOKS` permission.", flags=MsgFlagEphemeral)
        end
    end

    println("🌉 Bridge module loaded.")
end
