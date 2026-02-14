# Command tree — registration and syncing of application commands

"""
    CommandDefinition

A registered application command with its handler.
"""
struct CommandDefinition
    name::String
    description::String
    type::Int  # ApplicationCommandTypes
    options::Vector{Dict{String, Any}}
    handler::Function
    guild_id::Optional{Snowflake}
    checks::Vector{Function}
end

"""
    CommandTree

Manages application command registration and dispatch.
"""
mutable struct CommandTree
    commands::Dict{String, CommandDefinition}
    component_handlers::Dict{String, Function}  # custom_id → handler
    modal_handlers::Dict{String, Function}       # custom_id → handler
    autocomplete_handlers::Dict{String, Function} # command_name → handler
end

CommandTree() = CommandTree(
    Dict{String, CommandDefinition}(),
    Dict{String, Function}(),
    Dict{String, Function}(),
    Dict{String, Function}(),
)

"""
    register_command!(tree, name, description, handler; type=1, options=[], guild_id=missing)

Register a slash command.
"""
function register_command!(tree::CommandTree, name::String, description::String, handler::Function;
    type::Int = ApplicationCommandTypes.CHAT_INPUT,
    options::Vector = [],
    guild_id::Optional{Snowflake} = missing,
    checks::Vector = Function[],
)
    tree.commands[name] = CommandDefinition(name, description, type, options, handler, guild_id, Function[checks...])
end

"""
    register_component!(tree, custom_id, handler)

Register a handler for a component interaction (button, select menu).
"""
function register_component!(tree::CommandTree, custom_id::String, handler::Function)
    tree.component_handlers[custom_id] = handler
end

"""
    register_modal!(tree, custom_id, handler)

Register a handler for a modal submission.
"""
function register_modal!(tree::CommandTree, custom_id::String, handler::Function)
    tree.modal_handlers[custom_id] = handler
end

"""
    register_autocomplete!(tree, command_name, handler)

Register an autocomplete handler for a command.
"""
function register_autocomplete!(tree::CommandTree, command_name::String, handler::Function)
    tree.autocomplete_handlers[command_name] = handler
end

"""
    sync_commands!(client, tree; guild_id=nothing)

Sync registered commands with Discord.
`client` should be an `Accord.Client` instance.
If guild_id is provided, syncs as guild commands (instant).
Otherwise syncs as global commands (up to 1h propagation).
"""
function sync_commands!(client, tree::CommandTree; guild_id=nothing)
    app_id = client.application_id
    isnothing(app_id) && error("Client application_id not set. Wait for READY event first.")

    # Separate guild and global commands
    global_cmds = Dict{String, Any}[]
    guild_cmds = Dict{Snowflake, Vector{Dict{String, Any}}}()

    for (name, cmd) in tree.commands
        payload = Dict{String, Any}(
            "name" => cmd.name,
            "type" => cmd.type,
        )
        # Context menu commands (USER, MESSAGE) must not include description
        if cmd.type == ApplicationCommandTypes.CHAT_INPUT
            payload["description"] = cmd.description
        end
        !isempty(cmd.options) && (payload["options"] = cmd.options)

        if !ismissing(cmd.guild_id)
            cmds = get!(guild_cmds, cmd.guild_id, Dict{String, Any}[])
            push!(cmds, payload)
        elseif !isnothing(guild_id)
            cmds = get!(guild_cmds, Snowflake(guild_id), Dict{String, Any}[])
            push!(cmds, payload)
        else
            push!(global_cmds, payload)
        end
    end

    # Sync global commands
    if !isempty(global_cmds)
        bulk_overwrite_global_application_commands(
            client.ratelimiter, app_id;
            token=client.token, body=global_cmds
        )
        @info "Synced $(length(global_cmds)) global commands"
    end

    # Sync guild commands
    for (gid, cmds) in guild_cmds
        bulk_overwrite_guild_application_commands(
            client.ratelimiter, app_id, gid;
            token=client.token, body=cmds
        )
        @info "Synced $(length(cmds)) commands to guild $(gid)"
    end
end

"""
    dispatch_interaction!(tree, client, interaction)

Route an interaction to the appropriate handler.
`client` should be an `Accord.Client` instance.
"""
function dispatch_interaction!(tree::CommandTree, client, interaction::Interaction)
    ctx = InteractionContext(client, interaction)

    if interaction.type == InteractionTypes.APPLICATION_COMMAND
        data = interaction.data
        ismissing(data) && return
        cmd_name = data.name
        ismissing(cmd_name) && return

        cmd = get(tree.commands, cmd_name, nothing)
        if !isnothing(cmd)
            # Run pre-execution checks (guards)
            if !isempty(cmd.checks)
                run_checks(cmd.checks, ctx) || return
            end
            try
                cmd.handler(ctx)
            catch e
                @error "Error in command handler" command=cmd_name exception=(e, catch_backtrace())
            end
        else
            @warn "Unknown command" name=cmd_name
        end

    elseif interaction.type == InteractionTypes.MESSAGE_COMPONENT
        data = interaction.data
        ismissing(data) && return

        cid = data.custom_id
        ismissing(cid) && return
        # Try exact match first, then prefix match
        handler = get(tree.component_handlers, cid, nothing)
        if isnothing(handler)
            for (pattern, h) in tree.component_handlers
                if startswith(cid, pattern)
                    handler = h
                    break
                end
            end
        end

        if !isnothing(handler)
            try
                handler(ctx)
            catch e
                @error "Error in component handler" custom_id=cid exception=(e, catch_backtrace())
            end
        end

    elseif interaction.type == InteractionTypes.APPLICATION_COMMAND_AUTOCOMPLETE
        data = interaction.data
        ismissing(data) && return
        ac_name = data.name
        ismissing(ac_name) && return

        handler = get(tree.autocomplete_handlers, ac_name, nothing)
        if !isnothing(handler)
            try
                handler(ctx)
            catch e
                @error "Error in autocomplete handler" command=ac_name exception=(e, catch_backtrace())
            end
        end

    elseif interaction.type == InteractionTypes.MODAL_SUBMIT
        data = interaction.data
        ismissing(data) && return

        modal_cid = data.custom_id
        ismissing(modal_cid) && return

        handler = get(tree.modal_handlers, modal_cid, nothing)
        if !isnothing(handler)
            try
                handler(ctx)
            catch e
                @error "Error in modal handler" custom_id=modal_cid exception=(e, catch_backtrace())
            end
        end
    end
end
