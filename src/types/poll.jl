"""
    PollMedia

Media object containing text and/or emoji to display in a poll.

[Discord docs](https://discord.com/developers/docs/resources/poll#poll-media-object)

# Fields
- `text::Optional{String}` — Text of the poll answer. Maximum 55 characters for questions, 55 for answers.
- `emoji::Optional{Emoji}` — Emoji to display with the text.
"""
@discord_struct PollMedia begin
    text::Optional{String}
    emoji::Optional{Emoji}
end

"""
    PollAnswer

Represents an answer in a poll, including the answer ID and the media to display.

[Discord docs](https://discord.com/developers/docs/resources/poll#poll-answer-object)

# Fields
- `answer_id::Int` — ID of the answer. Indexes start at 1.
- `poll_media::Optional{PollMedia}` — Data of the answer.
"""
@discord_struct PollAnswer begin
    answer_id::Int
    poll_media::Optional{PollMedia}
end

"""
    PollAnswerCount

Represents the count of votes for a particular answer.

[Discord docs](https://discord.com/developers/docs/resources/poll#poll-results-object-poll-answer-count-object)

# Fields
- `id::Int` — ID of the answer this count is for.
- `count::Int` — Number of votes for this answer.
- `me_voted::Bool` — Whether the current user voted for this answer.
"""
@discord_struct PollAnswerCount begin
    id::Int
    count::Int
    me_voted::Bool
end

"""
    PollResults

Results of a poll, including vote counts for each answer.

[Discord docs](https://discord.com/developers/docs/resources/poll#poll-results-object)

# Fields
- `is_finalized::Bool` — Whether the votes have been precisely counted.
- `answer_counts::Vector{PollAnswerCount}` — Counts for each answer. Not all answers may be present.
"""
@discord_struct PollResults begin
    is_finalized::Bool
    answer_counts::Vector{PollAnswerCount}
end

"""
    Poll

Represents a poll in a message. Allows users to vote on one or more answers.

[Discord docs](https://discord.com/developers/docs/resources/poll#poll-object)

# Fields
- `question::Optional{PollMedia}` — Question of the poll. Maximum 300 characters total across both text and emoji.
- `answers::Vector{PollAnswer}` — Each of the answers available in the poll. Maximum 10 answers.
- `expiry::Optional{String}` — ISO8601 timestamp when the poll ends. `nothing` for non-expiring polls.
- `allow_multiselect::Bool` — Whether a user can select multiple answers.
- `layout_type::Int` — Layout type of the poll. See `PollLayoutTypes` (1 = default).
- `results::Optional{PollResults}` — Results of the poll. Not present when fetching the poll, must be requested separately.
"""
@discord_struct Poll begin
    question::Optional{PollMedia}
    answers::Vector{PollAnswer}
    expiry::Optional{String}
    allow_multiselect::Bool
    layout_type::Int
    results::Optional{PollResults}
end
