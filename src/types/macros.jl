"""
    @discord_struct Name begin
        field::Type
        field::Optional{Type}  # = missing
        ...
    end

Generate a Discord API struct with:
- Mutable struct with keyword constructor
- All Optional{T} fields default to `missing`
- All Nullable{T} fields default to `nothing`
- All other fields get sensible defaults for zero-arg construction
- JSON3/StructTypes Mutable() integration
"""
macro discord_struct(name, block)
    fields = []
    for expr in block.args
        expr isa LineNumberNode && continue
        if expr isa Expr && expr.head == :(::)
            fname = expr.args[1]
            ftype = expr.args[2]
            push!(fields, (fname, ftype))
        end
    end

    # Build struct fields with defaults
    field_exprs = []
    for (fname, ftype) in fields
        ftype_expr = esc(ftype)
        fname_expr = esc(fname)
        # Check if the type is Optional{...} or Nullable{...}
        if ftype isa Expr && ftype.head == :curly
            wrapper = ftype.args[1]
            if wrapper == :Optional
                push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :missing))
                continue
            elseif wrapper == :Nullable
                push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :nothing))
                continue
            elseif wrapper == :Vector
                push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :($(ftype_expr)())))
                continue
            end
        end
        # Provide defaults for concrete types so Mutable() can construct empty instances
        default = _default_for_type(ftype)
        if !isnothing(default)
            push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), esc(default)))
        else
            push!(field_exprs, :($(fname_expr)::$(ftype_expr)))
        end
    end

    esc_name = esc(name)

    quote
        Base.@kwdef mutable struct $esc_name
            $(field_exprs...)
        end

        StructTypes.StructType(::Type{$esc_name}) = StructTypes.Mutable()
        StructTypes.omitempties(::Type{$esc_name}) = true
    end
end

function _default_for_type(ftype)
    if ftype == :Snowflake
        return :(Snowflake(0))
    elseif ftype == :String
        return ""
    elseif ftype == :Int
        return 0
    elseif ftype == :Bool
        return false
    elseif ftype == :Float64
        return 0.0
    elseif ftype == :Any
        return nothing
    else
        # For other struct types, try providing a default via missing
        # These are types like User, Emoji, etc. — they should be Optional or Nullable
        return nothing
    end
end
