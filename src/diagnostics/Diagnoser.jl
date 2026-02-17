module Diagnoser

using Dates

export Diagnostic, report, diagnose

"""
    Diagnostic

A structured error report used to present friendly, Elm-like diagnostics to the user.
"""
struct Diagnostic
    title::String
    explanation::String
    code_context::Union{String, Nothing}
    hint::Union{String, Nothing}
    docs_url::Union{String, Nothing}
end

const BOX_H = "─"
const BOX_V = "│"
const BOX_TL = "┌"
const BOX_TR = "┐"
const BOX_BL = "└"
const BOX_BR = "┘"

function render(io::IO, d::Diagnostic)
    # Width calculation (clamped to 80 chars max)
    content_width = min(80, max(length(d.title) + 5, 60))
    
    # Header
    print(io, "\n", BOX_TL, BOX_H, " ", d.title, " ")
    println(io, repeat(BOX_H, content_width - length(d.title) - 3), BOX_TR)
    
    # Body helper
    function print_line(text, color=:default)
        if isnothing(text); return; end
        
        # Word wrapping simple implementation
        words = split(text)
        current_line = ""
        
        for word in words
            if length(current_line) + length(word) + 1 > content_width - 4
                println(io, BOX_V, "  ", current_line, repeat(" ", content_width - length(current_line) - 4), BOX_V)
                current_line = word
            else
                current_line = isempty(current_line) ? word : current_line * " " * word
            end
        end
        if !isempty(current_line)
            println(io, BOX_V, "  ", current_line, repeat(" ", content_width - length(current_line) - 4), BOX_V)
        end
    end
    
    # Spacer
    println(io, BOX_V, repeat(" ", content_width - 2), BOX_V)
    
    # Code Context
    if !isnothing(d.code_context)
        for line in split(d.code_context, "\n")
            println(io, BOX_V, "  ", line, repeat(" ", max(0, content_width - length(line) - 4)), BOX_V)
        end
        println(io, BOX_V, repeat(" ", content_width - 2), BOX_V) 
    end

    # Explanation
    print_line(d.explanation)
    
    # Hints
    if !isnothing(d.hint)
        println(io, BOX_V, repeat(" ", content_width - 2), BOX_V)
        print_line("Fix: " * d.hint, :cyan)
    end
    
    # Docs
    if !isnothing(d.docs_url)
        println(io, BOX_V, repeat(" ", content_width - 2), BOX_V) 
        print_line("Docs: " * d.docs_url, :blue)
    end

    # Footer
    println(io, BOX_BL, repeat(BOX_H, content_width - 2), BOX_BR)
end

"""
    report(exception, stacktone)

The main entry point for reporting errors. It attempts to diagnose the exception
and print a friendly box. If no diagnosis is found, it falls back to standard Julia standard error.
"""
function report(e, catch_stack)
    diag = diagnose(e, catch_stack)
    
    if isnothing(diag)
        # Fallback: Just rethrow or print normally if we can't be helpful
        # Check if it is an unknown Discord error so we don't silence it
        @error "Unhandled Exception" exception=(e, catch_stack)
        return
    end

    # Print the friendly box
    buf = IOBuffer()
    render(buf, diag)
    printstyled(stderr, String(take!(buf)), color=:red)
end


# =========================================================================================
# Matchers — The "Double Pareto" (Top 30 Errors)
# =========================================================================================

# =========================================================================================
# Matchers — The "Double Pareto" (Top 30 Errors)
# =========================================================================================

function diagnose(e, stack)
    # 1. SETUP & CONFIGURATION
    
    # 1.1 Missing Token
    if e isa ArgumentError && occursin("token cannot be empty", e.msg)
        return Diagnostic(
            "MISSING TOKEN",
            "The bot functionality requires a valid Discord Bot Token, but an empty string was provided.",
            "Client(\"\"; ...)",
            "Get your token from the Developer Portal -> Bot -> Copy Token.",
            "https://discord.com/developers/applications"
        )
    end

    # 1.2 Invalid Token Format (contains newlines or spaces)
    if e isa ArgumentError && occursin("Token contains invalid characters", e.msg)
        return Diagnostic(
            "INVALID TOKEN FORMAT",
            "The provided token contains spaces or newlines, which are not allowed.",
            "Client(\"Bot ... \")",
            "Ensure you copied the token exactly and didn't include extra whitespace.",
            nothing
        )
    end
    
    # 1.4 Disallowed Intents (4014) / Authentication Failed (4004)
    # This usually comes as a WebSocket Close or HTTP 400x
    status = 0
    if e isa HTTP.StatusError
        status = e.status
    elseif e isa HTTP.WebSockets.WebSocketError && e.message isa HTTP.WebSockets.CloseFrameBody
        status = e.message.status
    elseif hasproperty(e, :code)
        status = e.code
    end

    if status == 4004 # Authentication Failed
         return Diagnostic(
            "AUTHENTICATION FAILED (4004)",
            "The Gateway refused your token. It might be invalid or expired.",
            "Client(\"Bot ...\")",
            "Check that your token is correct and lacks extra spaces.",
            "https://discord.com/developers/docs/topics/gateway#close-codes"
        )
    end

    if status == 4014 # Disallowed Intents
        return Diagnostic(
            "DISALLOWED INTENTS (4014)",
            "The Gateway refused connection because you are requesting Privileged Intents that are not enabled in the Developer Portal.",
            "Client(token; intents=IntentMessageContent ...)",
            "Go to Dev Portal -> Bot -> Privileged Gateway Intents and enable 'Message Content', 'Server Members', etc.",
            "https://discord.com/developers/docs/topics/gateway#privileged-intents"
        )
    end

    # 1.5 Sharding Config Error
    # e.g. "Sharding required for >2500 guilds" or manual mismatch
    if e isa ArgumentError && occursin("Invalid shard configuration", e.msg)
         return Diagnostic(
            "SHARDING CONFIGURATION ERROR",
            "The number of shards specified does not match the Gateway recommendation, or is invalid.",
            "ShardInfo(0, 1, ...)",
            "Use `get_gateway_bot()` to dynamically fetch the recommended shard count.",
            "https://discord.com/developers/docs/topics/gateway#sharding"
        )
    end
    
    # 2. RUNTIME / API ERRORS
    
    # Extract JSON body if available
    json = nothing
    if e isa HTTP.StatusError && !isempty(e.response.body)
        try
            json = JSON3.read(e.response.body)
        catch
        end
    end
    
    code = !isnothing(json) && haskey(json, :code) ? json.code : 0

    # 2.1 Missing Permissions (50013)
    if code == 50013
        return Diagnostic(
            "MISSING PERMISSIONS (50013)",
            "The bot tried to perform an action but lacks the necessary permissions in the guild/channel.",
            nothing,
            "Check the bot's role hierarchy and channel overrides. It needs 'Administrator' or specific override.",
            "https://discord.com/developers/docs/topics/permissions"
        )
    end

    # 2.2 Unknown Resource (Channel/Message/User)
    if code == 10003 # Unknown Channel
        return Diagnostic(
            "UNKNOWN CHANNEL (10003)",
            "The channel you are trying to access does not exist or was deleted.",
            "get_channel(client, id)",
            "Ensure the ID is correct and the channel is viewable by the bot.",
            nothing
        )
    end
    if code == 10008 # Unknown Message
        return Diagnostic(
            "UNKNOWN MESSAGE (10008)",
            "The message you are trying to edit/delete/react to does not exist.",
            "edit_message(client, channel_id, message_id)",
            "Messages cannot be manipulated if they were deleted.",
            nothing
        )
    end
    if code == 10062 # Unknown Interaction
        return Diagnostic(
            "UNKNOWN INTERACTION (10062)",
            "The interaction token has expired or is invalid.",
            "respond(ctx; ...)",
            "You must respond to an interaction within 3 seconds. Use `defer(ctx)` to extend this window.",
            "https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-time-limits"
        )
    end

    # 2.3 Rate Limit (429)
    if e isa HTTP.StatusError && e.status == 429
        retry_after = !isnothing(json) ? get(json, :retry_after, 0) : "?"
        return Diagnostic(
            "RATE LIMIT EXCEEDED (429)",
            "You are sending too many requests too quickly. The library usually handles this, but you may have hit a global limit.",
            "Retry-After: $retry_after",
            "Slow down your requests or check if you are being spammy.",
            "https://discord.com/developers/docs/topics/rate-limits"
        )
    end

    # 2.4 Invalid Form Body (50035) — The "Validation" Error
    if code == 50035
        errors = get(json, :errors, Dict())
        explanation = "Discord rejected the data sent in the request body."
        
        # Try to pretty print the nested errors
        if !isempty(errors)
            # Simple flattener for nested errors (could be improved)
            explanation *= "\nDetails: " * string(errors)
        end

        return Diagnostic(
            "INVALID FORM BODY (50035)",
            explanation,
            nothing,
            "Check constraints: Embeds < 6000 chars, Select Menus < 25 options, etc.",
            "https://discord.com/developers/docs/reference#error-messages"
        )
    end

    # 2.5 Empty Message (50006)
    if code == 50006
        return Diagnostic(
            "EMPTY MESSAGE (50006)",
            "You cannot send an empty message.",
            "create_message(c, channel_id; content=\"\")",
            "A message must have at least one of: content, embed, file, or component.",
            nothing
        )
    end
    
    # 3. LOGIC ERRORS

    return nothing # No match found
end

end # module
