# REST Route abstraction for rate limiting

"""
    Route

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

Create a Route with automatic bucket key generation.
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

"""Full URL for this route."""
url(r::Route) = API_BASE * r.path
