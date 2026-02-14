@discord_struct PollMedia begin
    text::Optional{String}
    emoji::Optional{Emoji}
end

@discord_struct PollAnswer begin
    answer_id::Int
    poll_media::Optional{PollMedia}
end

@discord_struct PollAnswerCount begin
    id::Int
    count::Int
    me_voted::Bool
end

@discord_struct PollResults begin
    is_finalized::Bool
    answer_counts::Vector{PollAnswerCount}
end

@discord_struct Poll begin
    question::Optional{PollMedia}
    answers::Vector{PollAnswer}
    expiry::Optional{String}
    allow_multiselect::Bool
    layout_type::Int
    results::Optional{PollResults}
end
