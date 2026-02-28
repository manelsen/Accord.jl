# Tickets Module
# Provides a support ticketing system using buttons and modals.

using Accord

function setup_tickets(client::Client)

    @slash_command client begin
        name = "setup_tickets"
        description = "Spawns the ticket creation button (Admin only)"
        default_member_permissions = "8" # PermAdministrator
    end
    function setup_tickets_cmd(ctx)
        btn = button(label="Open Ticket", style=ButtonStyles.PRIMARY, custom_id="ticket_open", emoji="🎫")
        row = action_row([btn])
        
        respond(ctx, content="Click below to open a support ticket:", components=[row])
    end

    @button_handler client "ticket_open" begin
    end
    function on_ticket_open(ctx)
        # Show a modal to gather information
        ti = text_input("subject", "Brief Subject", style=TextInputStyles.SHORT, required=true)
        ti_desc = text_input("description", "Please describe your issue", style=TextInputStyles.PARAGRAPH, required=true)
        
        show_modal(ctx, "ticket_modal", "Open a Support Ticket", [action_row([ti]), action_row([ti_desc])])
    end

    @modal_handler client "ticket_modal" begin
    end
    function on_ticket_submit(ctx)
        subject = modal_values(ctx)["subject"]
        description = modal_values(ctx)["description"]
        
        user_name = ctx.interaction.member.user.username
        
        # In a real bot, you'd create a new channel here.
        # For simplicity in the template, we'll just send an embed back.
        e = embed(
            title="Ticket: \$subject",
            description=description,
            color=0x5865F2,
            footer=embed_footer("Opened by \$user_name")
        )
        
        respond(ctx, content="Ticket opened successfully!", embeds=[e], flags=MsgFlagEphemeral)
    end

    println("🎫 Tickets module loaded.")
end
