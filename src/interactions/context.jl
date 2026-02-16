# Interaction context — provides helpers for responding to interactions

"""
    InteractionContext

Use this in your slash command handlers to access interaction data and send responses.

Wraps an [`Interaction`](@ref) with convenience methods for responding. Holds a reference to the [`Client`](@ref).
"""
struct InteractionContext
    client::Client
    interaction::Interaction
    responded::Ref{Bool}
    deferred::Ref{Bool}
end

function InteractionContext(client::Client, interaction::Interaction)
    InteractionContext(client, interaction, Ref(false), Ref(false))
end

# --- Property accessors ---

_is_present(x) = !ismissing(x) && !isnothing(x)

"""Use this property to access the Discord user who invoked the command or interaction.

Get the user who triggered the interaction."""
function Base.getproperty(ctx::InteractionContext, name::Symbol)
    if name === :user || name === :author
        i = getfield(ctx, :interaction)
        # Prefer member.user in guild contexts, fall back to user
        member = i.member
        if _is_present(member) && _is_present(member.user)
            return member.user
        end
        return ismissing(i.user) ? nothing : i.user
    elseif name === :guild_id
        return getfield(ctx, :interaction).guild_id
    elseif name === :channel_id
        return getfield(ctx, :interaction).channel_id
    elseif name === :state
        return getfield(ctx, :client).state_data
    else
        return getfield(ctx, name)
    end
end

"""
    get_options(ctx::InteractionContext) -> Dict{String, Any}

Use this to retrieve all command options that the user provided when invoking a slash command.

Get all interaction data options as a dictionary mapping option names to values.
"""
function get_options(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return Dict{String, Any}()
    options = data.options
    ismissing(options) && return Dict{String, Any}()

    result = Dict{String, Any}()
    for opt in options
        if !ismissing(opt.value)
            result[opt.name] = opt.value
        end
    end
    return result
end

"""
    get_option(ctx, name, default=nothing)

Use this to retrieve a specific command option value by its name.

Get a specific option value by name from the interaction data.

# Example
```julia
@slash_command client "greet" "Greet someone" options=[command_option(type=6, name="user", description="Who to greet", required=true)] function(ctx)
    user_id = get_option(ctx, "user")
    respond(ctx; content="Hello, <@\$user_id>!")
end
```
"""
function get_option(ctx::InteractionContext, name::String, default=nothing)
    opts = get_options(ctx)
    get(opts, name, default)
end

"""
    custom_id(ctx) -> String

Use this to identify which button, select menu, or modal was interacted with.

Get the [`custom_id`](@ref) for component interactions (buttons, selects) or modal submissions.

# Example
```julia
register_component!(client.command_tree, "action_", ctx -> begin
    id = custom_id(ctx)  # e.g. "action_delete" or "action_ban"
    respond(ctx; content="You triggered: \$id")
end)
```
"""
function custom_id(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return nothing
    cid = data.custom_id
    ismissing(cid) && return nothing
    return cid
end

"""
    selected_values(ctx) -> Vector{String}

Use this to retrieve the values selected by the user in a select menu component.

Get the selected values for a select menu interaction.

# Example
```julia
register_component!(client.command_tree, "color_select", ctx -> begin
    colors = selected_values(ctx)  # ["red", "blue"]
    respond(ctx; content="You picked: \$(join(colors, ", "))")
end)
```
"""
function selected_values(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return String[]
    vals = data.values
    ismissing(vals) && return String[]
    return vals
end

"""
    modal_values(ctx) -> Dict{String, String}

Use this to retrieve the values entered by the user in a modal form submission.

Get modal component values as a dictionary mapping [`custom_id`](@ref) to the input value.

# Example
```julia
register_modal!(client.command_tree, "feedback_form", ctx -> begin
    vals = modal_values(ctx)
    respond(ctx; content="Thanks! You said: \$(vals["message"])")
end)
```
"""
function modal_values(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return Dict{String, String}()
    rows = data.components
    ismissing(rows) && return Dict{String, String}()

    result = Dict{String, String}()
    for row in rows
        inner = row.components
        if !ismissing(inner)
            for comp in inner
                cid = comp.custom_id
                val = comp.value
                if !ismissing(cid) && !ismissing(val)
                    result[cid] = val
                end
            end
        end
    end
    return result
end

"""
    target(ctx::InteractionContext)

Use this to get the user or message that was right-clicked in a context menu command.

Get the target of a context menu interaction (User or Message command).
Returns the resolved User or Message object, or `nothing` if unavailable.

For User commands (`ApplicationCommandTypes.USER`), returns a [`User`](@ref).
For Message commands (`ApplicationCommandTypes.MESSAGE`), returns a [`Message`](@ref).

# Example
```julia
register_command!(client.command_tree, "User Info", "", ctx -> begin
    user = target(ctx)
    respond(ctx; content="User: \$(user.username)#\$(user.discriminator)")
end; type=ApplicationCommandTypes.USER)
```
"""
function target(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return nothing
    ismissing(data.target_id) && return nothing

    target_id = data.target_id
    resolved = data.resolved
    ismissing(resolved) && return nothing

    # User command — look in resolved.users then resolved.members
    if !ismissing(data.type) && data.type == ApplicationCommandTypes.USER
        if _is_present(resolved.users)
            user = get(resolved.users, string(target_id), nothing)
            !isnothing(user) && return user
        end
        return nothing
    end

    # Message command — look in resolved.messages
    if !ismissing(data.type) && data.type == ApplicationCommandTypes.MESSAGE
        if _is_present(resolved.messages)
            msg = get(resolved.messages, string(target_id), nothing)
            !isnothing(msg) && return msg
        end
        return nothing
    end

    return nothing
end

"""
    respond(ctx; content="", embeds=[], components=[], ephemeral=false, tts=false, files=nothing)

Use this to send an immediate response to a slash command or component interaction.

Send an interaction response. Automatically chooses between creating a new response
or editing a deferred one.

!!! warning
    You must call `respond` within **3 seconds** of receiving the interaction, unless
    you first call [`defer`](@ref). After deferring, you have up to 15 minutes.

# Example
```julia
@slash_command client "hello" "Say hello" function(ctx)
    respond(ctx; content="Hello, world!", ephemeral=true)
end
```
"""
function respond(ctx::InteractionContext;
    content::String = "",
    embeds::Vector = [],
    components::Vector = [],
    ephemeral::Bool = false,
    tts::Bool = false,
    files = nothing,
)
    data = Dict{String, Any}()
    !isempty(content) && (data["content"] = content)
    !isempty(embeds) && (data["embeds"] = embeds)
    !isempty(components) && (data["components"] = components)
    tts && (data["tts"] = true)
    ephemeral && (data["flags"] = 64)  # EPHEMERAL flag

    if ctx.deferred[]
        # Edit the deferred response
        app_id = ctx.client.application_id
        if isnothing(app_id)
            error("Cannot respond to deferred interaction: application_id not set (READY event may not have been processed)")
        end
        edit_original_interaction_response(
            ctx.client.ratelimiter, app_id, ctx.interaction.token;
            token=ctx.client.token, body=data, files
        )
    else
        response_type = ctx.interaction.type == InteractionTypes.MESSAGE_COMPONENT ?
            InteractionCallbackTypes.UPDATE_MESSAGE :
            InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE

        body = Dict("type" => response_type, "data" => data)
        create_interaction_response(
            ctx.client.ratelimiter, ctx.interaction.id, ctx.interaction.token;
            token=ctx.client.token, body, files
        )
    end
    ctx.responded[] = true
end

"""
    defer(ctx; ephemeral=false)

Use this when you need more than 3 seconds to process a command before responding.

Acknowledge the interaction and defer the response (shows a "thinking..." indicator).
This gives you 15 minutes to call [`respond`](@ref) or [`edit_response`](@ref).

!!! warning
    `defer` must itself be called within 3 seconds of receiving the interaction.
    Always defer at the top of your handler if the response may take time.

# Example
```julia
@slash_command client "slow" "Slow command" function(ctx)
    defer(ctx)
    sleep(5)
    respond(ctx; content="Done!")
end
```
"""
function defer(ctx::InteractionContext; ephemeral::Bool=false)
    response_type = ctx.interaction.type == InteractionTypes.MESSAGE_COMPONENT ?
        InteractionCallbackTypes.DEFERRED_UPDATE_MESSAGE :
        InteractionCallbackTypes.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE

    data = Dict{String, Any}()
    ephemeral && (data["flags"] = 64)

    body = Dict("type" => response_type, "data" => data)
    resp = create_interaction_response(
        ctx.client.ratelimiter, ctx.interaction.id, ctx.interaction.token;
        token=ctx.client.token, body
    )
    if resp.status < 300
        ctx.deferred[] = true
    else
        @warn "Failed to defer interaction response" status=resp.status body=String(resp.body)
    end
    return resp
end

"""
    edit_response(ctx; content=nothing, embeds=nothing, components=nothing, files=nothing)

Use this to modify your bot's response after it has already been sent.

Edit the original interaction response.

# Example
```julia
@slash_command client "countdown" "Start a countdown" function(ctx)
    respond(ctx; content="3...")
    sleep(1); edit_response(ctx; content="2...")
    sleep(1); edit_response(ctx; content="1...")
    sleep(1); edit_response(ctx; content="🚀 Go!")
end
```
"""
function edit_response(ctx::InteractionContext;
    content = nothing,
    embeds = nothing,
    components = nothing,
    files = nothing,
)
    app_id = ctx.client.application_id
    isnothing(app_id) && error("Cannot edit response: application_id not set")

    body = Dict{String, Any}()
    !isnothing(content) && (body["content"] = content)
    !isnothing(embeds) && (body["embeds"] = embeds)
    !isnothing(components) && (body["components"] = components)

    edit_original_interaction_response(
        ctx.client.ratelimiter, app_id, ctx.interaction.token;
        token=ctx.client.token, body, files
    )
end

"""
    followup(ctx; content="", embeds=[], components=[], ephemeral=false, files=nothing)

Use this to send additional messages after the initial response to an interaction.

Send a followup message to an interaction after the initial response.

# Example
```julia
@slash_command client "multi" "Send multiple messages" function(ctx)
    respond(ctx; content="Message 1")
    followup(ctx; content="Message 2")
    followup(ctx; content="Secret message", ephemeral=true)
end
```
"""
function followup(ctx::InteractionContext;
    content::String = "",
    embeds::Vector = [],
    components::Vector = [],
    ephemeral::Bool = false,
    files = nothing,
)
    app_id = ctx.client.application_id
    isnothing(app_id) && error("Cannot send followup: application_id not set")

    body = Dict{String, Any}()
    !isempty(content) && (body["content"] = content)
    !isempty(embeds) && (body["embeds"] = embeds)
    !isempty(components) && (body["components"] = components)
    ephemeral && (body["flags"] = 64)

    create_followup_message(
        ctx.client.ratelimiter, app_id, ctx.interaction.token;
        token=ctx.client.token, body, files
    )
end

"""
    show_modal(ctx; title::String, custom_id::String, components::Vector)

Use this to display a popup form for users to input data.

Show a modal dialog to the user.

!!! warning
    You **cannot** call [`defer`](@ref) before `show_modal`. Modals must be the
    first and only response to the interaction.

# Example
```julia
@slash_command client "feedback" "Give feedback" function(ctx)
    show_modal(ctx;
        title="Feedback Form",
        custom_id="feedback_form",
        components=[action_row([text_input(custom_id="message", label="Your feedback", style=TextInputStyles.PARAGRAPH)])]
    )
end
```
"""
function show_modal(ctx::InteractionContext;
    title::String,
    custom_id::String,
    components::Vector,
)
    body = Dict(
        "type" => InteractionCallbackTypes.MODAL,
        "data" => Dict(
            "title" => title,
            "custom_id" => custom_id,
            "components" => components,
        )
    )
    create_interaction_response(
        ctx.client.ratelimiter, ctx.interaction.id, ctx.interaction.token;
        token=ctx.client.token, body
    )
end
