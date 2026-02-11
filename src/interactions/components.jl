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

"""
    embed_field(name, value; inline=false)

Create an embed field dict. Use with the `embed()` builder's `fields` parameter.

# Example
```julia
embed(title="Info", fields=[
    embed_field("Name", "Accord.jl"; inline=true),
    embed_field("Version", "0.1.0"; inline=true),
])
```
"""
function embed_field(name::String, value::String; inline::Bool=false)
    d = Dict{String, Any}("name" => name, "value" => value)
    inline && (d["inline"] = true)
    d
end

"""
    embed_footer(text; icon_url="")

Create an embed footer dict. Use with the `embed()` builder's `footer` parameter.
"""
function embed_footer(text::String; icon_url::String="")
    d = Dict{String, Any}("text" => text)
    !isempty(icon_url) && (d["icon_url"] = icon_url)
    d
end

"""
    embed_author(name; url="", icon_url="")

Create an embed author dict. Use with the `embed()` builder's `author` parameter.
"""
function embed_author(name::String; url::String="", icon_url::String="")
    d = Dict{String, Any}("name" => name)
    !isempty(url) && (d["url"] = url)
    !isempty(icon_url) && (d["icon_url"] = icon_url)
    d
end

"""
    activity(name, type=ActivityTypes.GAME; url="")

Create an activity dict for use with `update_presence`. The `type` should be a constant
from `ActivityTypes` (e.g. `GAME`, `STREAMING`, `LISTENING`, `WATCHING`, `COMPETING`).

# Example
```julia
update_presence(client; activities=[activity("Accord.jl", ActivityTypes.GAME)])
```
"""
function activity(name::String, type::Int=ActivityTypes.GAME; url::String="")
    d = Dict{String, Any}("name" => name, "type" => type)
    !isempty(url) && (d["url"] = url)
    d
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

# === Components V2 Builders ===

"""Create a Container component (top-level v2 wrapper)."""
function container(components::Vector; color::Integer=0, spoiler::Bool=false)
    c = Dict{String, Any}("type" => ComponentTypes.CONTAINER, "components" => components)
    color > 0 && (c["accent_color"] = color)
    spoiler && (c["spoiler"] = true)
    c
end

"""Create a Section component with text and optional accessory."""
function section(components::Vector; accessory=nothing)
    s = Dict{String, Any}("type" => ComponentTypes.SECTION, "components" => components)
    !isnothing(accessory) && (s["accessory"] = accessory)
    s
end

"""Create a Text Display component."""
function text_display(content::String)
    Dict{String, Any}("type" => ComponentTypes.TEXT_DISPLAY, "content" => content)
end

"""Create a Thumbnail component."""
function thumbnail(; media::Dict, description::String="", spoiler::Bool=false)
    t = Dict{String, Any}("type" => ComponentTypes.THUMBNAIL, "media" => media)
    !isempty(description) && (t["description"] = description)
    spoiler && (t["spoiler"] = true)
    t
end

"""Create a Media Gallery component."""
function media_gallery(items::Vector)
    Dict{String, Any}("type" => ComponentTypes.MEDIA_GALLERY, "items" => items)
end

"""Create a media gallery item."""
function media_gallery_item(; media::Dict, description::String="", spoiler::Bool=false)
    item = Dict{String, Any}("media" => media)
    !isempty(description) && (item["description"] = description)
    spoiler && (item["spoiler"] = true)
    item
end

"""Create a File component."""
function file_component(; media::Dict, spoiler::Bool=false)
    f = Dict{String, Any}("type" => ComponentTypes.FILE, "file" => media)
    spoiler && (f["spoiler"] = true)
    f
end

"""Create a Separator component."""
function separator(; divider::Bool=true, spacing::Int=1)
    s = Dict{String, Any}("type" => ComponentTypes.SEPARATOR, "divider" => divider)
    spacing != 1 && (s["spacing"] = spacing)
    s
end

"""Create an unfurled media object (used by thumbnail, media_gallery, file)."""
function unfurled_media(url::String)
    Dict{String, Any}("url" => url)
end
