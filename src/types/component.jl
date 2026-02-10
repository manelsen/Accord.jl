@discord_struct SelectOption begin
    label::String
    value::String
    description::Optional{String}
    emoji::Optional{Emoji}
    default::Optional{Bool}
end

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
