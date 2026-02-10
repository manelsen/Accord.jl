# Channel REST endpoints

function get_channel(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)"; token, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function modify_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_patch(rl, "/channels/$(channel_id)"; token, body, reason, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function delete_channel(rl::RateLimiter, channel_id::Snowflake; token::String, reason=nothing)
    resp = discord_delete(rl, "/channels/$(channel_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function edit_channel_permissions(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, body::Dict, reason=nothing)
    discord_put(rl, "/channels/$(channel_id)/permissions/$(overwrite_id)"; token, body, reason, major_params=["channel_id" => string(channel_id)])
end

function delete_channel_permission(rl::RateLimiter, channel_id::Snowflake, overwrite_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/permissions/$(overwrite_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

function get_channel_invites(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/invites"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Invite, resp)
end

function create_channel_invite(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict=Dict(), reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/invites"; token, body, reason=reason, major_params=["channel_id" => string(channel_id)])
    parse_response(Invite, resp)
end

function follow_announcement_channel(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict)
    resp = discord_post(rl, "/channels/$(channel_id)/followers"; token, body, major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function trigger_typing_indicator(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_post(rl, "/channels/$(channel_id)/typing"; token, major_params=["channel_id" => string(channel_id)])
end

function get_pinned_messages(rl::RateLimiter, channel_id::Snowflake; token::String)
    resp = discord_get(rl, "/channels/$(channel_id)/pins"; token, major_params=["channel_id" => string(channel_id)])
    parse_response_array(Message, resp)
end

function pin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_put(rl, "/channels/$(channel_id)/pins/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

function unpin_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, reason=nothing)
    discord_delete(rl, "/channels/$(channel_id)/pins/$(message_id)"; token, reason, major_params=["channel_id" => string(channel_id)])
end

# Thread endpoints
function start_thread_from_message(rl::RateLimiter, channel_id::Snowflake, message_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/messages/$(message_id)/threads"; token, body, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function start_thread_without_message(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/threads"; token, body, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function start_thread_in_forum(rl::RateLimiter, channel_id::Snowflake; token::String, body::Dict, files=nothing, reason=nothing)
    resp = discord_post(rl, "/channels/$(channel_id)/threads"; token, body, files, reason=reason,
        major_params=["channel_id" => string(channel_id)])
    parse_response(DiscordChannel, resp)
end

function join_thread(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_put(rl, "/channels/$(channel_id)/thread-members/@me"; token, major_params=["channel_id" => string(channel_id)])
end

function add_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)
    discord_put(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, major_params=["channel_id" => string(channel_id)])
end

function leave_thread(rl::RateLimiter, channel_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/thread-members/@me"; token, major_params=["channel_id" => string(channel_id)])
end

function remove_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String)
    discord_delete(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, major_params=["channel_id" => string(channel_id)])
end

function get_thread_member(rl::RateLimiter, channel_id::Snowflake, user_id::Snowflake; token::String, with_member::Bool=false)
    query = with_member ? ["with_member" => "true"] : nothing
    resp = discord_get(rl, "/channels/$(channel_id)/thread-members/$(user_id)"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response(ThreadMember, resp)
end

function list_thread_members(rl::RateLimiter, channel_id::Snowflake; token::String, with_member::Bool=false, limit::Int=100)
    query = ["limit" => string(limit)]
    with_member && push!(query, "with_member" => "true")
    resp = discord_get(rl, "/channels/$(channel_id)/thread-members"; token, query,
        major_params=["channel_id" => string(channel_id)])
    parse_response_array(ThreadMember, resp)
end

function list_public_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/threads/archived/public"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function list_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/threads/archived/private"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end

function list_joined_private_archived_threads(rl::RateLimiter, channel_id::Snowflake; token::String, limit::Int=50)
    resp = discord_get(rl, "/channels/$(channel_id)/users/@me/threads/archived/private"; token,
        query=["limit" => string(limit)], major_params=["channel_id" => string(channel_id)])
    JSON3.read(resp.body, Dict{String, Any})
end
