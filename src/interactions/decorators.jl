# Macro-based decorators for registering commands and component handlers

"""
    @on_message client handler

Register a `MessageCreate` handler that automatically skips bot messages and
messages with missing `author` or `content`.

The handler receives `(client, message)` — the `Message` object directly.

# Example
```julia
@on_message client function(c, msg)
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

@slash_command client :guild_id "double" "Double a number" [
    Dict("name" => "number", "type" => 4, "description" => "Number to double", "required" => true)
] function(ctx)
    n = get_option(ctx, "number", 0)
    respond(ctx; content="Result: \$(n * 2)")
end
```
"""
macro slash_command(client, args...)
    if length(args) == 3
        # @slash_command client name description handler
        name, desc, handler = args
        return quote
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler)))
        end
    elseif length(args) == 4
        # Could be @slash_command client guild_id name description handler 
        # OR @slash_command client name description options handler
        arg1, arg2, arg3, arg4 = args
        
        if arg3 isa Expr && arg3.head == :vect
            # @slash_command client name description options handler
            name, desc, options, handler = arg1, arg2, arg3, arg4
            return quote
                $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                    options=$(esc(options)))
            end
        else
            # @slash_command client guild_id name description handler
            guild_id, name, desc, handler = arg1, arg2, arg3, arg4
            return quote
                $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                    guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))))
            end
        end
    elseif length(args) == 5
        # @slash_command client guild_id name description options handler
        guild_id, name, desc, options, handler = args
        return quote
            $(@__MODULE__).register_command!($(esc(client)).command_tree, $(esc(name)), $(esc(desc)), $(esc(handler));
                options=$(esc(options)), guild_id=$(@__MODULE__).Snowflake($(esc(guild_id))))
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