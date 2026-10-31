# Tickets Module
# Provides a support ticketing system using buttons and modals.

using Accord

function setup_tickets(client::Client)

    @check Accord.has_permissions(:MANAGE_GUILD)
    @slash_command client "setup_tickets" "Posts the ticket button in this channel (Manage Server only)" function(ctx)
        btn = Accord.button(label="Open Ticket", style=ButtonStyles.PRIMARY, custom_id="ticket_open", emoji=Dict("name" => "🎫"))
        Accord.respond(ctx; content="Click below to open a support ticket:", components=[Accord.action_row([btn])])
    end

    @button_handler client "ticket_open" function(ctx)
        show_modal(ctx; title="Open a Support Ticket", custom_id="ticket_modal", components=[
            Accord.label("Brief subject", Accord.text_input(custom_id="subject", style=TextInputStyles.SHORT, max_length=100)),
            Accord.label("Please describe your issue", Accord.text_input(custom_id="description", style=TextInputStyles.PARAGRAPH)),
        ])
    end

    @modal_handler client "ticket_modal" function(ctx)
        values = Accord.modal_values(ctx)
        e = Accord.embed(
            title="Ticket: $(values["subject"])",
            description=values["description"],
            color=0x5865F2,
            footer=Accord.embed_footer("Opened by $(ctx.user.username)"),
        )
        Accord.respond(ctx; content="Ticket opened successfully!", embeds=[e], ephemeral=true)
    end

    println("🎫 Tickets module loaded.")
end
