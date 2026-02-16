# Component builder helpers

"""Use this to group buttons and select menus into a horizontal row.

Create an Action Row containing components.

# Example
```julia
row = action_row([
    button(label="Yes", custom_id="yes", style=ButtonStyles.SUCCESS),
    button(label="No", custom_id="no", style=ButtonStyles.DANGER)
])
```
"""
function action_row(components::Vector)
    Dict{String, Any}(
        "type" => ComponentTypes.ACTION_ROW,
        "components" => components,
    )
end

"""Use this to create interactive buttons that users can click.

Create a Button component.

# Example
```julia
btn = button(label="Click me", custom_id="click_me", style=ButtonStyles.PRIMARY)
```
"""
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

"""Use this to create dropdown menus for users to select from text options.

Create a String Select Menu component.

# Example
```julia
options = [
    select_option(label="Option 1", value="opt1"),
    select_option(label="Option 2", value="opt2")
]
sel = string_select(custom_id="my_select", options=options, placeholder="Choose one...")
```
"""
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

"""Use this to define individual options within a string select menu.

Create a select option for string select menus."""
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

"""Use this to create a dropdown for selecting Discord users.

Create a User Select Menu.

# Example
```julia
sel = user_select(custom_id="pick_user", placeholder="Select a member")
```
"""
function user_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.USER_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Use this to create a dropdown for selecting server roles.

Create a Role Select Menu."""
function role_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.ROLE_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Use this to create a dropdown for selecting users or roles.

Create a Mentionable Select Menu."""
function mentionable_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.MENTIONABLE_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Use this to create a dropdown for selecting channels.

Create a Channel Select Menu."""
function channel_select(; custom_id::String, channel_types::Vector{Int}=Int[], placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false)
    sel = Dict{String, Any}("type" => ComponentTypes.CHANNEL_SELECT, "custom_id" => custom_id, "min_values" => min_values, "max_values" => max_values)
    !isempty(channel_types) && (sel["channel_types"] = channel_types)
    !isempty(placeholder) && (sel["placeholder"] = placeholder)
    disabled && (sel["disabled"] = true)
    sel
end

"""Use this to create text input fields inside modal dialogs.

Create a Text Input component (for modals).

# Example
```julia
input = text_input(
    custom_id="reason",
    label="Reason for report",
    style=TextInputStyles.PARAGRAPH,
    placeholder="Describe what happened..."
)
```
"""
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

"""Use this to create rich embedded messages with formatted content.

Create an Embed dict.

# Example
```julia
e = embed(
    title="Hello",
    description="This is an embed",
    color=0x5865F2,
    fields=[embed_field("Name", "Accord.jl")]
)
```
"""
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

Use this to add labeled fields to your embed messages.

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

Use this to add a footer with optional icon to your embed messages.

Create an embed footer dict. Use with the `embed()` builder's `footer` parameter.
"""
function embed_footer(text::String; icon_url::String="")
    d = Dict{String, Any}("text" => text)
    !isempty(icon_url) && (d["icon_url"] = icon_url)
    d
end

"""
    embed_author(name; url="", icon_url="")

Use this to add an author section with optional link and icon to your embed messages.

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

Use this to set your bot's status activity that appears below its name.

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

"""Use this internal function to build command option dictionaries.

Create a command option dict."""
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

"""Use this to create a container for organizing components in v2 messages.

Create a Container component (top-level v2 wrapper)."""
function container(components::Vector; color::Integer=0, spoiler::Bool=false)
    c = Dict{String, Any}("type" => ComponentTypes.CONTAINER, "components" => components)
    color > 0 && (c["accent_color"] = color)
    spoiler && (c["spoiler"] = true)
    c
end

"""Use this to group text and accessory components in v2 messages.

Create a Section component with text and optional accessory."""
function section(components::Vector; accessory=nothing)
    s = Dict{String, Any}("type" => ComponentTypes.SECTION, "components" => components)
    !isnothing(accessory) && (s["accessory"] = accessory)
    s
end

"""Use this to display plain text in v2 messages.

Create a Text Display component."""
function text_display(content::String)
    Dict{String, Any}("type" => ComponentTypes.TEXT_DISPLAY, "content" => content)
end

"""Use this to display small preview images in v2 messages.

Create a Thumbnail component."""
function thumbnail(; media::Dict, description::String="", spoiler::Bool=false)
    t = Dict{String, Any}("type" => ComponentTypes.THUMBNAIL, "media" => media)
    !isempty(description) && (t["description"] = description)
    spoiler && (t["spoiler"] = true)
    t
end

"""Use this to display collections of images or videos in v2 messages.

Create a Media Gallery component."""
function media_gallery(items::Vector)
    Dict{String, Any}("type" => ComponentTypes.MEDIA_GALLERY, "items" => items)
end

"""Use this to add individual items to a media gallery.

Create a media gallery item."""
function media_gallery_item(; media::Dict, description::String="", spoiler::Bool=false)
    item = Dict{String, Any}("media" => media)
    !isempty(description) && (item["description"] = description)
    spoiler && (item["spoiler"] = true)
    item
end

"""Use this to attach downloadable files to v2 messages.

Create a File component."""
function file_component(; media::Dict, spoiler::Bool=false)
    f = Dict{String, Any}("type" => ComponentTypes.FILE, "file" => media)
    spoiler && (f["spoiler"] = true)
    f
end

"""Use this to add visual separation between components in v2 messages.

Create a Separator component."""
function separator(; divider::Bool=true, spacing::Int=1)
    s = Dict{String, Any}("type" => ComponentTypes.SEPARATOR, "divider" => divider)
    spacing != 1 && (s["spacing"] = spacing)
    s
end

"""Use this to create media references for thumbnails, galleries, and file attachments.

Create an unfurled media object (used by thumbnail, media_gallery, file)."""
function unfurled_media(url::String)
    Dict{String, Any}("url" => url)
end
