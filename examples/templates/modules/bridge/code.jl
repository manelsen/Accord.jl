# Bridge Module
# Provides a simple way to receive external notifications via webhooks.

using Accord

function setup_bridge(client::Client)

    @slash_command client "webhook_setup" "Configures a bridge webhook for this channel" function(ctx)
        try
            wh = Accord.create_webhook(ctx.client, ctx.channel_id; body=Dict("name" => "Accord Bridge"))
            url = "https://discord.com/api/webhooks/$(wh.id)/$(wh.token)"

            e = Accord.embed(
                title="Bridge Configured",
                description="Use the following URL to send data from external apps:",
                color=0x57F287,
                fields=[Accord.embed_field("Webhook URL", "`$url`")],
            )
            Accord.respond(ctx; embeds=[e], ephemeral=true)
        catch e
            @error "Failed to create webhook" exception=e
            Accord.respond(ctx; content="❌ Failed to create webhook. I need the Manage Webhooks permission.", ephemeral=true)
        end
    end

    println("🌉 Bridge module loaded.")
end
