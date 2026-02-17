# Command tree — registration and syncing of application commands

"""
    CommandDefinition

Internal struct to store registered slash commands and their associated handlers.
This is used by [`CommandTree`](@ref) to track available commands.

# Fields
- `name::String`: Name of the command (1-32 characters).
- `description::String`: Description of the command (1-100 characters).
- `type::Int`: The [`ApplicationCommandTypes`](@ref) (e.g., CHAT_INPUT, USER, MESSAGE).
- `options::Vector{Dict{String, Any}}`: List of parameters/options for the command.
- `handler::Function`: The function to execute when the command is triggered.
- `guild_id::Optional{Snowflake}`: If set, the command is specific to this guild.
- `checks::Vector{Function}`: List of check functions that must pass for the command to run.
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

Organizes and routes slash commands, components, and modal handlers.
The `client.command_tree` field holds the instance used by the bot.

!!! compat "Accord 0.1.0"
    `CommandTree` and the declarative command registration API are available since Accord 0.1.0.

# Fields
- `commands::Dict{String, CommandDefinition}`: Map of command names to definitions.
- `component_handlers::Dict{String, Function}`: Map of custom_ids to component handlers.
- `component_prefix_handlers::Dict{String, Function}`: Map of custom_id prefixes to handlers.
- `modal_handlers::Dict{String, Function}`: Map of custom_ids to modal handlers.
- `autocomplete_handlers::Dict{String, Function}`: Map of command names to autocomplete handlers.

See [`register_command!`](@ref), [`sync_commands!`](@ref).
"""
mutable struct CommandTree
    commands::Dict{String, CommandDefinition}
    component_handlers::Dict{String, Function}        # custom_id → handler
    component_prefix_handlers::Dict{String, Function} # custom_id prefix → handler
    modal_handlers::Dict{String, Function}             # custom_id → handler
    autocomplete_handlers::Dict{String, Function}       # command_name → handler
end

CommandTree() = CommandTree(
    Dict{String, CommandDefinition}(),
    Dict{String, Function}(),
    Dict{String, Function}(),
    Dict{String, Function}(),
    Dict{String, Function}(),
)

"""
    register_command!(tree::CommandTree, name::String, description::String, handler::Function; type=1, options=[], guild_id=missing, checks=[])

Register a new application command (slash command).

Use this to define a command that users can invoke via `/name`. The handler function
should accept a single argument: the [`InteractionContext`](@ref).

# Arguments
- `tree::CommandTree`: The command tree to register into (usually `client.command_tree`).
- `name::String`: The command name (lowercase, no spaces).
- `description::String`: Help text shown to the user.
- `handler::Function`: Function called when command is invoked.

# Keyword Arguments
- `type::Int`: Command type (default: `1` for Chat Input). See [`ApplicationCommandTypes`](@ref).
- `options::Vector`: List of arguments/parameters for the command.
- `guild_id::Optional{Snowflake}`: If provided, registers as a guild-specific command (faster updates) instead of global.
- `checks::Vector{Function}`: List of functions `ctx -> Bool` that must return true for the command to run.

# Example
```julia
register_command!(client.command_tree, "ping", "Checks latency", ctx -> begin
    reply(ctx, "Pong!")
end)
```
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
    register_subcommand!(parent_options::Vector, name::String, description::String, handler::Function; options=[], checks=[])

Register a subcommand into a list of options for a parent command or group.
Internal helper used by the `@group` and `@subcommand` macros.
"""
function register_subcommand!(parent_options::Vector, name::String, description::String, handler::Function;
    options::Vector = [],
    checks::Vector = Function[],
)
    push!(parent_options, Dict{String, Any}(
        "type" => ApplicationCommandOptionTypes.SUB_COMMAND,
        "name" => name,
        "description" => description,
        "options" => options,
        "_handler" => handler, # Internal marker for routing
        "_checks" => checks
    ))
end

"""
    register_component!(tree::CommandTree, custom_id::String, handler::Function)

Register a handler for a Message Component (button or select menu).

Use this to handle interactions from buttons or dropdowns. The `custom_id` can be
an exact match or a prefix (if no exact match is found).

# Arguments
- `tree::CommandTree`: The command tree.
- `custom_id::String`: The identifier string assigned to the component. Use "prefix*" for prefix matching.
- `handler::Function`: Function `ctx -> Any` called when the component is used.

# Example
```julia
# Register a button handler
register_component!(client.command_tree, "click_one", ctx -> begin
    reply(ctx, "Button clicked!")
end)

# Register a prefix handler
register_component!(client.command_tree, "user_select:*", ctx -> begin
    id = split(ctx.interaction.data.custom_id, ":")[2]
    reply(ctx, "Selected user \$id")
end)
```
"""
function register_component!(tree::CommandTree, custom_id::String, handler::Function)
    if endswith(custom_id, "*")
        prefix = custom_id[1:end-1]
        tree.component_prefix_handlers[prefix] = handler
    else
        tree.component_handlers[custom_id] = handler
    end
end

"""
    register_modal!(tree::CommandTree, custom_id::String, handler::Function)

Register a handler for a Modal submission.

Use this to process form data submitted by users via Modals.

# Arguments
- `tree::CommandTree`: The command tree.
- `custom_id::String`: The identifier string assigned to the modal.
- `handler::Function`: Function `ctx -> Any` called when the modal is submitted.

# Example
```julia
register_modal!(client.command_tree, "feedback_form", ctx -> begin
    input = ctx.interaction.data.components[1].components[1].value
    reply(ctx, "Received: \$input")
end)
```
"""
function register_modal!(tree::CommandTree, custom_id::String, handler::Function)
    tree.modal_handlers[custom_id] = handler
end

"""
    register_autocomplete!(tree::CommandTree, command_name::String, handler::Function)

Register an autocomplete handler for a slash command option.

Use this to provide dynamic choices as the user types an argument.

# Arguments
- `tree::CommandTree`: The command tree.
- `command_name::String`: The name of the command to attach autocomplete to.
- `handler::Function`: Function `ctx -> Any` called on autocomplete interaction.

# Example
```julia
register_autocomplete!(client.command_tree, "search", ctx -> begin
    # ... logic to return choices ...
end)
```
"""
function register_autocomplete!(tree::CommandTree, command_name::String, handler::Function)
    tree.autocomplete_handlers[command_name] = handler
end

"""
    sync_commands!(client, tree::CommandTree; guild_id=nothing)

Upload registered commands to Discord.

Use this to update the command list visible to users. Global commands can take up to
1 hour to propagate, while guild commands are instant.

!!! warning
    This endpoint is rate-limited. During development, use `guild_id` to sync
    to a single test server for instant updates. Only sync globally for production.

# Arguments
- `client`: The [`Client`](@ref) instance.
- `tree::CommandTree`: The command tree containing commands to sync.

# Keyword Arguments
- `guild_id::Optional{Snowflake}`: If provided, only sync commands for this specific guild.
  If omitted, syncs global commands AND all guild-specific commands registered in the tree.

# Example
```julia
on(client, ReadyEvent) do c, event
    sync_commands!(c, c.command_tree)
end
```
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

function _dispatch_command(handler::Function, checks::Vector{Function}, options::Vector, ctx::InteractionContext)
    # 1. Run checks for this level
    if !isempty(checks)
        run_checks(checks, ctx) || return
    end

    # 2. Check if we have subcommands in the data
    data = ctx.interaction.data
    ismissing(data) && return
    
    # Nested subcommand data is usually in data.options
    sub_data = ismissing(data.options) ? nothing : first(data.options)
    
    if !isnothing(sub_data) && sub_data.type in (ApplicationCommandOptionTypes.SUB_COMMAND, ApplicationCommandOptionTypes.SUB_COMMAND_GROUP)
        # Find the subcommand definition in our options
        sub_name = sub_data.name
        sub_def_idx = findfirst(opt -> get(opt, "name", "") == sub_name, options)
        
        if !isnothing(sub_def_idx)
            sub_def = options[sub_def_idx]
            if haskey(sub_def, "_handler")
                # Found nested handler, recurse!
                # We need to shift the context or just pass it along
                # Discord subcommands are nested, but InteractionContext points to the root.
                # The handler can use get_option to find nested values.
                return _dispatch_command(sub_def["_handler"], sub_def["_checks"], get(sub_def, "options", []), ctx)
            end
        end
    end

    # 3. No more subcommands to route, call the handler
    try
        handler(ctx)
    catch e
        @error "Error in command handler" exception=(e, catch_backtrace())
    end
end

"""
    dispatch_interaction!(tree::CommandTree, client, interaction::Interaction)

Route an incoming interaction to the appropriate handler.

Internal function called by the `InteractionCreate` event handler.
It matches the interaction type and ID to a registered handler in the tree.

# Arguments
- `tree::CommandTree`: The command tree.
- `client`: The [`Client`](@ref) instance.
- `interaction::Interaction`: The interaction object received from the gateway.

# Returns
- The result of the handler function, or `nothing` if no handler was found.

# Example
```julia
# This is wired automatically by Client, but can be called manually:
on(client, InteractionCreate) do c, event
    dispatch_interaction!(c.command_tree, c, event.interaction)
end
```
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
            # Recursive routing for subcommands
            _dispatch_command(cmd.handler, cmd.checks, cmd.options, ctx)
        else
            @warn "Unknown command" name=cmd_name
        end

    elseif interaction.type == InteractionTypes.MESSAGE_COMPONENT
        data = interaction.data
        ismissing(data) && return

        cid = data.custom_id
        ismissing(cid) && return
        # Try exact match first
        handler = get(tree.component_handlers, cid, nothing)
        
        # Then try prefix matches (only if no exact match)
        if isnothing(handler)
            for (prefix, h) in tree.component_prefix_handlers
                if startswith(cid, prefix)
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
