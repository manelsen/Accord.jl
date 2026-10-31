# Interaction context — provides helpers for responding to interactions

"""
    InteractionContext

Use this in your slash command handlers to access interaction data and send responses.

Wraps an [`Interaction`](@ref) with convenience methods for responding. Holds a reference to the [`Client`](@ref).

!!! compat "Accord 0.1.0"
    `InteractionContext` and all interaction helpers are available since Accord 0.1.0.
"""
struct InteractionContext
    client::AbstractClient
    interaction::Interaction
    responded::Ref{Bool}
    deferred::Ref{Bool}
end

function InteractionContext(client::AbstractClient, interaction::Interaction)
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
    modal_values(ctx) -> Dict{String, Any}

Use this to retrieve what the user entered in a modal form submission.

Maps each input's [`custom_id`](@ref) to its value:

| Component | Value |
|:--|:--|
| [`text_input`](@ref) | `String` |
| [`radio_group`](@ref) | chosen `String`, or `nothing` |
| [`checkbox`](@ref) | `Bool` |
| [`checkbox_group`](@ref), select menus | `Vector{String}` |
| [`file_upload`](@ref) | `Vector{String}` of attachment ids (see [`modal_files`](@ref)) |

Inputs may be wrapped in a [`label`](@ref) or, in the older layout, an action row.

# Example
```julia
register_modal!(client.command_tree, "feedback_form", ctx -> begin
    vals = modal_values(ctx)
    respond(ctx; content="Thanks! You said: \$(vals["message"])")
end)
```
"""
function modal_values(ctx::InteractionContext)
    result = Dict{String, Any}()
    data = ctx.interaction.data
    ismissing(data) && return result
    top = data.components
    ismissing(top) && return result
    foreach(c -> _collect_modal_value!(result, c), top)
    return result
end

# Walk a submitted modal component: Labels wrap one child, action rows many.
function _collect_modal_value!(result::Dict{String, Any}, c::Component)
    child = c.component
    ismissing(child) || _collect_modal_value!(result, child)
    kids = c.components
    ismissing(kids) || foreach(k -> _collect_modal_value!(result, k), kids)
    cid = c.custom_id
    ismissing(cid) && return result
    if !ismissing(c.values)
        result[cid] = c.values
    elseif !ismissing(c.value)
        result[cid] = c.value          # String, Bool or nothing (empty radio group)
    end
    return result
end

"""
    modal_files(ctx, custom_id) -> Vector{Attachment}

The files a user submitted through the [`file_upload`](@ref) with `custom_id`.
Empty when the field is absent or nothing was uploaded.
"""
function modal_files(ctx::InteractionContext, custom_id::AbstractString)
    ids = get(modal_values(ctx), custom_id, nothing)
    ids isa AbstractVector || return Attachment[]
    data = ctx.interaction.data
    resolved = ismissing(data) ? missing : data.resolved
    atts = ismissing(resolved) ? missing : resolved.attachments
    (ismissing(atts) || isnothing(atts)) && return Attachment[]
    out = Attachment[]
    for id in ids
        raw = get(atts, Symbol(id), get(atts, string(id), nothing))
        isnothing(raw) && continue
        push!(out, raw isa Attachment ? raw : JSON3.read(JSON3.write(raw), Attachment))
    end
    return out
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
    flags = nothing,
    allowed_mentions = nothing,
    poll = nothing,
)
    data = _message_body(; content, embeds, components, ephemeral, tts, flags, allowed_mentions, poll)

    if ctx.deferred[]
        # Edit the deferred response
        edit_original_interaction_response(ctx.client, _application_id(ctx, "respond to deferred interaction"),
                                           ctx.interaction.token; body=data, files)
    else
        response_type = ctx.interaction.type == InteractionTypes.MESSAGE_COMPONENT ?
            InteractionCallbackTypes.UPDATE_MESSAGE :
            InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE

        body = Dict("type" => response_type, "data" => data)
        resp = create_interaction_response(ctx.client, ctx.interaction.id, ctx.interaction.token; body, files)

        if resp.status >= 300
            @warn "Failed to respond to interaction" status=resp.status body=String(resp.body)
            return resp
        end
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

    body = Dict("type" => response_type, "data" => _message_body(; ephemeral))
    resp = create_interaction_response(ctx.client, ctx.interaction.id, ctx.interaction.token; body)
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
    allowed_mentions = nothing,
)
    body = _message_body(; omit_empty=false, content, embeds, components, allowed_mentions)
    edit_original_interaction_response(ctx.client, _application_id(ctx, "edit response"),
                                       ctx.interaction.token; body, files)
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
    tts::Bool = false,
    files = nothing,
    flags = nothing,
    allowed_mentions = nothing,
    poll = nothing,
)
    body = _message_body(; content, embeds, components, ephemeral, tts, flags, allowed_mentions, poll)
    create_followup_message(ctx.client, _application_id(ctx, "send followup"), ctx.interaction.token; body, files)
end

# The application id is learned from READY; interaction webhooks need it.
function _application_id(ctx::InteractionContext, action::AbstractString)
    app_id = ctx.client.application_id
    isnothing(app_id) && error("Cannot $action: application_id not set (READY event may not have been processed)")
    return app_id
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
        components=[label("Your feedback", text_input(custom_id="message", style=TextInputStyles.PARAGRAPH))]
    )
end
```
"""
function show_modal(ctx::InteractionContext;
    title::String,
    custom_id::String,
    components::Vector,
)
    ctx.responded[] && throw(ArgumentError(
        "Cannot show modal: interaction already responded. " *
        "show_modal must be the first and only response to an interaction."
    ))
    ctx.deferred[] && throw(ArgumentError(
        "Cannot show modal: interaction already deferred. " *
        "Modals cannot follow a defer() call."
    ))
    body = Dict(
        "type" => InteractionCallbackTypes.MODAL,
        "data" => Dict(
            "title" => title,
            "custom_id" => custom_id,
            "components" => components,
        )
    )
    result = create_interaction_response(ctx.client, ctx.interaction.id, ctx.interaction.token; body)
    ctx.responded[] = true
    return result
end
