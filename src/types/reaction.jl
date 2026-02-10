@discord_struct ReactionCountDetails begin
    burst::Int
    normal::Int
end

@discord_struct Reaction begin
    count::Int
    count_details::ReactionCountDetails
    me::Bool
    me_burst::Bool
    emoji::Emoji
    burst_colors::Vector{String}
end
