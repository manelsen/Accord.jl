"""
    ReactionCountDetails

Breakdown of normal and super (burst) reaction counts.

# See Also
- [Discord API: Reaction Count Details](https://discord.com/developers/docs/resources/message#reaction-count-details-object)
"""
@discord_struct ReactionCountDetails begin
    burst::Int
    normal::Int
end

"""
    Reaction

Represents an emoji reaction to a Discord message.

# Fields
- `count::Int`: Total number of times this emoji was used.
- `count_details::Optional{ReactionCountDetails}`: Specific breakdown of reaction types.
- `me::Bool`: Whether the current bot/user reacted with this emoji.
- `me_burst::Bool`: Whether the current user super-reacted.
- `emoji::Optional{Emoji}`: The emoji used for the reaction.
- `burst_colors::Vector{String}`: HEX colors for the super-reaction animation.

# See Also
- [Discord API: Reaction Object](https://discord.com/developers/docs/resources/message#reaction-object)
"""
@discord_struct Reaction begin
    count::Int
    count_details::Optional{ReactionCountDetails}
    me::Bool
    me_burst::Bool
    emoji::Optional{Emoji}
    burst_colors::Vector{String}
end
