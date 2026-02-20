# Rate limiter actor — manages per-bucket and global rate limits
#
# Internal module: Implements Discord's rate limiting protocol. Tracks per-route
# bucket limits and global rate limits. Automatically retries on 429 responses
# with the `Retry-After` delay. Uses an actor pattern (async Task + Channel).

"""Use this internal struct to track rate limit state for each Discord API bucket.

State for a single rate limit bucket.

# Example
```julia
bucket = BucketState()  # remaining=1, reset_at=0.0
```
"""
mutable struct BucketState
    remaining::Int
    reset_at::Float64  # Unix timestamp
    bucket_hash::Nullable{String}
end

BucketState() = BucketState(1, 0.0, nothing)

struct RateLimitTimeoutError <: Exception
    bucket_key::String
    wait_time::Float64
end

struct RequestTimeoutError <: Exception
    url::String
    timeout::Float64
end

"""Use this internal struct to queue REST API requests for rate-limited execution.

A REST job submitted to the [`RateLimiter`](@ref).

# Example
```julia
result_ch = Channel{Any}(1)
job = RestJob(route, "GET", url, headers, nothing, result_ch, 30.0)
```
"""
struct RestJob
    route::Route
    method::String
    url::String
    headers::Vector{Pair{String,String}}
    body::Any
    result::Channel{Any}
    timeout::Float64
end

RestJob(route::Route, method::String, url::String, headers, body, result::Channel{Any}) =
    RestJob(route, method, url, headers, body, result, 30.0)

mutable struct RateLimiterStats
    requests_total::Int
    requests_success::Int
    requests_429::Int
    requests_5xx::Int
    requests_timeout::Int
    total_wait_time::Float64
end

"""
    RateLimiter

Use this actor to manage Discord API requests and automatically respect rate limits.

Actor that processes REST requests respecting Discord's rate limits.

!!! note
    The rate limiter automatically retries on HTTP 429 responses (up to 5 times)
    using the `Retry-After` header. You do not need to handle rate limiting yourself.

# Fields
- `default_timeout::Float64` - Default timeout in seconds for `submit_rest` (default: 30.0)
- `max_retries::Int` - Maximum retries for 429/5xx errors (default: 5)
"""
mutable struct RateLimiter
    buckets::Dict{String, BucketState}
    bucket_hashes::Dict{String, String}
    global_reset_at::Float64
    global_remaining::Int
    global_limit::Int
    jobs::Channel{RestJob}
    task::Nullable{Task}
    running::Bool
    request_handler::Function
    default_timeout::Float64
    max_retries::Int
    stats::RateLimiterStats
end

function RateLimiter(;global_limit::Int=50, default_timeout::Float64=30.0, max_retries::Int=5)
    RateLimiter(
        Dict{String, BucketState}(),
        Dict{String, String}(),
        0.0, global_limit, global_limit,
        Channel{RestJob}(256),
        nothing, false,
        (m, u, h, b) -> HTTP.request(m, u, h, b; status_exception=false, retry=false),
        default_timeout,
        max_retries,
        RateLimiterStats(0, 0, 0, 0, 0, 0.0)
    )
end

"""Use this to begin processing REST jobs through the rate limiter.

Start the [`RateLimiter`](@ref) actor loop.

# Example
```julia
rl = RateLimiter()
start_ratelimiter!(rl)  # begins processing in background
```
"""
function start_ratelimiter!(rl::RateLimiter)
    rl.running = true
    rl.task = @async _ratelimiter_loop(rl)
    return rl
end

"""Use this to gracefully shut down the rate limiter and stop processing jobs.

Stop the [`RateLimiter`](@ref).

# Example
```julia
stop_ratelimiter!(rl)  # closes job channel, stops actor
```
"""
function stop_ratelimiter!(rl::RateLimiter)
    rl.running = false
    close(rl.jobs)
end

"""Use this to queue a REST API request and receive the response through rate limiting.

Submit a [`RestJob`](@ref) and wait for the result.

# Arguments
- `timeout::Float64` - Maximum time to wait in seconds (default: `rl.default_timeout`)

# Example
```julia
resp = submit_rest(rl, job)  # blocks until response or error
resp = submit_rest(rl, job; timeout=60.0)  # with custom timeout
resp.status  # => 200
```

# Throws
- `RequestTimeoutError` if the request times out
- Other exceptions from the HTTP request or rate limiting
"""
function submit_rest(rl::RateLimiter, job::RestJob; timeout::Nullable{Float64}=nothing)
    actual_timeout = something(timeout, rl.default_timeout)
    job_with_timeout = RestJob(job.route, job.method, job.url, job.headers, job.body, job.result, actual_timeout)
    
    put!(rl.jobs, job_with_timeout)
    
    result = try
        timedwait(() -> isready(job.result), actual_timeout)
    catch
        :error
    end
    
    if result === :timed_out
        throw(RequestTimeoutError(job.url, actual_timeout))
    end
    
    result = take!(job.result)
    if result isa Exception
        throw(result)
    end
    return result
end

"""
    submit_rest(rl_actor::Actors.Link, job::RestJob; timeout=nothing)

Overload for the actor-based rate limiter.
"""
function submit_rest(rl_actor::Actors.Link, job::RestJob; timeout::Nullable{Float64}=nothing)
    # Since Actors.request is synchronous, we can just use it.
    # But we want to follow the same error handling/timeout logic.
    request(rl_actor, SubmitRest(job))
    
    # Wait for result on job.result channel (filled by actor)
    actual_timeout = something(timeout, 30.0) # Default
    result = try
        timedwait(() -> isready(job.result), actual_timeout)
    catch
        :error
    end
    
    if result === :timed_out
        throw(RequestTimeoutError(job.url, actual_timeout))
    end
    
    res = take!(job.result)
    if res isa Exception
        throw(res)
    end
    return res
end

"""Submit a REST job without blocking, returning a Channel that will receive the result.

Use this for fire-and-forget or concurrent requests.

# Example
```julia
ch = submit_rest_async(rl, job)
# ... do other work ...
resp = take!(ch)  # blocks until result is ready
```
"""
function submit_rest_async(rl::RateLimiter, job::RestJob)
    put!(rl.jobs, job)
    return job.result
end

function _ratelimiter_loop(rl::RateLimiter)
    while rl.running
        local job
        try
            job = take!(rl.jobs)
        catch e
            e isa InvalidStateException && break
            rethrow()
        end

        _process_job(rl, job)
    end
end

function _process_job(rl::RateLimiter, job::RestJob)
    rl.stats.requests_total += 1
    max_retries = rl.max_retries
    total_wait = 0.0

    for attempt in 1:max_retries
        now = time()
        
        if now < rl.global_reset_at
            wait_time = rl.global_reset_at - now
            total_wait += wait_time
            @debug "Global rate limit, waiting" wait_time
            sleep(wait_time)
        end

        bucket_key = _get_bucket_key(rl, job.route)
        bucket = get(rl.buckets, bucket_key, nothing)
        if !isnothing(bucket) && bucket.remaining <= 0
            now = time()
            if now < bucket.reset_at
                wait_time = bucket.reset_at - now
                total_wait += wait_time
                @debug "Bucket rate limit, waiting" bucket_key wait_time
                sleep(wait_time)
            end
        end

        try
            resp = rl.request_handler(job.method, job.url, job.headers, job.body)
            _update_ratelimit(rl, job.route, resp)

            if resp.status == 429
                rl.stats.requests_429 += 1
                retry_after = _get_retry_after(resp)
                scope = _get_ratelimit_scope(resp)
                is_global = scope == "global"
                
                total_wait += retry_after

                if is_global
                    @warn "Global rate limit hit" retry_after attempt
                    rl.global_reset_at = time() + retry_after
                else
                    @warn "Rate limit hit" bucket_key scope retry_after attempt
                end

                sleep(retry_after)
                continue
            end

            if resp.status >= 500
                rl.stats.requests_5xx += 1
                if attempt < max_retries
                    backoff = 2.0^(attempt - 1) + rand() * 0.5
                    total_wait += backoff
                    @warn "Server error, retrying with backoff" status=resp.status attempt backoff
                    sleep(backoff)
                    continue
                end
            end

            rl.stats.requests_success += 1
            rl.stats.total_wait_time += total_wait
            put!(job.result, resp)
            return
        catch e
            if attempt == max_retries
                put!(job.result, e)
                return
            end
            backoff = 2.0^(attempt - 1) + rand() * 0.5
            total_wait += backoff
            @warn "REST request failed, retrying with backoff" attempt exception=e backoff
            sleep(backoff)
        end
    end
    
    put!(job.result, ErrorException("Max retries ($max_retries) exceeded"))
end

function _get_bucket_key(rl::RateLimiter, route::Route)
    # Use Discord's bucket hash if known, otherwise use route bucket key
    get(rl.bucket_hashes, route.bucket_key, route.bucket_key)
end

function _update_ratelimit(rl::RateLimiter, route::Route, resp)
    headers = Dict(lowercase(h.first) => h.second for h in resp.headers)

    # Update global
    if haskey(headers, "x-ratelimit-global")
        # This response is about global limits
    end

    # Update bucket
    bucket_key = route.bucket_key
    if haskey(headers, "x-ratelimit-bucket")
        hash = headers["x-ratelimit-bucket"]
        rl.bucket_hashes[bucket_key] = hash
        bucket_key = hash
    end

    bucket = get!(rl.buckets, bucket_key, BucketState())

    if haskey(headers, "x-ratelimit-remaining")
        bucket.remaining = parse(Int, headers["x-ratelimit-remaining"])
    end
    if haskey(headers, "x-ratelimit-reset")
        bucket.reset_at = parse(Float64, headers["x-ratelimit-reset"])
    elseif haskey(headers, "x-ratelimit-reset-after")
        bucket.reset_at = time() + parse(Float64, headers["x-ratelimit-reset-after"])
    end

    rl.buckets[bucket_key] = bucket
end

function _get_retry_after(resp)
    try
        body = JSON3.read(resp.body, Dict{String, Any})
        return get(body, "retry_after", 1.0)
    catch
        # Try header
        headers = Dict(lowercase(h.first) => h.second for h in resp.headers)
        if haskey(headers, "retry-after")
            return parse(Float64, headers["retry-after"])
        end
        return 1.0
    end
end

function _get_ratelimit_scope(resp)
    headers = Dict(lowercase(h.first) => h.second for h in resp.headers)
    get(headers, "x-ratelimit-scope", 
        haskey(headers, "x-ratelimit-global") ? "global" : "user")
end

function _is_global_ratelimit(resp)
    headers = Dict(lowercase(h.first) => h.second for h in resp.headers)
    haskey(headers, "x-ratelimit-global")
end

"""Get statistics about the rate limiter's activity.

Returns a NamedTuple with:
- `requests_total` - Total requests processed
- `requests_success` - Successful requests (2xx)
- `requests_429` - Rate limited requests
- `requests_5xx` - Server error responses
- `requests_timeout` - Requests that timed out
- `total_wait_time` - Total time spent waiting for rate limits
"""
function get_stats(rl::RateLimiter)
    return (
        requests_total = rl.stats.requests_total,
        requests_success = rl.stats.requests_success,
        requests_429 = rl.stats.requests_429,
        requests_5xx = rl.stats.requests_5xx,
        requests_timeout = rl.stats.requests_timeout,
        total_wait_time = rl.stats.total_wait_time,
    )
end

"""Reset rate limiter statistics."""
function reset_stats!(rl::RateLimiter)
    rl.stats.requests_total = 0
    rl.stats.requests_success = 0
    rl.stats.requests_429 = 0
    rl.stats.requests_5xx = 0
    rl.stats.requests_timeout = 0
    rl.stats.total_wait_time = 0.0
end
