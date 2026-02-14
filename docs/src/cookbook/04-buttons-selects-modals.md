# Recipe 04 — Buttons, Selects & Modals

**Difficulty:** Intermediate
**What you will build:** Interactive buttons, select menus, modal dialogs, and a complete ticket system workflow.

**Prerequisites:** [Recipe 03](03-slash-commands.md)

---

## 1. Buttons

### Button Styles

| Style | Constant | Color | Requires |
|-------|----------|-------|----------|
| Primary | `ButtonStyles.PRIMARY` | Blurple | `custom_id` |
| Secondary | `ButtonStyles.SECONDARY` | Grey | `custom_id` |
| Success | `ButtonStyles.SUCCESS` | Green | `custom_id` |
| Danger | `ButtonStyles.DANGER` | Red | `custom_id` |
| Link | `ButtonStyles.LINK` | Grey | `url` (no handler) |

### Sending Buttons

```julia
@slash_command client "buttons" "Show some buttons" function(ctx)
    components = [
        action_row([
            button(label="Click me!", custom_id="btn_click", style=ButtonStyles.PRIMARY),
            button(label="Danger!", custom_id="btn_danger", style=ButtonStyles.DANGER),
            button(label="Visit Site", url="https://julialang.org", style=ButtonStyles.LINK),
        ])
    ]
    respond(ctx; content="Choose a button:", components=components)
end
```

### Handling Button Clicks

```julia
@button_handler client "btn_click" function(ctx)
    respond(ctx; content="You clicked the button!", ephemeral=true)
end

@button_handler client "btn_danger" function(ctx)
    respond(ctx; content="Danger zone!", ephemeral=true)
end
```

### Buttons with Emoji

```julia
button(
    label="Approve",
    custom_id="approve",
    style=ButtonStyles.SUCCESS,
    emoji=Dict("name" => "✅"),
)
```

### Disabling Buttons After Click

```julia
@button_handler client "confirm_action" function(ctx)
    # Respond with disabled buttons (UPDATE_MESSAGE for component interactions)
    components = [
        action_row([
            button(label="Confirmed", custom_id="confirm_action", style=ButtonStyles.SUCCESS, disabled=true),
        ])
    ]
    respond(ctx; content="Action confirmed!", components=components)
end
```

## 2. String Select Menus

```julia
@slash_command client "colors" "Pick your favorite colors" function(ctx)
    sel = string_select(
        custom_id="color_select",
        placeholder="Choose up to 3 colors...",
        min_values=1,
        max_values=3,
        options=[
            select_option(label="Red", value="red", description="The color of fire", emoji=Dict("name" => "🔴")),
            select_option(label="Green", value="green", description="The color of nature", emoji=Dict("name" => "🟢")),
            select_option(label="Blue", value="blue", description="The color of sky", emoji=Dict("name" => "🔵")),
            select_option(label="Yellow", value="yellow", description="The color of sun", emoji=Dict("name" => "🟡")),
        ]
    )
    respond(ctx; content="Pick your colors:", components=[action_row([sel])])
end

@select_handler client "color_select" function(ctx)
    values = selected_values(ctx)
    respond(ctx; content="You picked: **$(join(values, ", "))**", ephemeral=true)
end
```

## 3. Specialized Select Menus

### User Select

```julia
sel = user_select(custom_id="pick_user", placeholder="Select a user")
respond(ctx; content="Pick a user:", components=[action_row([sel])])
```

### Role Select

```julia
sel = role_select(custom_id="pick_role", placeholder="Select a role")
respond(ctx; content="Pick a role:", components=[action_row([sel])])
```

### Mentionable Select (Users + Roles)

```julia
sel = mentionable_select(custom_id="pick_mention", placeholder="Select user or role")
respond(ctx; content="Pick someone:", components=[action_row([sel])])
```

### Channel Select

```julia
sel = channel_select(
    custom_id="pick_channel",
    placeholder="Select a channel",
    channel_types=[ChannelTypes.GUILD_TEXT, ChannelTypes.GUILD_VOICE]
)
respond(ctx; content="Pick a channel:", components=[action_row([sel])])
```

All specialized selects use `@select_handler` and `selected_values(ctx)` returns Snowflake ID strings.

## 4. Modals (Popup Forms)

### Showing a Modal

```julia
@slash_command client "feedback" "Give feedback" function(ctx)
    show_modal(ctx;
        title="Feedback Form",
        custom_id="feedback_modal",
        components=[
            action_row([
                text_input(
                    custom_id="fb_subject",
                    label="Subject",
                    style=TextInputStyles.SHORT,
                    placeholder="Brief summary...",
                    required=true,
                    max_length=100,
                ),
            ]),
            action_row([
                text_input(
                    custom_id="fb_body",
                    label="Details",
                    style=TextInputStyles.PARAGRAPH,
                    placeholder="Tell us more...",
                    required=true,
                    min_length=10,
                    max_length=2000,
                ),
            ]),
        ]
    )
end
```

### Handling Modal Submissions

```julia
@modal_handler client "feedback_modal" function(ctx)
    values = modal_values(ctx)  # Dict{String, String}
    subject = values["fb_subject"]
    body = values["fb_body"]

    e = embed(
        title="Feedback Received",
        color=0x57F287,
        fields=[
            Dict("name" => "Subject", "value" => subject),
            Dict("name" => "Details", "value" => body),
        ]
    )
    respond(ctx; embeds=[e], ephemeral=true)
end
```

## 5. Button → Modal Flow

A button click can open a modal:

```julia
@slash_command client "report" "Report an issue" function(ctx)
    components = [
        action_row([
            button(label="Report Bug", custom_id="report_bug", style=ButtonStyles.DANGER, emoji=Dict("name" => "🐛")),
        ])
    ]
    respond(ctx; content="Click to report an issue:", components=components)
end

@button_handler client "report_bug" function(ctx)
    show_modal(ctx;
        title="Bug Report",
        custom_id="bug_report_modal",
        components=[
            action_row([text_input(custom_id="bug_title", label="Bug Title", style=TextInputStyles.SHORT, required=true)]),
            action_row([text_input(custom_id="bug_desc", label="Description", style=TextInputStyles.PARAGRAPH, required=true)]),
        ]
    )
end

@modal_handler client "bug_report_modal" function(ctx)
    values = modal_values(ctx)
    e = embed(
        title="Bug Report: $(values["bug_title"])",
        description=values["bug_desc"],
        color=0xED4245,
        footer=Dict("text" => "Reported by $(ctx.interaction.member.user.username)")
    )
    respond(ctx; content="Bug report submitted!", embeds=[e])
end
```

## 6. Dynamic Custom IDs

Use prefixed custom IDs to pass data through interactions:

```julia
# When creating buttons, encode data in the custom_id
@slash_command client "poll_quick" "Quick yes/no poll" function(ctx)
    question = get_option(ctx, "question", "Agree?")
    components = [
        action_row([
            button(label="Yes (0)", custom_id="vote:yes:0", style=ButtonStyles.SUCCESS),
            button(label="No (0)", custom_id="vote:no:0", style=ButtonStyles.DANGER),
        ])
    ]
    respond(ctx; content="**$question**", components=components)
end

# Handle all "vote:" prefixed buttons (prefix matching)
@button_handler client "vote:" function(ctx)
    cid = custom_id(ctx)
    parts = split(cid, ":")
    choice = parts[2]  # "yes" or "no"
    count = parse(Int, parts[3]) + 1

    # Update the button with incremented count
    new_id = "vote:$(choice):$(count)"
    respond(ctx; content="You voted **$choice**! (Total: $count)", ephemeral=true)
end
```

## 7. Complete Example: Ticket System

A full workflow: slash command → button → modal → ticket channel.

```julia
using Accord

token = ENV["DISCORD_TOKEN"]
client = Client(token; intents=IntentGuilds)

# Step 1: Post the ticket panel
@slash_command client "ticket_setup" "Set up a ticket panel" function(ctx)
    e = embed(
        title="Support Tickets",
        description="Click the button below to create a support ticket.",
        color=0x5865F2,
    )
    components = [
        action_row([
            button(label="Create Ticket", custom_id="ticket_create", style=ButtonStyles.PRIMARY, emoji=Dict("name" => "🎫")),
        ])
    ]
    respond(ctx; embeds=[e], components=components)
end

# Step 2: Button opens a modal
@button_handler client "ticket_create" function(ctx)
    show_modal(ctx;
        title="Create Support Ticket",
        custom_id="ticket_modal",
        components=[
            action_row([
                text_input(custom_id="ticket_subject", label="Subject", style=TextInputStyles.SHORT, required=true, placeholder="Brief description"),
            ]),
            action_row([
                text_input(custom_id="ticket_details", label="Details", style=TextInputStyles.PARAGRAPH, required=true, placeholder="Describe your issue..."),
            ]),
        ]
    )
end

# Step 3: Modal submission creates the ticket
@modal_handler client "ticket_modal" function(ctx)
    values = modal_values(ctx)
    user = ctx.interaction.member.user

    e = embed(
        title="Ticket: $(values["ticket_subject"])",
        description=values["ticket_details"],
        color=0xFEE75C,
        footer=Dict("text" => "Opened by $(user.username)"),
    )
    components = [
        action_row([
            button(label="Close Ticket", custom_id="ticket_close", style=ButtonStyles.DANGER),
        ])
    ]
    respond(ctx; content="Ticket created!", embeds=[e], components=components, ephemeral=true)

    # Also post in a log channel (optional)
    # LOG_CHANNEL = Snowflake(999999999999999999)
    # create_message(ctx.client, LOG_CHANNEL; embeds=[e])
end

# Step 4: Close the ticket
@button_handler client "ticket_close" function(ctx)
    respond(ctx; content="Ticket closed by <@$(ctx.interaction.member.user.id)>.")
end

# Wiring
on(client, ReadyEvent) do c, event
    sync_commands!(c, c.command_tree)
    @info "Ticket bot ready!"
end

start(client)
```

---

**Next steps:** [Recipe 05 — Voice](05-voice.md) for audio playback and recording, or [Recipe 10 — Polls](10-polls.md) for Discord's native poll system.
