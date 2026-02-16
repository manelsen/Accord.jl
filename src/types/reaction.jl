"""
    ReactionCountDetails

Breakdown of normal and super reaction counts for an emoji reaction.

[Discord docs](https://discord.com/developers/docs/resources/message#reaction-count-details-object)

# Fields
- `burst::Int` — count of super reactions (burst).
- `normal::Int` — count of normal reactions.
"""
@discord_struct ReactionCountDetails begin
    burst::Int
    normal::Int
end

"""
    Reaction

A reaction to a message. Represents the count and users who reacted with a specific emoji.

[Discord docs](https://discord.com/developers/docs/resources/message#reaction-object)

# Fields
- `count::Int` — total number of times this emoji has been used to react.
- `count_details::Optional{ReactionCountDetails}` — reaction count details for each type (normal/super).
- `me::Bool` — whether the current user reacted using this emoji.
- `me_burst::Bool` — whether the current user super-reacted using this emoji.
- `emoji::Optional{Emoji}` — emoji information.
- `burst_colors::Vector{String}` — HEX colors used for super reaction.
"""
@discord_struct Reaction begin
    count::Int
    count_details::Optional{ReactionCountDetails}
    me::Bool
    me_burst::Bool
    emoji::Optional{Emoji}
    burst_colors::Vector{String}
end
