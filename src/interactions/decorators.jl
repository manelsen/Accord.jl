# Macro-based decorators for registering commands and component handlers

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
        return esc(quote
            register_command!($client.command_tree, $name, $desc, $handler)
        end)
    elseif length(args) == 4
        # Could be guild_id or options
        arg1, name, desc, handler = args
        if arg1 isa Expr && arg1.head == :vect
            # @slash_command client [options] name description handler — unlikely
            error("Invalid @slash_command syntax")
        else
            # @slash_command client guild_id name description handler
            guild_id = arg1
            return esc(quote
                register_command!($client.command_tree, $name, $desc, $handler;
                    guild_id=Snowflake($guild_id))
            end)
        end
    elseif length(args) == 5
        # @slash_command client guild_id name description options handler
        guild_id, name, desc, options, handler = args
        return esc(quote
            register_command!($client.command_tree, $name, $desc, $handler;
                options=$options, guild_id=Snowflake($guild_id))
        end)
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
    esc(quote
        register_component!($client.command_tree, $custom_id, $handler)
    end)
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
    esc(quote
        register_component!($client.command_tree, $custom_id, $handler)
    end)
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
    esc(quote
        register_modal!($client.command_tree, $custom_id, $handler)
    end)
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
    esc(quote
        register_autocomplete!($client.command_tree, $command_name, $handler)
    end)
end
