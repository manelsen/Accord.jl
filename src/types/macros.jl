"""
    @discord_struct Name begin
        field::Type
        field::Optional{Type}  # = missing
        ...
    end

Use this macro when defining new Discord API data structures to automatically handle optional fields and JSON serialization.

Generate a Discord API struct with:
- Mutable struct with keyword constructor
- All Optional{T} fields default to `missing`
- All Nullable{T} fields default to `nothing`
- All other fields get sensible defaults for zero-arg construction
- JSON3/StructTypes Mutable() integration

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
    field_exprs = []
    
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
            ftype_expr = esc(ftype)
            fname_expr = esc(fname)
            
            if !isnothing(default_val)
                push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), esc(default_val)))
            else
                # Check if the type is Optional{...} or Nullable{...}
                found_wrapper = false
                if ftype isa Expr && ftype.head == :curly
                    wrapper = ftype.args[1]
                    if wrapper == :Optional || (wrapper isa Expr && wrapper.head == :. && wrapper.args[2] isa QuoteNode && wrapper.args[2].value == :Optional)
                        push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :missing))
                        found_wrapper = true
                    elseif wrapper == :Nullable || (wrapper isa Expr && wrapper.head == :. && wrapper.args[2] isa QuoteNode && wrapper.args[2].value == :Nullable)
                        push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :nothing))
                        found_wrapper = true
                    elseif wrapper == :Vector || (wrapper isa Expr && wrapper.head == :. && wrapper.args[2] isa QuoteNode && wrapper.args[2].value == :Vector)
                        push!(field_exprs, Expr(:(=), :($(fname_expr)::$(ftype_expr)), :($(ftype_expr)())))
                        found_wrapper = true
                    end
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

    quote
        Base.@kwdef mutable struct $esc_name
            $(field_exprs...)
        end

        $StructTypes.StructType(::Type{$esc_name}) = $StructTypes.Mutable()
        $StructTypes.omitempties(::Type{$esc_name}) = true
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