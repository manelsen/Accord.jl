# Timestamp field name heuristic — fields matching these patterns hold ISO8601 strings
function _is_timestamp_field(name::Symbol)::Bool
    s = string(name)
    return s == "timestamp" || s == "expiry" || s == "end_" ||
           endswith(s, "_at") || endswith(s, "_since") ||
           endswith(s, "_until") || endswith(s, "_timestamp")
end

const _TS_FMT_MS = dateformat"yyyy-mm-ddTHH:MM:SS.sss"
const _TS_FMT_S  = dateformat"yyyy-mm-ddTHH:MM:SS"

"""
    parse_timestamp(s) -> Union{DateTime, Missing}

Parse a Discord ISO8601 timestamp string into a Julia `DateTime`.
Returns `missing` if `s` is `missing`, empty, or unparseable (with a `@warn`).
Sub-millisecond precision is silently truncated to milliseconds.
"""
function parse_timestamp(s::AbstractString)::Union{DateTime, Missing}
    isempty(s) && return missing
    try
        if length(s) >= 23 && s[20] == '.'
            return DateTime(s[1:23], _TS_FMT_MS)
        else
            return DateTime(s[1:min(19, length(s))], _TS_FMT_S)
        end
    catch
        @warn "Failed to parse Discord timestamp" timestamp=s
        return missing
    end
end
parse_timestamp(::Missing) = missing

"""
    @discord_struct Name begin
        field::Type
        field::Optional{Type}  # = missing
        ...
    end

Use this macro when defining new Discord API data structures to automatically handle optional fields and JSON serialization.

Generate a Discord API struct with:
- Mutable struct with keyword constructor
- All Optional{T} and Maybe{T} fields default to `missing`
- All Nullable{T} fields default to `nothing`
- All other fields get sensible defaults for zero-arg construction
- JSON3/StructTypes Mutable() integration: an absent key reads as `missing` and
  a JSON `null` as `nothing`; on write, `missing` is omitted and `nothing` in a
  Maybe/Nullable field is written as `null`

# Example
```jldoctest
julia> Accord.@discord_struct MyResource begin
           id::Snowflake
           name::String
           description::Optional{String}
           count::Int
       end;

julia> r = MyResource(id=Snowflake(123), name="test");

julia> r.description === missing
true
```
"""
macro discord_struct(name, block)
    # Optional supertype: `@discord_struct Name <: Super begin ... end`
    supertype = nothing
    if name isa Expr && name.head == :<:
        name, supertype = name.args
    end
    field_exprs = []
    timestamp_fields = Symbol[]
    maybe_fields = Symbol[]     # null must decode to `nothing`
    nullable_fields = Symbol[]  # `nothing` must be written as null

    for expr in block.args
        if expr isa LineNumberNode
            push!(field_exprs, expr)
            continue
        end
        
        # Handle docstrings or other macro calls on fields
        if expr isa Expr && expr.head == :macrocall
            push!(field_exprs, expr)
            continue
        end

        fname = nothing
        ftype = nothing
        default_val = nothing

        if expr isa Expr && expr.head == :(::)
            fname = expr.args[1]
            ftype = expr.args[2]
        elseif expr isa Expr && expr.head == :(=) && expr.args[1] isa Expr && expr.args[1].head == :(::)
            fname = expr.args[1].args[1]
            ftype = expr.args[1].args[2]
            default_val = expr.args[2]
        end

        if !isnothing(fname)
            fname isa Symbol && _is_timestamp_field(fname) && push!(timestamp_fields, fname)
            ftype_expr = esc(ftype)
            fname_expr = esc(fname)
            wrapper = _wrapper_name(ftype)
            wrapper === :Maybe && push!(maybe_fields, fname)
            wrapper in (:Maybe, :Nullable) && push!(nullable_fields, fname)

            if !isnothing(default_val)
                push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), esc(default_val)))
            else
                found_wrapper = true
                if wrapper in (:Optional, :Maybe)
                    push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :missing))
                elseif wrapper === :Nullable
                    push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :nothing))
                elseif wrapper === :Vector
                    push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :($(ftype_expr)())))
                else
                    found_wrapper = false
                end

                if !found_wrapper
                    # Provide defaults for concrete types so Mutable() can construct empty instances
                    default = _default_for_type(ftype)
                    if !isnothing(default)
                        push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), default))
                    else
                        push!(field_exprs, :($(fname_expr)::$(ftype_expr)))
                    end
                end
            end
        elseif expr isa String
            # Skip docstrings for now as Base.@kwdef doesn't handle them well inside the block
            continue
        else
            # Keep other expressions as is (e.g. comments are already filtered, but maybe other stuff)
            push!(field_exprs, expr)
        end
    end

    esc_name = esc(name)
    struct_head = isnothing(supertype) ? esc_name : :($esc_name <: $(esc(supertype)))

    getprop_block = if isempty(timestamp_fields)
        :()
    else
        checks = [:(name === $(QuoteNode(f))) for f in timestamp_fields]
        is_ts = reduce((a, b) -> :($a || $b), checks)
        quote
            function Base.getproperty(obj::$esc_name, name::Symbol)
                val = getfield(obj, name)
                if $is_ts && val isa AbstractString
                    return parse_timestamp(val)
                end
                return val
            end
        end
    end

    quote
        Base.@kwdef mutable struct $struct_head
            $(field_exprs...)
        end

        $StructTypes.StructType(::Type{$esc_name}) = $StructTypes.Mutable()
        $StructTypes.omitempties(::Type{$esc_name}) = true
        $StructTypes.isempty(::Type{$esc_name}, x::$esc_name, i::Int) =
            _omit_field(getfield(x, i), fieldname($esc_name, i) in $(Tuple(nullable_fields)))

        $(_null_decode_block(esc_name, maybe_fields))

        $getprop_block
    end
end

# `Optional`, `Maybe`, `Nullable` or `Vector` for a `Wrapper{T}` field type
# (bare or module-qualified), otherwise `nothing`.
function _wrapper_name(ftype)
    (ftype isa Expr && ftype.head == :curly) || return nothing
    w = ftype.args[1]
    if w isa Expr && w.head == :. && w.args[2] isa QuoteNode
        w = w.args[2].value
    end
    return w in (:Optional, :Maybe, :Nullable, :Vector) ? w : nothing
end

# Whether to leave a field out when writing JSON: `missing` means absent, so it
# is always omitted; `nothing` means null, written only where the type allows it.
_omit_field(::Missing, keep_null::Bool) = true
_omit_field(::Nothing, keep_null::Bool) = !keep_null
_omit_field(v, keep_null::Bool) = StructTypes.isempty(v)

# JSON3 reads a null into `Union{T, Missing, Nothing}` as `missing`, the first
# null-like member of the union. StructTypes only applies fields whose key is
# present, so a Maybe field that is still `missing` afterwards was a null.
function _null_decode_block(esc_name, maybe_fields)
    isempty(maybe_fields) && return :()
    quote
        function $StructTypes.applyfield!(f, x::$esc_name, nm::Symbol)
            applied = invoke($StructTypes.applyfield!, Tuple{Any, Any, Symbol}, f, x, nm)
            fld = $StructTypes.julianame($StructTypes.names($esc_name), nm)
            if applied && fld in $(Tuple(maybe_fields)) && getfield(x, fld) === missing
                setfield!(x, fld, nothing)
            end
            return applied
        end
    end
end

function _default_for_type(ftype)
    # Extract the base type name if it's qualified
    sym = if ftype isa Symbol
        ftype
    elseif ftype isa Expr && ftype.head == :. && ftype.args[2] isa QuoteNode
        ftype.args[2].value
    else
        nothing
    end

    if sym == :Snowflake
        return :(Accord.Snowflake(0))
    elseif sym == :String
        return ""
    elseif sym == :Int || sym == :Int64 || sym == :Int32
        return 0
    elseif sym == :Bool
        return false
    elseif sym == :Float64 || sym == :Float32
        return 0.0
    elseif sym == :Any
        return nothing
    else
        return nothing
    end
end