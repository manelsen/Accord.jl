# Invite REST endpoints

function get_invite(rl::RateLimiter, invite_code::String; token::String, with_counts::Bool=false, with_expiration::Bool=false, guild_scheduled_event_id=nothing)
    query = Pair{String,String}[]
    with_counts && push!(query, "with_counts" => "true")
    with_expiration && push!(query, "with_expiration" => "true")
    !isnothing(guild_scheduled_event_id) && push!(query, "guild_scheduled_event_id" => string(guild_scheduled_event_id))
    resp = discord_get(rl, "/invites/$(invite_code)"; token, query=isempty(query) ? nothing : query)
    parse_response(Invite, resp)
end

function delete_invite(rl::RateLimiter, invite_code::String; token::String, reason=nothing)
    resp = discord_delete(rl, "/invites/$(invite_code)"; token, reason)
    parse_response(Invite, resp)
end
