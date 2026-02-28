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
- `components::Optional{Vector{Component}}`: Children (for Action Rows).
- `options::Optional{Vector{SelectOption}}`: Choices for select menus.
- `placeholder::Optional{String}`: Placeholder text.
- `min_values::Optional{Int}`: Minimum number of items to select.
- `max_values::Optional{Int}`: Maximum number of items to select.
- `min_length::Optional{Int}`: Minimum input length (Text Input).
- `max_length::Optional{Int}`: Maximum input length (Text Input).
- `required::Optional{Bool}`: Whether input is mandatory.
- `value::Optional{String}`: Pre-filled value.

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
    value::Optional{String}
    sku_id::Optional{Snowflake}
    # Components V2
    content::Optional{String}
    media::Optional{Any}
    items::Optional{Vector{Any}}
    accessory::Optional{Any}
    spoiler::Optional{Bool}
    description::Optional{String}
    divider::Optional{Bool}
    spacing::Optional{Int}
    color::Optional{Int}
    id::Optional{Int}
end
