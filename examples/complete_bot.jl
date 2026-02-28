using Accord
using Dates

# ─── 1. State Structure (The "Heart" of your Bot) ─────────────────────────
# In Julia, we avoid global variables. We inject this state into the Context.
mutable struct BotState
    start_time::DateTime
    commands_run::Int
    feedback_count::Int
    admin_users::Vector{Snowflake}
end

# ─── 2. Custom Guards ────────────────────────────────────────────────
# We can create our own reusable checks.
function is_bot_admin()
    return function(ctx)
        if ctx.state.commands_run > 1000 # Example of dynamic logic
            return true
        end
        # Check against our admin list injected into the state
        return ctx.user.id in ctx.state.admin_users
    end
end

# ─── 3. Initialization ────────────────────────────────────────────────────────
state = BotState(now(), 0, 0, [Snowflake(0)]) # Add your ID here

client = Client(get(ENV, "DISCORD_TOKEN", "YOUR_TOKEN");
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
    state = state # State injection! Accessible via ctx.state
)

# ─── 4. Lifecycle Events ──────────────────────────────────────────────
on(client, ReadyEvent) do c, event
    @info "Bot connected as $(event.user.username)"
    # Sync commands globally
    sync_commands!(c, c.command_tree)
end

# ─── 5. Slash Commands with Options ────────────────────────────────────────────
@slash_command client "stats" "Shows bot statistics" function(ctx)
    ctx.state.commands_run += 1
    uptime = canonicalize(Dates.CompoundPeriod(now() - ctx.state.start_time))
    
    embed_data = embed(
        title = "📊 Accord.jl Bot Stats",
        color = 0x5865F2,
        fields = [
            embed_field("Uptime", "$uptime", true),
            embed_field("Commands", "$(ctx.state.commands_run)", true),
            embed_field("Feedback", "$(ctx.state.feedback_count)", true)
        ],
        footer = embed_footer("Powered by Julia")
    )
    
    respond(ctx; embeds=[embed_data])
end

# ─── 6. Context Commands (Right Click) ────────────────────────────────
@user_command client "Member Info" function(ctx)
    target_user = target(ctx) # Gets the user that was clicked
    respond(ctx; content="You selected **$(target_user.username)** (ID: $(target_user.id))", ephemeral=true)
end

# ─── 7. Components and Modals ─────────────────────────────────────────────────
@slash_command client "feedback" "Sends feedback to the developers" function(ctx)
    # Shows a button to open the Modal
    btn = button(ButtonStyles.PRIMARY, "open_feedback"; label="Send Feedback")
    row = action_row([btn])
    
    respond(ctx; 
        content="Click the button below to open the feedback form.",
        components=[row],
        ephemeral=true
    )
end

# Button Handler
@button_handler client "open_feedback" function(ctx)
    # Opens a form (Modal)
    show_modal(ctx, "modal_feedback", "Feedback Form", [
        action_row([
            text_input("fb_title", "Subject"; placeholder="E.g.: Bug in the stats command")
        ]),
        action_row([
            text_input("fb_body", "Message"; style=TextInputStyles.PARAGRAPH)
        ])
    ])
end

# Modal Handler
@modal_handler client "modal_feedback" function(ctx)
    vals = modal_values(ctx) # Dictionary with inputs
    ctx.state.feedback_count += 1
    
    @info "Feedback received" title=vals["fb_title"] body=vals["fb_body"]
    
    respond(ctx; content="Thank you for the feedback! Registered as #$(ctx.state.feedback_count)", ephemeral=true)
end

# ─── 8. Restricted Commands (Checks) ──────────────────────────────────────────
@check is_owner() # Only the bot owner
@slash_command client "shutdown" "Remotely shuts down the bot" function(ctx)
    respond(ctx; content="Shutting down processes... Bye!")
    sleep(1.0)
    stop(ctx.client)
    exit(0)
end

# ─── 9. Execution ─────────────────────────────────────────────────────────────
@info "Starting bot..."
start(client)
