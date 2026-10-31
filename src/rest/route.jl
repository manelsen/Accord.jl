# REST Route abstraction for rate limiting
#
# Internal module: Defines the Route struct used to calculate rate limit bucket keys.
# Major parameters (channel_id, guild_id, webhook_id) are factored into bucket grouping.

"""
    Route

Use this struct when making REST API calls to properly handle Discord's rate limiting per endpoint.

Represents a Discord REST API route with method, path, and bucket key.
The bucket key groups routes that share a rate limit.

# Example
```julia
route = Route("GET", "/channels/{channel_id}/messages", "channel_id" => "123456")
url(route)  # => "https://discord.com/api/v10/channels/123456/messages"
```
"""
struct Route
    method::String
    path::String
    bucket_key::String
end

"""
    Route(method, path; major_params...)

Use this constructor when building REST API routes to ensure proper rate limit bucket assignment.

Create a [`Route`](@ref) with automatic bucket key generation.
Major parameters (channel_id, guild_id, webhook_id) are part of the bucket.
"""
function Route(method::String, path_template::String, params::Pair{String,String}...)
    path = path_template
    major = String[]

    for (key, val) in params
        path = replace(path, "{$key}" => val)
        if key in ("channel_id", "guild_id", "webhook_id")
            push!(major, "$key:$val")
        elseif key == "webhook_token"
            # Tokens are secrets: the bucket key ends up in log lines, so only a
            # fingerprint of the token is kept to tell buckets apart.
            push!(major, "webhook_token:" * _token_fingerprint(val))
        end
    end

    bucket_key = "$method:$(_bucket_template(path_template)):" * join(major, ":")
    Route(method, path, bucket_key)
end

# Short, non-reversible fingerprint used in place of secrets inside bucket keys.
_token_fingerprint(token::AbstractString) = string(hash(token); base=16)

# Normalise an already-substituted path so that requests sharing a Discord
# rate-limit bucket also share a bucket key. Snowflakes that follow a major
# resource (/channels/, /guilds/, /webhooks/) are kept, every other snowflake
# collapses to {id}, and webhook/interaction tokens are replaced by a
# fingerprint so they never appear in logs.
function _bucket_template(path::AbstractString)
    p = replace(path, r"(/(?:webhooks|interactions)/\d+)/([^/{}]+)" =>
        s -> begin
            m = match(r"^(/(?:webhooks|interactions)/\d+)/([^/]+)$", s)
            m === nothing ? s : m.captures[1] * "/{token:" * _token_fingerprint(m.captures[2]) * "}"
        end)
    replace(p, r"(?<!/channels|/guilds|/webhooks)/\d{5,}" => "/{id}")
end

"""Use this to get the complete URL for making HTTP requests to this route.

Full URL for this route.

# Example
```julia
route = Route("POST", "/channels/123/messages")
url(route)  # => "https://discord.com/api/v10/channels/123/messages"
```
"""
url(r::Route) = API_BASE * r.path
