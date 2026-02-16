# Voice REST endpoints

"""
    list_voice_regions(rl::RateLimiter; token::String) -> Vector{VoiceRegion}

Get all available voice regions.

Use this when a bot needs to list voice regions for server configuration,
voice channel setup, or region selection features.

# Arguments
- `rl::RateLimiter` — The rate limiter instance for request throttling.

# Keyword Arguments
- `token::String` — Bot authentication token.

# Note
This returns the global list of voice regions. Some regions may be VIP-only
or deprecated. Use `get_guild_voice_regions` for guild-specific regions.

# Errors
- HTTP 401 if the token is invalid.

[Discord docs](https://discord.com/developers/docs/resources/voice#list-voice-regions)
"""
function list_voice_regions(rl::RateLimiter; token::String)
    resp = discord_get(rl, "/voice/regions"; token)
    parse_response_array(VoiceRegion, resp)
end
