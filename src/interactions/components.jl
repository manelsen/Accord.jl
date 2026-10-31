# Component builder helpers

# Add to `d` the keyword arguments that carry a value, and return `d`.
# "No value" is `nothing`, `false`, "" or an empty collection: for component
# and embed fields that is Discord's default, so the key is simply left out.
function _with_set(d::Dict{String, Any}; kwargs...)
    for (k, v) in pairs(kwargs)
        (v === nothing || v === false) && continue
        v isa Union{AbstractString, AbstractVector, AbstractDict} && isempty(v) && continue
        d[string(k)] = v
    end
    return d
end

# Shared body of the select menu builders. `required` only applies in modals
# (Discord's default there is true), so it is sent only when given.
function _select(type::Int; custom_id::String, min_values::Int, max_values::Int,
                 required::Union{Bool, Nothing} = nothing, kwargs...)
    d = _with_set(Dict{String, Any}("type" => type, "custom_id" => custom_id,
                                    "min_values" => min_values, "max_values" => max_values); kwargs...)
    isnothing(required) || (d["required"] = required)
    return d
end

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
    _with_set(Dict{String, Any}("type" => ComponentTypes.BUTTON, "style" => style);
        label, custom_id, url, emoji, disabled,
        sku_id = isnothing(sku_id) ? nothing : string(sku_id))
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

In a modal, pass `required=false` to make the menu optional (Discord's default
there is required); outside modals leave it unset. The same keyword exists on
the other select builders.
"""
function string_select(;
    custom_id::String,
    options::Vector,
    placeholder::String = "",
    min_values::Int = 1,
    max_values::Int = 1,
    disabled::Bool = false,
    required::Union{Bool, Nothing} = nothing,
)
    _select(ComponentTypes.STRING_SELECT; custom_id, options, placeholder, min_values, max_values, disabled, required)
end

"""Use this to define individual options within a string select menu.

Create a select option for string select menus.

# Example
```julia
opt = select_option(label="Pizza", value="pizza"; description="Classic choice", default=true)
```
"""
function select_option(;
    label::String,
    value::String,
    description::String = "",
    emoji = nothing,
    default::Bool = false,
)
    _with_set(Dict{String, Any}("label" => label, "value" => value); description, emoji, default)
end

"""Use this to create a dropdown for selecting Discord users.

Create a User Select Menu.

# Example
```julia
sel = user_select(custom_id="pick_user", placeholder="Select a member")
```
"""
function user_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false, required::Union{Bool, Nothing}=nothing)
    _select(ComponentTypes.USER_SELECT; custom_id, placeholder, min_values, max_values, disabled, required)
end

"""Use this to create a dropdown for selecting server roles.

Create a Role Select Menu.

# Example
```julia
sel = role_select(custom_id="assign_role", placeholder="Pick a role", max_values=3)
```
"""
function role_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false, required::Union{Bool, Nothing}=nothing)
    _select(ComponentTypes.ROLE_SELECT; custom_id, placeholder, min_values, max_values, disabled, required)
end

"""Use this to create a dropdown for selecting users or roles.

Create a Mentionable Select Menu.

# Example
```julia
sel = mentionable_select(custom_id="mention_target", placeholder="Pick a user or role")
```
"""
function mentionable_select(; custom_id::String, placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false, required::Union{Bool, Nothing}=nothing)
    _select(ComponentTypes.MENTIONABLE_SELECT; custom_id, placeholder, min_values, max_values, disabled, required)
end

"""Use this to create a dropdown for selecting channels.

Create a Channel Select Menu.

# Example
```julia
sel = channel_select(custom_id="log_channel", placeholder="Pick a text channel", channel_types=[0])
```
"""
function channel_select(; custom_id::String, channel_types::Vector{Int}=Int[], placeholder::String="", min_values::Int=1, max_values::Int=1, disabled::Bool=false, required::Union{Bool, Nothing}=nothing)
    _select(ComponentTypes.CHANNEL_SELECT; custom_id, channel_types, placeholder, min_values, max_values, disabled, required)
end

"""Use this to create text input fields inside modal dialogs.

Create a Text Input component (for modals). Wrap it in a [`label`](@ref), which
carries the question shown to the user; the `label` keyword here is Discord's
older form, still accepted inside an [`action_row`](@ref) but deprecated.

# Example
```julia
label("Reason for report",
      text_input(custom_id="reason", style=TextInputStyles.PARAGRAPH,
                 placeholder="Describe what happened..."))
```
"""
function text_input(;
    custom_id::String,
    label::String = "",
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
        "style" => style,
        "required" => required,
    )
    !isempty(label) && (ti["label"] = label)
    min_length > 0 && (ti["min_length"] = min_length)
    max_length < 4000 && (ti["max_length"] = max_length)
    !isempty(value) && (ti["value"] = value)
    !isempty(placeholder) && (ti["placeholder"] = placeholder)
    ti
end

"""
    label(text, component; description="") -> Dict

Wrap one modal input with the question shown above it. Every interactive
component of a modal goes in a Label: [`text_input`](@ref), the select menus,
[`file_upload`](@ref), [`radio_group`](@ref), [`checkbox_group`](@ref) and
[`checkbox`](@ref).

# Example
```julia
show_modal(ctx; title="Report", custom_id="report", components=[
    label("What happened?", text_input(custom_id="what", style=TextInputStyles.PARAGRAPH)),
    label("Severity", radio_group(custom_id="sev", options=[
        select_option(label="Low", value="low"),
        select_option(label="High", value="high"),
    ]); description="Pick one"),
])
```
"""
function label(text::AbstractString, component::AbstractDict; description::AbstractString = "")
    _with_set(Dict{String, Any}("type" => ComponentTypes.LABEL, "label" => text,
                                "component" => component); description)
end

"""
    file_upload(; custom_id, min_values=1, max_values=1, required=true, file_types=String[])

A file picker for modals (wrap it in a [`label`](@ref)). `file_types` restricts
what can be chosen: `"image"`, `"video"`, `"audio"` or extensions like `".pdf"`.
The submission carries attachment ids; read the files with [`modal_files`](@ref).
"""
function file_upload(; custom_id::String, min_values::Int = 1, max_values::Int = 1,
                     required::Bool = true, file_types::Vector{String} = String[])
    d = _with_set(Dict{String, Any}("type" => ComponentTypes.FILE_UPLOAD, "custom_id" => custom_id,
                                    "min_values" => min_values, "max_values" => max_values,
                                    "required" => required); file_types)
    return d
end

"""
    radio_group(; custom_id, options, required=true)

Exactly-one choice for modals (wrap it in a [`label`](@ref)). `options` are
[`select_option`](@ref)s, between 2 and 10; mark one with `default=true` to
preselect it.
"""
function radio_group(; custom_id::String, options::Vector, required::Bool = true)
    Dict{String, Any}("type" => ComponentTypes.RADIO_GROUP, "custom_id" => custom_id,
                      "options" => options, "required" => required)
end

"""
    checkbox_group(; custom_id, options, min_values=1, max_values=length(options), required=true)

Multiple-choice checkboxes for modals (wrap it in a [`label`](@ref)). `options`
are [`select_option`](@ref)s, up to 10.
"""
function checkbox_group(; custom_id::String, options::Vector, min_values::Int = 1,
                        max_values::Int = length(options), required::Bool = true)
    Dict{String, Any}("type" => ComponentTypes.CHECKBOX_GROUP, "custom_id" => custom_id,
                      "options" => options, "min_values" => min_values,
                      "max_values" => max_values, "required" => required)
end

"""
    checkbox(; custom_id, default=false)

A single yes/no box for modals (wrap it in a [`label`](@ref)). Discord does not
let a lone checkbox be required; use a one-option [`checkbox_group`](@ref) for that.
"""
checkbox(; custom_id::String, default::Bool = false) =
    _with_set(Dict{String, Any}("type" => ComponentTypes.CHECKBOX, "custom_id" => custom_id); default)

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
    _with_set(Dict{String, Any}(); title, description, url,
        color = color > 0 ? color : nothing, timestamp, footer, image, thumbnail, author, fields)
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
    _with_set(Dict{String, Any}("name" => name, "value" => value); inline)
end

"""
    embed_footer(text; icon_url="")

Use this to add a footer with optional icon to your embed messages.

Create an embed footer dict. Use with the `embed()` builder's `footer` parameter.

# Example
```julia
embed(title="Report", footer=embed_footer("Generated by Accord.jl"; icon_url="https://example.com/icon.png"))
```
"""
function embed_footer(text::String; icon_url::String="")
    _with_set(Dict{String, Any}("text" => text); icon_url)
end

"""
    embed_author(name; url="", icon_url="")

Use this to add an author section with optional link and icon to your embed messages.

Create an embed author dict. Use with the `embed()` builder's `author` parameter.

# Example
```julia
embed(title="Post", author=embed_author("Alice"; url="https://alice.com", icon_url="https://alice.com/avatar.png"))
```
"""
function embed_author(name::String; url::String="", icon_url::String="")
    _with_set(Dict{String, Any}("name" => name); url, icon_url)
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
    _with_set(Dict{String, Any}("name" => name, "type" => type); url)
end

"""Use this internal function to build command option dictionaries.

Create a command option dict.

# Example
```julia
opt = command_option(type=ApplicationCommandOptionTypes.STRING,
    name="query", description="Search term", required=true)
```
"""
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
    _with_set(Dict{String, Any}("type" => type, "name" => name, "description" => description);
        required, choices, options, channel_types, min_value, max_value, min_length, max_length, autocomplete)
end

# === Components V2 Builders ===

"""Use this to create a container for organizing components in v2 messages.

Create a Container component (top-level v2 wrapper).

!!! compat "Accord 0.1.0"
    Components V2 builders (`container`, `section`, `text_display`, `separator`,
    `media_gallery`, `file_component`, `unfurled_media`) are available since Accord 0.1.0.

# Example
```julia
msg = container([
    text_display("Welcome to the server!"),
    separator(),
    section([text_display("Click to learn more")]; accessory=button(label="Info", custom_id="info"))
]; color=0x5865F2)
```
"""
function container(components::Vector; color::Integer=0, spoiler::Bool=false)
    _with_set(Dict{String, Any}("type" => ComponentTypes.CONTAINER, "components" => components);
        accent_color = color > 0 ? color : nothing, spoiler)
end

"""Use this to group text and accessory components in v2 messages.

Create a Section component with text and optional accessory.

# Example
```julia
sec = section([text_display("Server stats")]; accessory=thumbnail(media=unfurled_media("https://example.com/icon.png")))
```
"""
function section(components::Vector; accessory=nothing)
    _with_set(Dict{String, Any}("type" => ComponentTypes.SECTION, "components" => components); accessory)
end

"""Use this to display plain text in v2 messages.

Create a Text Display component.

# Example
```julia
td = text_display("**Bold** and *italic* markdown supported")
```
"""
function text_display(content::String)
    Dict{String, Any}("type" => ComponentTypes.TEXT_DISPLAY, "content" => content)
end

"""Use this to display small preview images in v2 messages.

Create a Thumbnail component.

# Example
```julia
thumb = thumbnail(media=unfurled_media("https://example.com/preview.png"); description="Map Preview")
```
"""
function thumbnail(; media::Dict, description::String="", spoiler::Bool=false)
    _with_set(Dict{String, Any}("type" => ComponentTypes.THUMBNAIL, "media" => media); description, spoiler)
end

"""Use this to display collections of images or videos in v2 messages.

Create a Media Gallery component.

# Example
```julia
gallery = media_gallery([
    media_gallery_item(media=unfurled_media("https://example.com/img1.png")),
    media_gallery_item(media=unfurled_media("https://example.com/img2.png"); description="Photo 2")
])
```
"""
function media_gallery(items::Vector)
    Dict{String, Any}("type" => ComponentTypes.MEDIA_GALLERY, "items" => items)
end

"""Use this to add individual items to a media gallery.

Create a media gallery item.

# Example
```julia
item = media_gallery_item(media=unfurled_media("https://example.com/photo.png"); description="A nice photo", spoiler=true)
```
"""
function media_gallery_item(; media::Dict, description::String="", spoiler::Bool=false)
    _with_set(Dict{String, Any}("media" => media); description, spoiler)
end

"""Use this to attach downloadable files to v2 messages.

Create a File component.

# Example
```julia
f = file_component(media=unfurled_media("attachment://report.pdf"))
```
"""
function file_component(; media::Dict, spoiler::Bool=false)
    _with_set(Dict{String, Any}("type" => ComponentTypes.FILE, "file" => media); spoiler)
end

"""Use this to add visual separation between components in v2 messages.

Create a Separator component.

# Example
```julia
sep = separator(divider=true, spacing=2)
```
"""
function separator(; divider::Bool=true, spacing::Int=1)
    _with_set(Dict{String, Any}("type" => ComponentTypes.SEPARATOR, "divider" => divider);
        spacing = spacing != 1 ? spacing : nothing)
end

"""Use this to create media references for thumbnails, galleries, and file attachments.

Create an unfurled media object (used by thumbnail, media_gallery, file).

# Example
```julia
media = unfurled_media("https://example.com/image.png")
thumb = thumbnail(media=media)
```
"""
function unfurled_media(url::String)
    Dict{String, Any}("url" => url)
end
