# Macro-based decorators for registering commands and component handlers

# Map symbols to color hex values for @embed
const DISCORD_COLORS = Dict(
    :blurple => 0x5865F2,
    :green   => 0x57F287,
    :yellow  => 0xFEE75C,
    :fuchsia => 0xEB459E,
    :red     => 0xED4245,
    :white   => 0xFFFFFF,
    :black   => 0x23272A,
    :gold    => 0xF1C40F,
    :orange  => 0xE67E22,
    :blue    => 0x3498DB,
)

"""
    @on client EventType handler

Register an event handler using a clean decorator syntax.

# Example
```julia
@on client MessageCreate (c, event) -> println(event.message.content)

@on client ReadyEvent function(c, event)
    @info "Logged in as \$(event.user.username)"
end
```
"""
macro on(client, event_type, handler)
    quote
        $(@__MODULE__).on($(esc(handler)), $(esc(client)), $(esc(event_type)))
    end
end

"""
    @embed begin ... end

DSL for building Discord embeds quickly.

# Supported Keywords
- `title "text"`
- `description "text"`
- `url "url"`
- `color :symbol` or `0xHEX`
- `image "url"`
- `thumbnail "url"`
- `author "name" icon="url" url="url"`
- `footer "text" icon="url"`
- `field "name" "value" inline=true/false`
- `timestamp` (uses current time)

# Example
```julia
e = @embed begin
    title "Success"
    description "Operation completed"
    color :green
    field "ID" "123" inline=true
    timestamp
end
```
"""
macro embed(block)
    exprs = []
    push!(exprs, :(dict = Dict{String, Any}()))
    push!(exprs, :(fields = Dict{String, Any}[]))
    
    for line in block.args
        line isa LineNumberNode && continue
        !(line isa Expr) && continue
        
        cmd = line.args[1]
        args = line.args[2:end]
        
        if cmd == :title
            push!(exprs, :(dict["title"] = $(esc(args[1]))))
        elseif cmd == :description
            push!(exprs, :(dict["description"] = $(esc(args[1]))))
        elseif cmd == :url
            push!(exprs, :(dict["url"] = $(esc(args[1]))))
        elseif cmd == :color
            color_val = args[1]
            if color_val isa QuoteNode || (color_val isa Expr && color_val.head == :quote)
                push!(exprs, :(dict["color"] = get(DISCORD_COLORS, $(esc(color_val)), 0x000000)))
            else
                push!(exprs, :(dict["color"] = $(esc(color_val))))
            end
        elseif cmd == :image
            push!(exprs, :(dict["image"] = Dict("url" => $(esc(args[1])))))
        elseif cmd == :thumbnail
            push!(exprs, :(dict["thumbnail"] = Dict("url" => $(esc(args[1])))))
        elseif cmd == :timestamp
            push!(exprs, :(dict["timestamp"] = string(Dates.now()) * "Z"))
        elseif cmd == :author
            name = args[1]
            author_dict = :(Dict{String, Any}("name" => $(esc(name))))
            for arg in args[2:end]
                if arg isa Expr && arg.head == :kw
                    author_dict.args[1].args[2][string(arg.args[1])] = esc(arg.args[2]) # simplified for logic
                end
            end
            # Build author dict properly
            author_expr = :(a_dict = Dict{String, Any}("name" => $(esc(name))))
            for arg in args[2:end]
                if arg isa Expr && arg.head == :kw
                    key = string(arg.args[1])
                    if key == "icon" key = "icon_url" end
                    push!(author_expr.args, :(a_dict[$key] = $(esc(arg.args[2]))))
                end
            end
            push!(exprs, quote $author_expr; dict["author"] = a_dict end)
        elseif cmd == :footer
            text = args[1]
            footer_expr = :(f_dict = Dict{String, Any}("text" => $(esc(text))))
            for arg in args[2:end]
                if arg isa Expr && arg.head == :kw
                    key = string(arg.args[1])
                    if key == "icon" key = "icon_url" end
                    push!(footer_expr.args, :(f_dict[$key] = $(esc(arg.args[2]))))
                end
            end
            push!(exprs, quote $footer_expr; dict["footer"] = f_dict end)
        elseif cmd == :field
            name = args[1]
            val = args[2]
            f_expr = :(f = Dict{String, Any}("name" => $(esc(name)), "value" => string($(esc(val)))))
            for arg in args[3:end]
                if arg isa Expr && arg.head == :kw
                    push!(f_expr.args, :(f[$(string(arg.args[1]))] = $(esc(arg.args[2]))))
                end
            end
            push!(exprs, quote $f_expr; push!(fields, f) end)
        end
    end
    
    push!(exprs, :(if !isempty(fields) dict["fields"] = fields end))
    push!(exprs, :(dict))
    
    return quote
        let
            $(exprs...)
        end
    end
end

"""
    @check check_function

Use this macro to add permission checks or guards before a command executes.

Add a pre-execution check (guard) to the next `@slash_command`, `@user_command`,
or `@message_command`.
Checks are stacked — multiple `@check` macros accumulate and are
all drained when a command macro is invoked.

Check functions receive an [`InteractionContext`](@ref) and return `true` (pass)
or `false` (deny). If a check fails, the command handler is never called
and a default "permission denied" ephemeral message is sent.

# Built-in checks
- `has_permissions(perms...)` — require specific permissions
- `is_owner()` — require guild owner
- `is_in_guild()` — require guild context (not DMs)
- `cooldown(seconds; per=:user)` — rate-limit per user/guild/channel/global

# Example
```jldoctest
julia> @check has_permissions(:MANAGE_GUILD);

julia> @check is_owner();

julia> length(Accord._PENDING_CHECKS) # Verifies checks were queued
2
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

Use this macro to easily register a handler for incoming text messages.

Register a `MessageCreate` handler that automatically skips bot messages and
messages with missing `author` or `content`.

The handler receives `(client, message)` — the [`Message`](@ref) object directly.

# Example
```jldoctest
julia> client = Client("token");

julia> @on_message client (c, msg) -> "handled";

julia> length(client.event_handler.handlers[Accord.MessageCreate])
1
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

Use this macro to define slash commands that users can invoke with "/command".

Register a slash command with the client's command tree.

# Example
```jldoctest
julia> client = Client("token");

julia> # Simple command
       @slash_command client "greet" "Say hello" (ctx) -> "Hello!";

julia> # Command with options
       @slash_command client "double" "Double a number" [
           @option Integer "number" "Number to double" required=true
       ] (ctx) -> get_option(ctx, "number", 0) * 2;

julia> # Guild-specific command (Guild ID 123)
       @slash_command client 123 "info" "Server info" (ctx) -> "Guild command!";
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

Use this macro to handle clicks on buttons with a specific custom_id.

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

Use this macro to handle selections from dropdown menus.

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

Use this macro to handle form submissions from modal dialogs.

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

Use this macro to provide dynamic autocomplete suggestions as users type command options.

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

# Temporary storage for subcommands during @group macro expansion
const _GROUP_OPTIONS = Dict{Symbol, Vector{Dict{String, Any}}}()

"""
    @group client [guild_id] name description begin ... end

Organize related slash commands into a single top-level command with subcommands.

# Example
```julia
@group client "admin" "Moderation tools" begin
    @subcommand "ban" "Ban a user" [
        @option User "user" "The user to ban" required=true
    ] (ctx) -> respond(ctx, content="Banned!")

    @subcommand "kick" "Kick a user" (ctx) -> respond(ctx, content="Kicked!")
end
```
"""
macro group(client, args...)
    # Logic to handle optional guild_id and block
    block = args[end]
    if !(block isa Expr && block.head == :begin)
        error("@group requires a begin...end block as the last argument")
    end

    if length(args) == 3
        name, desc = args[1], args[2]
        guild_id = nothing
    elseif length(args) == 4
        guild_id, name, desc = args[1], args[2], args[3]
    else
        error("Invalid @group syntax. Expected: @group client [guild_id] name description begin...end")
    end

    # Use a unique key for this group to support nesting if needed
    group_key = gensym(:group)
    
    quote
        $(@__MODULE__)._GROUP_OPTIONS[$QuoteNode(group_key)] = Dict{String, Any}[]
        
        # Run the block which should contain @subcommand calls
        # We need to pass the group_key down
        let
            $(esc(block))
        end
        
        opts = pop!($(@__MODULE__)._GROUP_OPTIONS, $QuoteNode(group_key))
        
        # Register the top-level command with collected subcommands
        # Top level group doesn't have a handler of its own (usually)
        # but we provide a dummy one that just does nothing if called directly.
        if isnothing($guild_id)
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), (ctx) -> nothing;
                options=opts)
        else
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), (ctx) -> nothing;
                options=opts, guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))))
        end
    end
end

"""
    @subcommand name description [options] handler

Define a subcommand inside a `@group` block.
"""
macro subcommand(name, description, args...)
    handler = args[end]
    options = length(args) == 2 ? args[1] : :([])
    
    # This macro relies on being called inside @group which sets up the context.
    # However, macros are expanded independently. We'll find the last group key.
    
    quote
        # Get the current group being built (last added to the dict)
        # This is a bit hacky due to macro expansion order, but works for linear definitions.
        keys_list = collect(keys($(@__MODULE__)._GROUP_OPTIONS))
        if isempty(keys_list)
            error("@subcommand must be used inside a @group block")
        end
        current_key = last(keys_list)
        
        _checks_ = $(@__MODULE__).drain_pending_checks!()
        $(@__MODULE__).register_subcommand!($(@__MODULE__)._GROUP_OPTIONS[current_key], 
            $(esc(name)), $(esc(description)), $(esc(handler));
            options=$(esc(options)), checks=_checks_)
    end
end

"""
    @user_command client [guild_id] name handler

Use this macro to add right-click context menu commands on users.

Register a User Context Menu command (right-click on a user).
Context menu commands have no description or options.

# Example
```jldoctest
julia> client = Client("token");

julia> @user_command client "User Info" (ctx) -> "User Info";

julia> @user_command client 123 "Warn User" (ctx) -> "Warned";
```
"""
macro user_command(client, args...)
    if length(args) == 2
        # @user_command client name handler
        name, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), "", $(esc(handler));
                type=$(@__MODULE__).ApplicationCommandTypes.USER, checks=_checks_)
        end
    elseif length(args) == 3
        # @user_command client guild_id name handler
        guild_id, name, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), "", $(esc(handler));
                type=$(@__MODULE__).ApplicationCommandTypes.USER,
                guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))), checks=_checks_)
        end
    else
        error("Invalid @user_command syntax. Expected: @user_command client [guild_id] name handler")
    end
end

"""
    @message_command client [guild_id] name handler

Use this macro to add right-click context menu commands on messages.

Register a Message Context Menu command (right-click on a message).
Context menu commands have no description or options.

# Example
```jldoctest
julia> client = Client("token");

julia> @message_command client "Bookmark" (ctx) -> "Bookmarked";

julia> @message_command client 123 "Report" (ctx) -> "Reported";
```
"""
macro message_command(client, args...)
    if length(args) == 2
        # @message_command client name handler
        name, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), "", $(esc(handler));
                type=$(@__MODULE__).ApplicationCommandTypes.MESSAGE, checks=_checks_)
        end
    elseif length(args) == 3
        # @message_command client guild_id name handler
        guild_id, name, handler = args
        return quote
            _checks_ = $(@__MODULE__).drain_pending_checks!()
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), "", $(esc(handler));
                type=$(@__MODULE__).ApplicationCommandTypes.MESSAGE,
                guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))), checks=_checks_)
        end
    else
        error("Invalid @message_command syntax. Expected: @message_command client [guild_id] name handler")
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

Use this macro to define command options with types and validation rules.

Create a command option dict using a concise syntax. `Type` is one of:
`String`, `Integer`, `Boolean`, [`User`](@ref), `Channel`, [`Role`](@ref), `Mentionable`,
`Number`, or [`Attachment`](@ref).

# Examples
```jldoctest
julia> opt = @option String "query" "Search query" required=true;

julia> opt["name"]
"query"

julia> opt["type"] == 3 # STRING type
true

julia> opt = @option Integer "count" "How many" min_value=1 max_value=25;

julia> opt["min_value"]
1
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