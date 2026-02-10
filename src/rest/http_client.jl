# HTTP client layer for REST API requests

"""
    discord_request(rl::RateLimiter, route::Route; kwargs...) -> HTTP.Response

Execute a Discord REST API request through the rate limiter.

# Keyword arguments
- `token::String` — Bot token for Authorization header
- `body=nothing` — Request body (Dict for JSON, or raw)
- `files=nothing` — Vector of (filename, data) for multipart upload
- `reason=nothing` — Audit log reason (X-Audit-Log-Reason header)
- `query=nothing` — Query string parameters
"""
function discord_request(
    rl::RateLimiter, route::Route;
    token::String,
    body=nothing,
    files=nothing,
    reason::Nullable{String}=nothing,
    query=nothing,
)
    headers = Pair{String,String}[
        "Authorization" => token,
        "User-Agent" => USER_AGENT,
    ]

    request_url = url(route)
    if !isnothing(query)
        params = join(["$k=$(HTTP.URIs.escapeuri(string(v)))" for (k, v) in query if !isnothing(v) && !ismissing(v)], "&")
        if !isempty(params)
            request_url *= "?" * params
        end
    end

    if !isnothing(reason)
        push!(headers, "X-Audit-Log-Reason" => HTTP.URIs.escapeuri(reason))
    end

    request_body = nothing

    if !isnothing(files) && !isempty(files)
        # Multipart form upload
        parts = HTTP.Forms.Form[]
        form_data = []

        if !isnothing(body)
            push!(form_data, :payload_json => JSON3.write(body))
        end

        for (i, (filename, data, content_type)) in enumerate(files)
            push!(form_data, Symbol("files[$i]") => HTTP.Forms.File(data, filename, content_type))
        end

        request_body = HTTP.Forms.Form(form_data)
    elseif !isnothing(body)
        push!(headers, "Content-Type" => "application/json")
        request_body = JSON3.write(body)
    end

    result_ch = Channel{Any}(1)
    job = RestJob(route, route.method, request_url, headers, request_body, result_ch)

    return submit_rest(rl, job)
end

"""
    discord_get(rl, path; token, query=nothing, kwargs...) -> HTTP.Response

Convenience for GET requests.
"""
function discord_get(rl::RateLimiter, path::String; token::String, query=nothing, major_params=Pair{String,String}[])
    route = Route("GET", path, major_params...)
    discord_request(rl, route; token, query)
end

"""
    discord_post(rl, path; token, body=nothing, kwargs...) -> HTTP.Response

Convenience for POST requests.
"""
function discord_post(rl::RateLimiter, path::String; token::String, body=nothing, files=nothing, reason=nothing, major_params=Pair{String,String}[])
    route = Route("POST", path, major_params...)
    discord_request(rl, route; token, body, files, reason)
end

"""
    discord_put(rl, path; token, body=nothing, kwargs...) -> HTTP.Response

Convenience for PUT requests.
"""
function discord_put(rl::RateLimiter, path::String; token::String, body=nothing, reason=nothing, major_params=Pair{String,String}[])
    route = Route("PUT", path, major_params...)
    discord_request(rl, route; token, body, reason)
end

"""
    discord_patch(rl, path; token, body=nothing, kwargs...) -> HTTP.Response

Convenience for PATCH requests.
"""
function discord_patch(rl::RateLimiter, path::String; token::String, body=nothing, files=nothing, reason=nothing, major_params=Pair{String,String}[])
    route = Route("PATCH", path, major_params...)
    discord_request(rl, route; token, body, files, reason)
end

"""
    discord_delete(rl, path; token, kwargs...) -> HTTP.Response

Convenience for DELETE requests.
"""
function discord_delete(rl::RateLimiter, path::String; token::String, body=nothing, reason=nothing, major_params=Pair{String,String}[])
    route = Route("DELETE", path, major_params...)
    discord_request(rl, route; token, body, reason)
end

"""Parse a JSON response body into type T."""
function parse_response(::Type{T}, resp::HTTP.Response) where T
    JSON3.read(resp.body, T)
end

"""Parse a JSON response body into a Vector of type T."""
function parse_response_array(::Type{T}, resp::HTTP.Response) where T
    JSON3.read(resp.body, Vector{T})
end
