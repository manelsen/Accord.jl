"""
    SelectOption

An option within a select menu component.

# Fields
- `label::String`: The user-facing name of the option.
- `value::String`: The internal value sent to the bot when selected.
- `description::Optional{String}`: Additional text describing the option.
- `emoji::Optional{Emoji}`: Emoji to display with the option.
- `default::Optional{Bool}`: Whether this option is selected by default.

# See Also
- [Discord API: Select Option](https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-option-structure)
"""
@discord_struct SelectOption begin
    label::String
    value::String
    description::Optional{String}
    emoji::Optional{Emoji}
    default::Optional{Bool}
end

"""
    ContentScanMetadata

Results of Discord's content scanning of a media item. `flags` combines
[`ContentScanFlags`](@ref). Scanning may finish after the message is sent, so
the metadata can first arrive in a later message update.
"""
@discord_struct ContentScanMetadata begin
    flags::Int
end

"""
    ContentScanFlags

Bits of `ContentScanMetadata.flags`.

[Discord docs](https://docs.discord.com/developers/components/reference#unfurled-media-item)
"""
module ContentScanFlags
    const IS_EXPLICIT_CONTENT  = 1 << 0
    const IS_GORE_CONTENT      = 1 << 1
    const IS_SELF_HARM_CONTENT = 1 << 2
end

"""
    UnfurledMediaItem

Media shown by a Thumbnail, Media Gallery item or File component, as received.
Only `url` is set by the sender (an `https://` URL or `attachment://filename`);
Discord fills in the rest. `flags` has `1 << 0` for animated images.

[Discord docs](https://docs.discord.com/developers/components/reference#unfurled-media-item)
"""
@discord_struct UnfurledMediaItem begin
    url::String
    proxy_url::Optional{String}
    height::Maybe{Int}
    width::Maybe{Int}
    placeholder::Optional{String}
    placeholder_version::Optional{Int}
    content_type::Optional{String}
    flags::Optional{Int}
    content_scan_metadata::Optional{ContentScanMetadata}
    attachment_id::Optional{Snowflake}
end

"""
    MediaGalleryItem

One item of a received Media Gallery component.
"""
@discord_struct MediaGalleryItem begin
    media::UnfurledMediaItem = UnfurledMediaItem()
    description::Maybe{String}
    spoiler::Optional{Bool}
end

"""
    Component

Represents an interactive message component (Buttons, Select Menus, Text Inputs).

Components are organized into "Action Rows" (type 1) and allow users to trigger
interactions.

# Fields
- `type::Int`: Component type (see [`ComponentTypes`](@ref)).
- `custom_id::Optional{String}`: Developer-defined ID for the component.
- `style::Optional{Int}`: Visual style (see [`ButtonStyles`](@ref)).
- `label::Optional{String}`: Text displayed on the component.
- `emoji::Optional{Emoji}`: Emoji displayed on the component.
- `url::Optional{String}`: URL for link buttons.
- `disabled::Optional{Bool}`: Whether the component is inactive.
- `components::Optional{Vector{Component}}`: Children (Action Rows, Sections, Containers).
- `component::Optional{Component}`: The wrapped child of a Label (modals).
- `options::Optional{Vector{SelectOption}}`: Choices for select menus.
- `placeholder::Optional{String}`: Placeholder text.
- `min_values::Optional{Int}`: Minimum number of items to select.
- `max_values::Optional{Int}`: Maximum number of items to select.
- `min_length::Optional{Int}`: Minimum input length (Text Input).
- `max_length::Optional{Int}`: Maximum input length (Text Input).
- `required::Optional{Bool}`: Whether input is mandatory.
- `value::Optional{Any}`: A Text Input's text, a Radio Group's chosen value
  (`nothing` when none) or a Checkbox's `Bool`. Modal submissions only, except
  the pre-filled value of a Text Input.
- `values::Optional{Vector{String}}`: Submitted values of a select, Checkbox
  Group or File Upload (attachment ids) inside a modal.
- `default::Optional{Bool}`: Initial state of a Checkbox.
- `file_types::Optional{Vector{String}}`: Accepted types of a File Upload.
- `accent_color::Maybe{Int}`: Accent colour of a Container.
- `media::Optional{UnfurledMediaItem}`: Media of a Thumbnail or File.
- `items::Optional{Vector{MediaGalleryItem}}`: Items of a Media Gallery.

# Example
```julia
button = Component(
    type = ComponentTypes.BUTTON,
    style = ButtonStyles.PRIMARY,
    label = "Click Me",
    custom_id = "my_button"
)
row = Component(type=ComponentTypes.ACTION_ROW, components=[button])
```

# See Also
- [Discord API: Component Object](https://discord.com/developers/docs/interactions/message-components#component-object)
"""
@discord_struct Component begin
    type::Int
    custom_id::Optional{String}
    style::Optional{Int}
    label::Optional{String}
    emoji::Optional{Emoji}
    url::Optional{String}
    disabled::Optional{Bool}
    components::Optional{Vector{Component}}
    options::Optional{Vector{SelectOption}}
    channel_types::Optional{Vector{Int}}
    placeholder::Optional{String}
    default_values::Optional{Vector{Any}}
    min_values::Optional{Int}
    max_values::Optional{Int}
    min_length::Optional{Int}
    max_length::Optional{Int}
    required::Optional{Bool}
    value::Optional{Any}
    values::Optional{Vector{String}}
    default::Optional{Bool}
    file_types::Optional{Vector{String}}
    component::Optional{Component}
    sku_id::Optional{Snowflake}
    # Components V2
    content::Optional{String}
    media::Optional{UnfurledMediaItem}
    items::Optional{Vector{MediaGalleryItem}}
    accessory::Optional{Any}
    spoiler::Optional{Bool}
    description::Optional{String}
    divider::Optional{Bool}
    spacing::Optional{Int}
    accent_color::Maybe{Int}
    id::Optional{Int}
end
