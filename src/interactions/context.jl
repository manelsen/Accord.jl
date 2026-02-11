# Interaction context — provides helpers for responding to interactions

"""
    InteractionContext

Wraps an Interaction with convenience methods for responding.
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

"""Get the user who triggered the interaction."""
function Base.getproperty(ctx::InteractionContext, name::Symbol)
    if name === :user || name === :author
        i = getfield(ctx, :interaction)
        # Prefer member.user in guild contexts, fall back to user
        if _is_present(i.member) && _is_present(i.member.user)
            return i.member.user
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

"""Get the interaction data options as a Dict."""
function get_options(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return Dict{String, Any}()
    ismissing(data.options) && return Dict{String, Any}()

    result = Dict{String, Any}()
    for opt in data.options
        if !ismissing(opt.value)
            result[opt.name] = opt.value
        end
    end
    return result
end

"""Get a specific option value by name."""
function get_option(ctx::InteractionContext, name::String, default=nothing)
    opts = get_options(ctx)
    get(opts, name, default)
end

"""Get the custom_id for component interactions."""
function custom_id(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return nothing
    ismissing(data.custom_id) && return nothing
    return data.custom_id
end

"""Get the selected values for select menu interactions."""
function selected_values(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return String[]
    ismissing(data.values) && return String[]
    return data.values
end

"""Get modal component values as a Dict{String, String}."""
function modal_values(ctx::InteractionContext)
    data = ctx.interaction.data
    ismissing(data) && return Dict{String, String}()
    ismissing(data.components) && return Dict{String, String}()

    result = Dict{String, String}()
    for row in data.components
        if !ismissing(row.components)
            for comp in row.components
                if !ismissing(comp.custom_id) && !ismissing(comp.value)
                    result[comp.custom_id] = comp.value
                end
            end
        end
    end
    return result
end

"""
    target(ctx::InteractionContext)

Get the target of a context menu interaction (User or Message command).
Returns the resolved User or Message object, or `nothing` if unavailable.

For User commands (`ApplicationCommandTypes.USER`), returns a `User`.
For Message commands (`ApplicationCommandTypes.MESSAGE`), returns a `Message`.
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
    respond(ctx; kwargs...)

Send an interaction response. Automatically chooses the right response type.
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
        if isnothing(ctx.client.application_id)
            error("Cannot respond to deferred interaction: application_id not set (READY event may not have been processed)")
        end
        edit_original_interaction_response(
            ctx.client.ratelimiter, ctx.client.application_id, ctx.interaction.token;
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

Acknowledge the interaction and defer the response (shows "thinking...").
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
    edit_response(ctx; kwargs...)

Edit the original interaction response.
"""
function edit_response(ctx::InteractionContext;
    content = nothing,
    embeds = nothing,
    components = nothing,
    files = nothing,
)
    body = Dict{String, Any}()
    !isnothing(content) && (body["content"] = content)
    !isnothing(embeds) && (body["embeds"] = embeds)
    !isnothing(components) && (body["components"] = components)

    edit_original_interaction_response(
        ctx.client.ratelimiter, ctx.client.application_id, ctx.interaction.token;
        token=ctx.client.token, body, files
    )
end

"""
    followup(ctx; kwargs...)

Send a followup message to an interaction.
"""
function followup(ctx::InteractionContext;
    content::String = "",
    embeds::Vector = [],
    components::Vector = [],
    ephemeral::Bool = false,
    files = nothing,
)
    body = Dict{String, Any}()
    !isempty(content) && (body["content"] = content)
    !isempty(embeds) && (body["embeds"] = embeds)
    !isempty(components) && (body["components"] = components)
    ephemeral && (body["flags"] = 64)

    create_followup_message(
        ctx.client.ratelimiter, ctx.client.application_id, ctx.interaction.token;
        token=ctx.client.token, body, files
    )
end

"""
    show_modal(ctx; title, custom_id, components)

Show a modal dialog to the user.
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
