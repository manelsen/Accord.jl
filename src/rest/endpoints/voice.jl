# Voice REST endpoints

function list_voice_regions(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/voice/regions"; token)
    parse_response_array(VoiceRegion, resp)
end
