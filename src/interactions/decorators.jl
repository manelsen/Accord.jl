# Macro-based decorators for registering commands and component handlers

"""
    @check check_function

Add a pre-execution check (guard) to the next `@slash_command`.
Checks are stacked — multiple `@check` macros accumulate and are
all drained when `@slash_command` is invoked.

Check functions receive an `InteractionContext` and return `true` (pass)
or `false` (deny). If a check fails, the command handler is never called
and a default "permission denied" ephemeral message is sent.

# Built-in checks
- `has_permissions(perms...)` — require specific permissions
- `is_owner()` — require guild owner
- `is_in_guild()` — require guild context (not DMs)

# Example
```julia
@check has_permissions(:MANAGE_GUILD)
@check is_owner()
@slash_command client "nuke" "Owner-only danger command" function(ctx)
    respond(ctx; content="💥 Boom!")
end
```
"""
macro check(expr)
    quote
        lock($(@__MODULE__)._CHECKS_LOCK) do
            push!($(@__MODULE__)._PENDING_CHECKS, $(esc(expr)))
        end
    end
end

"""
    @on_message client handler

Register a `MessageCreate` handler that automatically skips bot messages and
messages with missing `author` or `content`.

The handler receives `(client, message)` — the `Message` object directly.

# Example
```julia
@on_message client (c, msg) -> begin
    msg.content == "!ping" && reply(c, msg; content="Pong!")
end
```
"""
macro on_message(client, handler)
    quote
        $(@__MODULE__).on($(esc(client)), $(@__MODULE__).MessageCreate) do _c_, _event_
            _msg_ = _event_.message
            ismissing(_msg_.author) && return
            ismissing(_msg_.content) && return
            !ismissing(_msg_.author.bot) && _msg_.author.bot == true && return
            $(esc(handler))(_c_, _msg_)
        end
    end
end

"""
    @slash_command client [guild_id] name description [options] handler

Register a slash command with the client's command tree.

# Example
```julia
@slash_command client "greet" "Say hello" function(ctx)
    respond(ctx; content="Hello!")
end

@slash_command client "double" "Double a number" [
    @option Integer "number" "Number to double" required=true
] function(ctx)
    n = get_option(ctx, "number", 0)
    respond(ctx; content="Result: \$(n * 2)")
end

# Guild-specific command:
@slash_command client :guild_id "info" "Server info" function(ctx)
    respond(ctx; content="Guild command!")
end
```
"""
macro slash_command(client, args...)
    if length(args) == 3
        # @slash_command client name description handler
        name, desc, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                checks=_checks_)
        end
    elseif length(args) == 4
        # Could be @slash_command client guild_id name description handler 
        # OR @slash_command client name description options handler
        arg1, arg2, arg3, arg4 = args
        
        if arg3 isa Expr && arg3.head == :vect
            # @slash_command client name description options handler
            name, desc, options, handler = arg1, arg2, arg3, arg4
            return quote
                _checks_ = $(@__MODULE__).drain_pending_checks!()
                $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                    options=$(esc(options)), checks=_checks_)
            end
        else
            # @slash_command client guild_id name description handler
            guild_id, name, desc, handler = arg1, arg2, arg3, arg4
            return quote
                _checks_ = $(@__MODULE__).drain_pending_checks!()
                $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                    guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))), checks=_checks_)
            end
        end
    elseif length(args) == 5
        # @slash_command client guild_id name description options handler
        guild_id, name, desc, options, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                options=$(esc(options)), guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))), checks=_checks_)
        end
    else
        error("Invalid @slash_command syntax. Expected: @slash_command client [guild_id] name description [options] handler")
    end
end

"""
    @button_handler client custom_id handler

Register a button click handler.

# Example
```julia
@button_handler client "my_button" function(ctx)
    respond(ctx; content="Button clicked!", ephemeral=true)
end
```
"""
macro button_handler(client, custom_id, handler)
    quote
        $(@__MODULE__).register_component!($(esc(client)).command_tree, $(esc(custom_id)), $(esc(handler)))
    end
end

"""
    @select_handler client custom_id handler

Register a select menu handler.

# Example
```julia
@select_handler client "color_select" function(ctx)
    values = selected_values(ctx)
    respond(ctx; content="You selected: \$(join(values, ", "))")
end
```
"""
macro select_handler(client, custom_id, handler)
    quote
        $(@__MODULE__).register_component!($(esc(client)).command_tree, $(esc(custom_id)), $(esc(handler)))
    end
end

"""
    @modal_handler client custom_id handler

Register a modal submission handler.

# Example
```julia
@modal_handler client "feedback_form" function(ctx)
    values = modal_values(ctx)
    respond(ctx; content="Thanks for your feedback: \$(values["feedback"])")
end
```
"""
macro modal_handler(client, custom_id, handler)
    quote
        $(@__MODULE__).register_modal!($(esc(client)).command_tree, $(esc(custom_id)), $(esc(handler)))
    end
end

"""
    @autocomplete client command_name handler

Register an autocomplete handler for a slash command.

# Example
```julia
@autocomplete client "search" function(ctx)
    query = get_option(ctx, "query", "")
    choices = [Dict("name" => r, "value" => r) for r in search_results(query)]
    body = Dict("type" => InteractionCallbackTypes.APPLICATION_COMMAND_AUTOCOMPLETE_RESULT,
                "data" => Dict("choices" => choices))
    create_interaction_response(ctx.client.ratelimiter, ctx.interaction.id, ctx.interaction.token;
        token=ctx.client.token, body)
end
```
"""
macro autocomplete(client, command_name, handler)
    quote
        $(@__MODULE__).register_autocomplete!($(esc(client)).command_tree, $(esc(command_name)), $(esc(handler)))
    end
end

# Map symbols to ApplicationCommandOptionTypes constants
const _OPTION_TYPE_MAP = Dict{Symbol, Int}(
    :String      => ApplicationCommandOptionTypes.STRING,
    :Integer     => ApplicationCommandOptionTypes.INTEGER,
    :Boolean     => ApplicationCommandOptionTypes.BOOLEAN,
    :User        => ApplicationCommandOptionTypes.USER,
    :Channel     => ApplicationCommandOptionTypes.CHANNEL,
    :Role        => ApplicationCommandOptionTypes.ROLE,
    :Mentionable => ApplicationCommandOptionTypes.MENTIONABLE,
    :Number      => ApplicationCommandOptionTypes.NUMBER,
    :Attachment  => ApplicationCommandOptionTypes.ATTACHMENT,
)

"""
    @option Type name description [kwargs...]

Create a command option dict using a concise syntax. `Type` is one of:
`String`, `Integer`, `Boolean`, `User`, `Channel`, `Role`, `Mentionable`,
`Number`, or `Attachment`.

# Examples
```julia
@option String "query" "Search query" required=true
@option Integer "count" "How many" required=true min_value=1 max_value=25
@option Channel "target" "Target channel"

# Use inside @slash_command:
@slash_command client "search" "Search for items" [
    @option String "query" "Search query" required=true
    @option Integer "limit" "Max results" min_value=1 max_value=25
] function(ctx)
    q = get_option(ctx, "query", "")
    respond(ctx; content="Searching for: \$q")
end
```
"""
macro option(type_sym, name, description, kwargs...)
    if !haskey(_OPTION_TYPE_MAP, type_sym)
        error("Unknown option type :$type_sym. Expected one of: $(join(sort(collect(keys(_OPTION_TYPE_MAP))), ", "))")
    end
    type_val = _OPTION_TYPE_MAP[type_sym]

    kw_exprs = [Expr(:kw, ex.args[1], esc(ex.args[2])) for ex in kwargs if ex isa Expr && ex.head == :(=)]

    quote
        $(@__MODULE__).command_option(;
            type=$type_val,
            name=$(esc(name)),
            description=$(esc(description)),
            $(kw_exprs...),
        )
    end
end