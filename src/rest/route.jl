# REST Route abstraction for rate limiting
#
# Internal module: Defines the Route struct used to calculate rate limit bucket keys.
# Major parameters (channel_id, guild_id, webhook_id/token) are read from the path.

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
    Route(method, path_template, params...)

Use this constructor when building REST API routes to ensure proper rate limit bucket assignment.

Create a [`Route`](@ref) with automatic bucket key generation. `params` are
substituted into `{name}` placeholders. The major parameters Discord uses to
split rate-limit buckets (channel, guild, webhook id and token) are read from
the resulting path, so callers never have to repeat them.
"""
function Route(method::String, path_template::String, params::Pair{String,String}...)
    path = foldl((p, (k, v)) -> replace(p, "{$k}" => v), params; init=path_template)
    bucket_key = "$method:$(_bucket_template(path_template)):" * join(_major_params(path), ":")
    Route(method, path, bucket_key)
end

# Major parameters of a concrete path, in the form used inside bucket keys:
# "channel_id:<id>" / "guild_id:<id>" (first occurrence) and, for webhook
# routes, "webhook_id:<id>" plus a fingerprint of the token, never the token.
function _major_params(path::AbstractString)
    major = String[]
    m = match(r"/(channels|guilds)/(\d+)", path)
    if m !== nothing
        kind, id = m.captures
        push!(major, (kind == "channels" ? "channel_id:" : "guild_id:") * id)
    end
    w = match(r"/webhooks/(\d+)(?:/([^/?]+))?", path)
    if w !== nothing
        id, token = w.captures
        push!(major, "webhook_id:" * id)
        token === nothing || push!(major, "webhook_token:" * _token_fingerprint(token))
    end
    return major
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
            m === nothing && return s
            prefix, token = m.captures
            (prefix === nothing || token === nothing) && return s
            prefix * "/{token:" * _token_fingerprint(token) * "}"
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
