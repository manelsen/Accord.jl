# Rate limiter — manages per-bucket and global rate limits
#
# Internal module: Implements Discord's rate limiting protocol. Tracks per-route
# bucket limits and the global request budget. Automatically retries on 429
# responses with the `Retry-After` delay.
#
# Concurrency model: a dispatcher task takes jobs from a Channel and runs each
# one in its own task. Requests in the same bucket are serialised by a
# per-bucket lock; requests in different buckets run concurrently, so a bucket
# that is waiting for its reset never blocks the others.

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

"""Use this internal struct to queue REST API requests for rate-limited execution.

A REST job submitted to the [`RateLimiter`](@ref).

`body` is either the request body itself (`nothing`, a `String`, bytes) or a
zero-argument function that builds it. Use a function for bodies that are
consumed when sent, such as multipart forms, so every retry gets a fresh body.

# Example
```julia
result_ch = Channel{Any}(1)
job = RestJob(route, "GET", url, headers, nothing, result_ch)
```
"""
struct RestJob
    route::Route
    method::String
    url::String
    headers::Vector{Pair{String,String}}
    body::Any  # Nothing, String, Vector{UInt8}, or a () -> body factory
    result::Channel{Any}  # receives (HTTP.Response or Exception)
end

"""
    RateLimiter

Use this to manage Discord API requests and automatically respect rate limits.

Processes REST requests respecting Discord's per-bucket and global rate limits.
Different buckets are served concurrently; requests within a bucket are sent
one at a time.

!!! note
    The rate limiter automatically retries on HTTP 429 responses (up to 5 times)
    using the `Retry-After` header. You do not need to handle rate limiting yourself.
    Network errors are retried only for idempotent methods (GET, HEAD, PUT,
    DELETE, OPTIONS), so a POST is never sent twice because of a dropped
    connection.
"""
mutable struct RateLimiter
    buckets::Dict{String, BucketState}
    bucket_hashes::Dict{String, String}  # route bucket_key → discord bucket hash
    global_reset_at::Float64
    global_remaining::Int
    global_limit::Int
    jobs::Channel{RestJob}
    task::Nullable{Task}
    running::Bool
    request_handler::Function # (method, url, headers, body) -> HTTP.Response
    safety_buffer::Float64
    global_window_start::Float64
    bucket_locks::Dict{String, ReentrantLock}
end

function RateLimiter(;global_limit::Int=50, safety_buffer::Float64=0.1)
    RateLimiter(
        Dict{String, BucketState}(),
        Dict{String, String}(),
        0.0, global_limit, global_limit,
        Channel{RestJob}(256),
        nothing, false,
        (m, u, h, b) -> begin
            if b === nothing
                HTTP.request(m, u, h; status_exception=false, retry=false)
            else
                HTTP.request(m, u, h, b; status_exception=false, retry=false)
            end
        end,
        safety_buffer,
        0.0,
        Dict{String, ReentrantLock}(),
    )
end

"""Use this to begin processing REST jobs through the rate limiter.

Start the [`RateLimiter`](@ref) dispatcher loop.

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

Stop the [`RateLimiter`](@ref). Requests already in flight are allowed to finish.

# Example
```julia
stop_ratelimiter!(rl)  # closes job channel, stops dispatcher
```
"""
function stop_ratelimiter!(rl::RateLimiter)
    rl.running = false
    close(rl.jobs)
end

"""Use this to queue a REST API request and receive the response through rate limiting.

Submit a [`RestJob`](@ref) and wait for the result.

# Example
```julia
resp = submit_rest(rl, job)  # blocks until response or error
resp.status  # => 200
```
"""
function submit_rest(rl::RateLimiter, job::RestJob)
    put!(rl.jobs, job)
    result = take!(job.result)
    if result isa Exception
        throw(result)
    end
    return result
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

        # One task per job: buckets are independent, so a long wait in one
        # bucket must not hold up requests to the others.
        errormonitor(@async _run_job(rl, job))
    end
end

function _run_job(rl::RateLimiter, job::RestJob)
    lk = _bucket_lock(rl, job.route)
    try
        lock(lk) do
            _process_job(rl, job)
        end
    catch e
        # _process_job always answers the caller; this only guards against bugs
        # in the limiter itself so the caller is never left waiting forever.
        isready(job.result) || put!(job.result, e)
    end
end

# Lock that serialises requests sharing the route's bucket key.
_bucket_lock(rl::RateLimiter, route::Route) =
    get!(() -> ReentrantLock(), rl.bucket_locks, route.bucket_key)

const _IDEMPOTENT_METHODS = ("GET", "HEAD", "PUT", "DELETE", "OPTIONS")

# Whether a request may be re-sent after a network error without side effects.
_is_idempotent(method::AbstractString) = uppercase(method) in _IDEMPOTENT_METHODS

# Materialise a job body; factories are called once per attempt.
_materialize_body(body) = body isa Function ? Base.invokelatest(body) : body

# Wait until the global budget (`global_limit` requests per second, plus any
# global 429 cool-down) allows one more request, then consume it.
function _acquire_global!(rl::RateLimiter)
    while true
        now = time()
        if now < rl.global_reset_at
            # Add safety buffer for clock drift/network jitter
            wait_time = (rl.global_reset_at - now) + rl.safety_buffer
            @debug "Global rate limit, waiting" wait_time
            sleep(wait_time)
            continue
        end

        if now - rl.global_window_start >= 1.0
            rl.global_window_start = now
            rl.global_remaining = rl.global_limit
        end

        if rl.global_remaining > 0
            rl.global_remaining -= 1
            return
        end

        sleep(max(0.0, rl.global_window_start + 1.0 - now))
    end
end

function _process_job(rl::RateLimiter, job::RestJob)
    max_retries = 5

    for attempt in 1:max_retries
        # Check bucket rate limit
        bucket_key = _get_bucket_key(rl, job.route)
        bucket = get(rl.buckets, bucket_key, nothing)
        if !isnothing(bucket) && bucket.remaining <= 0
            now = time()
            if now < bucket.reset_at
                # Add safety buffer for clock drift/network jitter
                wait_time = (bucket.reset_at - now) + rl.safety_buffer
                @debug "Bucket rate limit, waiting" bucket_key wait_time
                sleep(wait_time)
            end
        end

        _acquire_global!(rl)

        # Execute request
        local resp
        try
            # Use invokelatest to avoid world age issues in tests
            resp = Base.invokelatest(rl.request_handler, job.method, job.url, job.headers,
                                     _materialize_body(job.body))
        catch e
            if attempt == max_retries || !_is_idempotent(job.method)
                put!(job.result, e)
                return
            end
            # Exponential backoff with jitter for network/generic errors
            backoff = min(10.0, (2^attempt) * (0.5 + rand()))
            @warn "REST request failed, retrying with backoff" attempt backoff exception=e
            sleep(backoff)
            continue
        end

        # Update rate limit state from headers
        _update_ratelimit(rl, job.route, resp)

        if resp.status == 429 && attempt < max_retries
            retry_after = _get_retry_after(resp)
            if _is_global_ratelimit(resp)
                @warn "Global rate limit hit" retry_after
                rl.global_reset_at = time() + retry_after
            else
                @warn "Bucket rate limit hit" bucket_key retry_after
            end

            sleep(retry_after + rl.safety_buffer) # Buffer also on explicit 429
            continue  # Retry
        end

        # Success, a non-429 error, or a 429 after the last retry: the caller
        # always gets an answer.
        put!(job.result, resp)
        return
    end
end

# The major-parameter part of a route's bucket key (e.g. `channel_id:123`).
# Discord buckets are shared per hash *and* per major parameter, so two
# channels with the same bucket hash still have independent limits.
function _major_key(route::Route)
    parts = split(route.bucket_key, ':'; limit=3)
    length(parts) == 3 ? String(parts[3]) : ""
end

function _get_bucket_key(rl::RateLimiter, route::Route)
    # Use Discord's bucket hash (plus major params) if known, otherwise the route key
    bucket_hash = get(rl.bucket_hashes, route.bucket_key, nothing)
    isnothing(bucket_hash) && return route.bucket_key
    major = _major_key(route)
    isempty(major) ? bucket_hash : "$bucket_hash:$major"
end

function _update_ratelimit(rl::RateLimiter, route::Route, resp)
    bucket_hash = HTTP.header(resp, "X-RateLimit-Bucket")
    isempty(bucket_hash) || (rl.bucket_hashes[route.bucket_key] = bucket_hash)

    bucket = get!(rl.buckets, _get_bucket_key(rl, route), BucketState())
    bucket.bucket_hash = get(rl.bucket_hashes, route.bucket_key, nothing)

    remaining = HTTP.header(resp, "X-RateLimit-Remaining")
    isempty(remaining) || (bucket.remaining = parse(Int, remaining))

    reset = HTTP.header(resp, "X-RateLimit-Reset")
    reset_after = HTTP.header(resp, "X-RateLimit-Reset-After")
    if !isempty(reset)
        bucket.reset_at = parse(Float64, reset)
    elseif !isempty(reset_after)
        bucket.reset_at = time() + parse(Float64, reset_after)
    end

    return bucket
end

function _get_retry_after(resp)
    try
        body = JSON3.read(resp.body, Dict{String, Any})
        return Float64(get(body, "retry_after", 1.0))
    catch
        header = HTTP.header(resp, "Retry-After")
        return isempty(header) ? 1.0 : parse(Float64, header)
    end
end

_is_global_ratelimit(resp) = HTTP.hasheader(resp, "X-RateLimit-Global")
