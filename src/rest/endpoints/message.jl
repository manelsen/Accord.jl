# Message REST endpoints

function get_channel_messages(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50, around=nothing, before=nothing, after=nothing)
    query = ["limit" => string(limit)]
    !isnothing(around) && push!(query, "around" => string(around))
    !isnothing(before) && push!(query, "before" => string(before))
    !isnothing(after) && push!(query, "after" => string(after))
    resp = discord_get(rl, "/channels/$(channel_id)/messages"; token, query, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Message, resp)
end

function get_channel_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

function create_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), files=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/messages"; token, body, files, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

function crosspost_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/messages/$(message_id)/crosspost"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

function edit_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, files=nothing)
    resp = discord_patch(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, body, files, major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end

function delete_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

function bulk_delete_messages(rl::RateLimiter, channel_id::Snowflake; token::String, message_ids::Vector{Snowflake}, reason=nothing)
    body = Dict("messages" => [string(id) for id in message_ids])
    discord_post(rl, "/channels/$(channel_id)/messages/bulk-delete"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
end

# Reactions
function create_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_put(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token,
        major_params=["channel_id" => string(channel_id)])
end

function delete_own_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/@me"; token,
        major_params=["channel_id" => string(channel_id)])
end

function delete_user_reaction(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String, user_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))/$(user_id)"; token,
        major_params=["channel_id" => string(channel_id)])
end

function get_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String, limit::Int=25, type::Int=0)
    query = ["limit" => string(limit)]
    type > 0 && push!(query, "type" => string(type))
    resp = discord_get(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response_array(User, resp)
end

function delete_all_reactions(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions"; token,
        major_params=["channel_id" => string(channel_id)])
end

function delete_all_reactions_for_emoji(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, emoji::String; token::String)
    discord_delete(rl, "/channels/$(channel_id)/messages/$(message_id)/reactions/$(HTTP.URIs.escapeuri(emoji))"; token,
        major_params=["channel_id" => string(channel_id)])
end

# Polls
function get_answer_voters(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake, answer_id::Int; token::String, limit::Int=25)
    resp = discord_get(rl, "/channels/$(channel_id)/polls/$(message_id)/answers/$(answer_id)"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function end_poll(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String)
    resp = discord_post(rl, "/channels/$(channel_id)/polls/$(message_id)/expire"; token,
        major_params=["channel_id" => string(channel_id)])
    parse_response(Message, resp)
end
