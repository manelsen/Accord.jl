# Recipe 04 — Buttons, Selects & Modals

**Difficulty:** Intermediate
**What you will build:** Interactive buttons, select menus, modal dialogs, and a complete ticket system workflow.

**Prerequisites:** [Recipe 03](03-slash-commands.md)

---

## 1. Buttons

### Button Styles

| Style | Constant | Color | Requires |
|-------|----------|-------|----------|
| Primary | [`ButtonStyles`](@ref)`.PRIMARY` | Blurple | `custom_id` |
| Secondary | [`ButtonStyles`](@ref)`.SECONDARY` | Grey | `custom_id` |
| Success | [`ButtonStyles`](@ref)`.SUCCESS` | Green | `custom_id` |
| Danger | [`ButtonStyles`](@ref)`.DANGER` | Red | `custom_id` |
| Link | [`ButtonStyles`](@ref)`.LINK` | Grey | `url` (no handler) |

### Sending Buttons

```julia
@slash_command client "buttons" "Show some buttons" function(ctx)
    components = [
        Accord.action_row([
            Accord.button(label="Click me!", custom_id="btn_click", style=ButtonStyles.PRIMARY),
            Accord.button(label="Danger!", custom_id="btn_danger", style=ButtonStyles.DANGER),
            Accord.button(label="Visit Site", url="https://julialang.org", style=ButtonStyles.LINK),
        ])
    ]
    Accord.respond(ctx; content="Choose a button:", components=components)
end
```

### Handling Button Clicks

!!! warning "3-Second Interaction Response Deadline"
    Discord requires an initial response to button clicks, select menu choices, and modal submissions within **3 seconds**. If your handler performs slow operations, call `defer(ctx)` first to acknowledge the interaction, then follow up with the actual response.

```julia
@button_handler client "btn_click" function(ctx)
    Accord.respond(ctx; content="You clicked the button!", ephemeral=true)
end

@button_handler client "btn_danger" function(ctx)
    Accord.respond(ctx; content="Danger zone!", ephemeral=true)
end
```

### Buttons with Emoji

```julia
Accord.button(
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
        Accord.action_row([
            Accord.button(label="Confirmed", custom_id="confirm_action", style=ButtonStyles.SUCCESS, disabled=true),
        ])
    ]
    Accord.respond(ctx; content="Action confirmed!", components=components)
end
```

## 2. String Select Menus

```julia
@slash_command client "colors" "Pick your favorite colors" function(ctx)
    sel = Accord.string_select(
        custom_id="color_select",
        placeholder="Choose up to 3 colors...",
        min_values=1,
        max_values=3,
        options=[
            Accord.select_option(label="Red", value="red", description="The color of fire", emoji=Dict("name" => "🔴")),
            Accord.select_option(label="Green", value="green", description="The color of nature", emoji=Dict("name" => "🟢")),
            Accord.select_option(label="Blue", value="blue", description="The color of sky", emoji=Dict("name" => "🔵")),
            Accord.select_option(label="Yellow", value="yellow", description="The color of sun", emoji=Dict("name" => "🟡")),
        ]
    )
    Accord.respond(ctx; content="Pick your colors:", components=[Accord.action_row([sel])])
end

@select_handler client "color_select" function(ctx)
    values = Accord.selected_values(ctx)
    Accord.respond(ctx; content="You picked: **$(join(values, ", "))**", ephemeral=true)
end
```

## 3. Specialized Select Menus

### User Select

```julia
sel = user_select(custom_id="pick_user", placeholder="Select a user")
Accord.respond(ctx; content="Pick a user:", components=[Accord.action_row([sel])])
```

### Role Select

```julia
sel = role_select(custom_id="pick_role", placeholder="Select a role")
Accord.respond(ctx; content="Pick a role:", components=[Accord.action_row([sel])])
```

### Mentionable Select (Users + Roles)

```julia
sel = mentionable_select(custom_id="pick_mention", placeholder="Select user or role")
Accord.respond(ctx; content="Pick someone:", components=[Accord.action_row([sel])])
```

### Channel Select

```julia
sel = channel_select(
    custom_id="pick_channel",
    placeholder="Select a channel",
    channel_types=[[`ChannelTypes`](@ref).GUILD_TEXT, [`ChannelTypes`](@ref).GUILD_VOICE]
)
Accord.respond(ctx; content="Pick a channel:", components=[Accord.action_row([sel])])
```

All specialized selects use [`@select_handler`](@ref) and [`selected_values`](@ref) returns [`Snowflake`](@ref) ID strings.

## 4. Modals (Popup Forms)

### Showing a Modal

```julia
@slash_command client "feedback" "Give feedback" function(ctx)
    show_modal(ctx;
        title="Feedback Form",
        custom_id="feedback_modal",
        components=[
            Accord.label("Subject",
                Accord.text_input(
                    custom_id="fb_subject",
                    style=TextInputStyles.SHORT,
                    placeholder="Brief summary...",
                    max_length=100,
                )),
            Accord.label("Details",
                Accord.text_input(
                    custom_id="fb_body",
                    style=TextInputStyles.PARAGRAPH,
                    placeholder="Tell us more...",
                    min_length=10,
                    max_length=2000,
                );
                description="What happened, and what you expected"),
        ]
    )
end
```

### Handling Modal Submissions

```julia
@modal_handler client "feedback_modal" function(ctx)
    values = Accord.modal_values(ctx)  # Dict{String, Any}: custom_id => value
    subject = values["fb_subject"]
    body = values["fb_body"]

    e = Accord.embed(
        title="Feedback Received",
        color=0x57F287,
        fields=[
            Dict("name" => "Subject", "value" => subject),
            Dict("name" => "Details", "value" => body),
        ]
    )
    Accord.respond(ctx; embeds=[e], ephemeral=true)
end
```

!!! note "Labels"
    Discord now wants every modal input wrapped in a [`label`](@ref), which holds
    the question and an optional description. The older layout, a `text_input`
    with its own `label=` inside an `action_row`, still works but is deprecated.

### Choices, Checkboxes and File Uploads

Besides text and select menus, a modal can hold radio buttons, checkboxes and
file pickers. [`modal_values`](@ref) returns each in its natural type.

```julia
@slash_command client "signup" "Sign up for the event" function(ctx)
    show_modal(ctx;
        title="Event Signup",
        custom_id="signup_modal",
        components=[
            Accord.label("Which day?", Accord.radio_group(custom_id="day", options=[
                Accord.select_option(label="Saturday", value="sat"),
                Accord.select_option(label="Sunday", value="sun"),
            ])),
            Accord.label("Sessions", Accord.checkbox_group(custom_id="sessions", options=[
                Accord.select_option(label="Workshop", value="workshop"),
                Accord.select_option(label="Talks", value="talks"),
                Accord.select_option(label="Dinner", value="dinner"),
            ]; min_values=0)),
            Accord.label("Send me reminders", Accord.checkbox(custom_id="remind", default=true)),
            Accord.label("Photo for your badge",
                Accord.file_upload(custom_id="photo", required=false, file_types=["image"])),
        ]
    )
end

@modal_handler client "signup_modal" function(ctx)
    v = Accord.modal_values(ctx)
    day      = v["day"]          # "sat", "sun" (or nothing if the group is optional)
    sessions = v["sessions"]     # Vector{String}, possibly empty
    remind   = v["remind"]       # Bool
    photos   = Accord.modal_files(ctx, "photo")   # Vector{Attachment}
    Accord.respond(ctx; content="Signed up for $(day): $(join(sessions, ", ")); " *
        "reminders $(remind ? "on" : "off"); $(length(photos)) photo(s)", ephemeral=true)
end
```

## 5. Button → Modal Flow

A button click can open a modal:

```julia
@slash_command client "report" "Report an issue" function(ctx)
    components = [
        Accord.action_row([
            Accord.button(label="Report Bug", custom_id="report_bug", style=ButtonStyles.DANGER, emoji=Dict("name" => "🐛")),
        ])
    ]
    Accord.respond(ctx; content="Click to report an issue:", components=components)
end

@button_handler client "report_bug" function(ctx)
    show_modal(ctx;
        title="Bug Report",
        custom_id="bug_report_modal",
        components=[
            Accord.label("Bug Title", Accord.text_input(custom_id="bug_title", style=TextInputStyles.SHORT)),
            Accord.label("Description", Accord.text_input(custom_id="bug_desc", style=TextInputStyles.PARAGRAPH)),
        ]
    )
end

@modal_handler client "bug_report_modal" function(ctx)
    values = Accord.modal_values(ctx)
    e = Accord.embed(
        title="Bug Report: $(values["bug_title"])",
        description=values["bug_desc"],
        color=0xED4245,
        footer=Dict("text" => "Reported by $(ctx.interaction.member.user.username)")
    )
    Accord.respond(ctx; content="Bug report submitted!", embeds=[e])
end
```

!!! note "Custom ID 100-Character Limit"
    Discord limits [`custom_id`](@ref) to **100 characters**. Keep IDs short and use prefixes/suffixes efficiently. For complex state, store data in your bot's memory and reference it with a short ID.

## 6. Dynamic Custom IDs

Use prefixed custom IDs to pass data through interactions:

```julia
# When creating buttons, encode data in the custom_id
@slash_command client "poll_quick" "Quick yes/no poll" function(ctx)
    question = Accord.get_option(ctx, "question", "Agree?")
    components = [
        Accord.action_row([
            Accord.button(label="Yes (0)", custom_id="vote:yes:0", style=ButtonStyles.SUCCESS),
            Accord.button(label="No (0)", custom_id="vote:no:0", style=ButtonStyles.DANGER),
        ])
    ]
    Accord.respond(ctx; content="**$question**", components=components)
end

# Handle all "vote:" prefixed buttons (prefix matching)
@button_handler client "vote:" function(ctx)
    cid = Accord.custom_id(ctx)
    parts = split(cid, ":")
    choice = parts[2]  # "yes" or "no"
    count = parse(Int, parts[3]) + 1

    # Update the button with incremented count
    new_id = "vote:$(choice):$(count)"
    Accord.respond(ctx; content="You voted **$choice**! (Total: $count)", ephemeral=true)
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
    e = Accord.embed(
        title="Support Tickets",
        description="Click the button below to create a support ticket.",
        color=0x5865F2,
    )
    components = [
        Accord.action_row([
            Accord.button(label="Create Ticket", custom_id="ticket_create", style=ButtonStyles.PRIMARY, emoji=Dict("name" => "🎫")),
        ])
    ]
    Accord.respond(ctx; embeds=[e], components=components)
end

# Step 2: Button opens a modal
@button_handler client "ticket_create" function(ctx)
    show_modal(ctx;
        title="Create Support Ticket",
        custom_id="ticket_modal",
        components=[
            Accord.label("Subject", Accord.text_input(custom_id="ticket_subject", style=TextInputStyles.SHORT, placeholder="Brief description")),
            Accord.label("Details", Accord.text_input(custom_id="ticket_details", style=TextInputStyles.PARAGRAPH, placeholder="Describe your issue...")),
        ]
    )
end

# Step 3: Modal submission creates the ticket
@modal_handler client "ticket_modal" function(ctx)
    values = Accord.modal_values(ctx)
    user = ctx.interaction.member.user

    e = Accord.embed(
        title="Ticket: $(values["ticket_subject"])",
        description=values["ticket_details"],
        color=0xFEE75C,
        footer=Dict("text" => "Opened by $(user.username)"),
    )
    components = [
        Accord.action_row([
            Accord.button(label="Close Ticket", custom_id="ticket_close", style=ButtonStyles.DANGER),
        ])
    ]
    Accord.respond(ctx; content="Ticket created!", embeds=[e], components=components, ephemeral=true)

    # Also post in a log channel (optional)
    # LOG_CHANNEL = Snowflake(999999999999999999)
    # create_message(ctx.client, LOG_CHANNEL; embeds=[e])
end

# Step 4: Close the ticket
@button_handler client "ticket_close" function(ctx)
    Accord.respond(ctx; content="Ticket closed by <@$(ctx.interaction.member.user.id)>.")
end

# Wiring
Accord.on(client, [`ReadyEvent`](@ref)) do c, event
    sync_commands!(c, c.command_tree)
    @info "Ticket bot ready!"
end

Accord.start(client)
```

---

**Next steps:** [Recipe 05 — Voice](05-voice.md) for audio playback and recording, or [Recipe 10 — Polls](10-polls.md) for Discord's native poll system.
