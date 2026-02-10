# Component builder helpers

"""Create an Action Row containing components."""
function action_row(components::Vector)
    Dict{String, Any}(
        "type" => ComponentTypes.ACTION_ROW,
        "components" => components,
    )
end

"""Create a Button component."""
function button(;
    label::String = "",
    custom_id::String = "",
    style::Int = ButtonStyles.PRIMARY,
    emoji = nothing,
    url::String = "",
    disabled::Bool = false,
    sku_id = nothing,
)
    btn = Dict{String, Any}("type" => ComponentTypes.BUTTON, "style" => style)
    !isempty(label) && (btn["label"] = label)
    !isempty(custom_id) && (btn["custom_id"] = custom_id)
    !isempty(url) && (btn["url"] = url)
    !isnothing(emoji) && (btn["emoji"] = emoji)
    disabled && (btn["disabled"] = true)
    !isnothing(sku_id) && (btn["sku_id"] = string(sku_id))
    btn
end

"""Create a String Select Menu component."""
function string_select(;
    custom_id::String,
    options::Vector,
    placeholder::String = "",
    min_values::Int = 1,
    max_values::Int = 1,
    disabled::Bool = false,
)
    sel = Dict{String, Any}(
        "type" => ComponentTypes.STRING_SELECT,
        "custom_id" => custom_id,
        "options" => options,
        "min_values" => min_values,
        "max_values" => max_values,
    )
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Create a select option for string select menus."""
function select_option(;
    label::String,
    value::String,
    description::String = "",
    emoji = nothing,
    default::Bool = false,
)
    opt = Dict{String, Any}("label" => label, "value" => value)
    !isempty(description) && (opt["description"] = description)
    !isnothing(emoji) && (opt["emoji"] = emoji)
    default && (opt["default"] = true)
    opt
end

"""Create a User Select Menu."""
function user_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.USER_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Create a Role Select Menu."""
function role_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.ROLE_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Create a Mentionable Select Menu."""
function mentionable_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.MENTIONABLE_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Create a Channel Select Menu."""
function channel_select(; custom_id::String, channel_types::Vector{Int}=Int[], placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.CHANNEL_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(channel_types) && (sel["channel_types"] = channel_types)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Create a Text Input component (for modals)."""
function text_input(;
    custom_id::String,
    label::String,
    style::Int = TextInputStyles.SHORT,
    min_length::Int = 0,
    max_length::Int = 4000,
    required::Bool = true,
    value::String = "",
    placeholder::String = "",
)
    ti = Dict{String, Any}(
        "type" => ComponentTypes.TEXT_INPUT,
        "custom_id" => custom_id,
        "label" => label,
        "style" => style,
        "required" => required,
    )
    min_length > 0 && (ti["min_length"] = min_length)
    max_length < 4000 && (ti["max_length"] = max_length)
    !isempty(value) && (ti["value"] = value)
    !isempty(placeholder) && (ti["placeholder"] = placeholder)
    ti
end

"""Create an Embed dict."""
function embed(;
    title::String = "",
    description::String = "",
    url::String = "",
    color::Integer = 0,
    timestamp::String = "",
    footer = nothing,
    image = nothing,
    thumbnail = nothing,
    author = nothing,
    fields::Vector = [],
)
    e = Dict{String, Any}()
    !isempty(title) && (e["title"] = title)
    !isempty(description) && (e["description"] = description)
    !isempty(url) && (e["url"] = url)
    color > 0 && (e["color"] = color)
    !isempty(timestamp) && (e["timestamp"] = timestamp)
    !isnothing(footer) && (e["footer"] = footer)
    !isnothing(image) && (e["image"] = image)
    !isnothing(thumbnail) && (e["thumbnail"] = thumbnail)
    !isnothing(author) && (e["author"] = author)
    !isempty(fields) && (e["fields"] = fields)
    e
end

"""Create a command option dict."""
function command_option(;
    type::Int,
    name::String,
    description::String,
    required::Bool = false,
    choices::Vector = [],
    options::Vector = [],
    channel_types::Vector{Int} = Int[],
    min_value = nothing,
    max_value = nothing,
    min_length = nothing,
    max_length = nothing,
    autocomplete::Bool = false,
)
    opt = Dict{String, Any}(
        "type" => type,
        "name" => name,
        "description" => description,
    )
    required && (opt["required"] = true)
    !isempty(choices) && (opt["choices"] = choices)
    !isempty(options) && (opt["options"] = options)
    !isempty(channel_types) && (opt["channel_types"] = channel_types)
    !isnothing(min_value) && (opt["min_value"] = min_value)
    !isnothing(max_value) && (opt["max_value"] = max_value)
    !isnothing(min_length) && (opt["min_length"] = min_length)
    !isnothing(max_length) && (opt["max_length"] = max_length)
    autocomplete && (opt["autocomplete"] = true)
    opt
end
