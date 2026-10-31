# Message payload builder shared by every function that sends or edits a
# message: create_message, reply, edit_message, respond, followup,
# edit_response.

_flag_value(::Nothing) = 0
_flag_value(f::MessageFlags) = Int(f.value)
_flag_value(f::Integer) = Int(f)

# Build a message payload from keyword arguments named after Discord's JSON
# fields (content, embeds, components, poll, allowed_mentions, …).
#
# - `nothing` always means "leave the field out".
# - `omit_empty=true` (new messages) also leaves out "" and empty vectors.
#   Edits pass `omit_empty=false`, so "" or [] clears a field on Discord's side.
# - `flags` (MessageFlags or Integer) and `ephemeral=true` are OR-ed together.
function _message_body(; omit_empty::Bool=true, ephemeral::Bool=false, tts::Bool=false,
                       flags=nothing, fields...)
    body = Dict{String, Any}()
    for (k, v) in pairs(fields)
        v === nothing && continue
        omit_empty && v isa Union{AbstractString, AbstractVector} && isempty(v) && continue
        body[string(k)] = v
    end
    tts && (body["tts"] = true)
    f = _flag_value(flags) | (ephemeral ? _flag_value(MsgFlagEphemeral) : 0)
    f != 0 && (body["flags"] = f)
    return body
end
