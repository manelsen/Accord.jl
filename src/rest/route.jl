# REST Route abstraction for rate limiting
#
# Internal module: Defines the Route struct used to calculate rate limit bucket keys.
# Major parameters (channel_id, guild_id, webhook_id) are factored into bucket grouping.

"""
    Route

Use this struct when making REST API calls to properly handle Discord's rate limiting per endpoint.

Represents a Discord REST API route with method, path, and bucket key.
The bucket key groups routes that share a rate limit.
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
        if key in ("channel_id", "guild_id", "webhook_id", "webhook_token")
            push!(major, "$key:$val")
        end
    end

    bucket_key = "$method:$path_template:" * join(major, ":")
    Route(method, path, bucket_key)
end

"""Use this to get the complete URL for making HTTP requests to this route.

Full URL for this route."""
url(r::Route) = API_BASE * r.path
