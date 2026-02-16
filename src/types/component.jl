"""
    SelectOption

Represents an option in a select menu (string, user, role, mentionable, or channel select).

[Discord docs](https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-option-structure)

# Fields
- `label::String` — user-facing name of the option (1-100 characters). Not shown for user/role/channel selects.
- `value::String` — developer-defined value for the option (1-100 characters). Not shown for user/role/channel selects.
- `description::Optional{String}` — additional description of the option (0-100 characters). Not shown for user/role/channel selects.
- `emoji::Optional{Emoji}` — emoji to display with the option.
- `default::Optional{Bool}` — whether this option is selected by default.
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

A message component - buttons, select menus, text inputs, and action rows. Used to create interactive messages.

[Discord docs](https://discord.com/developers/docs/interactions/message-components#component-object)

# Fields
- `type::Int` — component type. See [`ComponentTypes`](@ref) module.
- `custom_id::Optional{String}` — custom ID for the component. Max 100 characters. Required for buttons, select menus, and text inputs.
- `style::Optional{Int}` — button or text input style. See [`ButtonStyles`](@ref) or [`TextInputStyles`](@ref) modules.
- `label::Optional{String}` — text that appears on the button or text input label. Max 80 characters.
- `emoji::Optional{Emoji}` — emoji that appears on the button.
- `url::Optional{String}` — URL for link-style buttons.
- `disabled::Optional{Bool}` — whether the component is disabled. Default `false`.
- `components::Optional{Vector{Component}}` — child components (for action rows). Max 5 children for action rows.
- `options::Optional{Vector{SelectOption}}` — options for select menus. Max 25 options.
- `channel_types::Optional{Vector{Int}}` — channel types to include in channel select. Only for channel select menus.
- `placeholder::Optional{String}` — placeholder text shown when nothing is selected. Max 150 characters.
- `default_values::Optional{Vector{Any}}` — default values for auto-populated select menus.
- `min_values::Optional{Int}` — minimum number of items that must be chosen (0-25). Default 1.
- `max_values::Optional{Int}` — maximum number of items that can be chosen (1-25). Default 1.
- `min_length::Optional{Int}` — minimum input length for text inputs (0-4000).
- `max_length::Optional{Int}` — maximum input length for text inputs (1-4000).
- `required::Optional{Bool}` — whether the text input is required. Default `true`.
- `value::Optional{String}` — pre-filled value for text inputs. Max 4000 characters.
- `sku_id::Optional{Snowflake}` — SKU ID for premium buttons.
- `content::Optional{String}` — component V2: content for display components.
- `media::Optional{Any}` — component V2: media information.
- `items::Optional{Vector{Any}}` — component V2: items in the component.
- `accessory::Optional{Any}` — component V2: accessory component.
- `spoiler::Optional{Bool}` — component V2: whether this component is a spoiler.
- `description::Optional{String}` — component V2: description text.
- `divider::Optional{Bool}` — component V2: whether this is a divider.
- `spacing::Optional{Int}` — component V2: spacing value.
- `color::Optional{Int}` — component V2: accent color.
- `id::Optional{Int}` — component V2: component ID.
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
