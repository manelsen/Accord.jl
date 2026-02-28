# Bridge Module
# Provides a simple way to receive external notifications via webhooks.

using Accord

function setup_bridge(client::Client)

    @slash_command client "webhook_setup" "Configures a bridge webhook for this channel" do ctx
        ch_id = ctx.interaction.channel_id
        
        try
            wh = create_webhook(ctx.client.ratelimiter, ch_id; 
                token=ctx.client.token, name="Accord Bridge")
            
            e = embed(
                title="Bridge Configured",
                description="Use the following URL to send data from external apps:",
                color=0x57F287
            )
            push!(e.fields, embed_field(name="Webhook URL", value="`$(wh.url)`"))
            
            respond(ctx, embeds=[e], flags=MsgFlagEphemeral)
        catch e
            respond(ctx, content="❌ Failed to create webhook.", flags=MsgFlagEphemeral)
        end
    end

    println("🌉 Bridge module loaded.")
end
