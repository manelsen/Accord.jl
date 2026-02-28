"""
    PollMedia

Media content (text and/or emoji) for a poll question or answer.

# See Also
- [Discord API: Poll Media Object](https://discord.com/developers/docs/resources/poll#poll-media-object)
"""
@discord_struct PollMedia begin
    text::Optional{String}
    emoji::Optional{Emoji}
end

"""
    PollAnswer

Represents an individual answer option in a [`Poll`](@ref).

# See Also
- [Discord API: Poll Answer Object](https://discord.com/developers/docs/resources/poll#poll-answer-object)
"""
@discord_struct PollAnswer begin
    answer_id::Int
    poll_media::Optional{PollMedia}
end

"""
    PollAnswerCount

The vote count for a specific poll answer.

# See Also
- [Discord API: Poll Answer Count Object](https://discord.com/developers/docs/resources/poll#poll-results-object-poll-answer-count-object)
"""
@discord_struct PollAnswerCount begin
    id::Int
    count::Int
    me_voted::Bool
end

"""
    PollResults

The results of a poll, containing vote counts for each answer.

# See Also
- [Discord API: Poll Results Object](https://discord.com/developers/docs/resources/poll#poll-results-object)
"""
@discord_struct PollResults begin
    is_finalized::Bool
    answer_counts::Vector{PollAnswerCount}
end

"""
    Poll

Represents a native Discord poll within a message.

Polls allow users to vote on predefined answers and see real-time results.

# Fields
- `question::Optional{PollMedia}`: The poll's question.
- `answers::Vector{PollAnswer}`: Up to 10 answer options.
- `expiry::Optional{String}`: ISO8601 timestamp of when the poll ends.
- `allow_multiselect::Bool`: Whether users can pick multiple answers.
- `layout_type::Int`: The visual layout (default 1).
- `results::Optional{PollResults}`: The current vote counts.

# See Also
- [Discord API: Poll Object](https://discord.com/developers/docs/resources/poll#poll-object)
"""
@discord_struct Poll begin
    question::Optional{PollMedia}
    answers::Vector{PollAnswer}
    expiry::Optional{String}
    allow_multiselect::Bool
    layout_type::Int
    results::Optional{PollResults}
end
