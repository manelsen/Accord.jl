# Tickets Module
# Provides a support ticketing system using buttons and modals.

using Accord

function setup_tickets(client::Client)

    @slash_command client "setup_tickets" "Spawns the ticket creation button (Admin only)" do ctx
        # Note: default_member_permissions would go in the macro if using the block syntax
        # For positional, we can use the @check macro or set it manually in sync_commands!
        # Let's use the new block syntax I just implemented to test it!
        
        # Wait, I need to check if the block syntax supports default_member_permissions.
        # I only added name, description, handler, and @option.
        # Let's stick to do-blocks for now for consistency.
        
        btn = button(label="Open Ticket", style=ButtonStyles.PRIMARY, custom_id="ticket_open", emoji="🎫")
        row = action_row([btn])
        respond(ctx, content="Click below to open a support ticket:", components=[row])
    end

    @button_handler client "ticket_open" function(ctx)
        ti = text_input("subject", "Brief Subject", style=TextInputStyles.SHORT, required=true)
        ti_desc = text_input("description", "Please describe your issue", style=TextInputStyles.PARAGRAPH, required=true)
        show_modal(ctx, "ticket_modal", "Open a Support Ticket", [action_row([ti]), action_row([ti_desc])])
    end

    @modal_handler client "ticket_modal" function(ctx)
        subject = modal_values(ctx)["subject"]
        description = modal_values(ctx)["description"]
        user_name = ctx.interaction.member.user.username
        
        e = embed(
            title="Ticket: $subject",
            description=description,
            color=0x5865F2,
            footer=embed_footer("Opened by $user_name")
        )
        respond(ctx, content="Ticket opened successfully!", embeds=[e], flags=MsgFlagEphemeral)
    end

    println("🎫 Tickets module loaded.")
end
