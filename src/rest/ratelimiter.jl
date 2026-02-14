# Rate limiter actor — manages per-bucket and global rate limits

"""State for a single rate limit bucket."""
mutable struct BucketState
    remaining::Int
    reset_at::Float64  # Unix timestamp
    bucket_hash::Nullable{String}
end

BucketState() = BucketState(1, 0.0, nothing)

"""A REST job submitted to the rate limiter."""
struct RestJob
    route::Route
    method::String
    url::String
    headers::Vector{Pair{String,String}}
    body::Any  # Nothing, String, Vector{UInt8}, or HTTP.Forms.Form
    result::Channel{Any}  # receives (HTTP.Response or Exception)
end

"""
    RateLimiter

Actor that processes REST requests respecting Discord's rate limits.
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
end

function RateLimiter(;global_limit::Int=50)
    RateLimiter(
        Dict{String, BucketState}(),
        Dict{String, String}(),
        0.0, global_limit, global_limit,
        Channel{RestJob}(256),
        nothing, false,
    )
end

"""Start the rate limiter actor loop."""
function start_ratelimiter!(rl::RateLimiter)
    rl.running = true
    rl.task = @async _ratelimiter_loop(rl)
    return rl
end

"""Stop the rate limiter."""
function stop_ratelimiter!(rl::RateLimiter)
    rl.running = false
    close(rl.jobs)
end

"""Submit a REST job and wait for the result."""
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

        _process_job(rl, job)
    end
end

function _process_job(rl::RateLimiter, job::RestJob)
    max_retries = 5

    for attempt in 1:max_retries
        # Check global rate limit
        now = time()
        if now < rl.global_reset_at
            wait_time = rl.global_reset_at - now
            @debug "Global rate limit, waiting" wait_time
            sleep(wait_time)
        end

        # Check bucket rate limit
        bucket_key = _get_bucket_key(rl, job.route)
        bucket = get(rl.buckets, bucket_key, nothing)
        if !isnothing(bucket) && bucket.remaining <= 0
            now = time()
            if now < bucket.reset_at
                wait_time = bucket.reset_at - now
                @debug "Bucket rate limit, waiting" bucket_key wait_time
                sleep(wait_time)
            end
        end

        # Execute request
        try
            kwargs = Dict{Symbol,Any}(
                :status_exception => false,
                :retry => false,
            )
            if !isnothing(job.body)
                kwargs[:body] = job.body
            end
            resp = HTTP.request(
                job.method, job.url, job.headers;
                kwargs...,
            )

            # Update rate limit state from headers
            _update_ratelimit(rl, job.route, resp)

            if resp.status == 429
                # Rate limited
                retry_after = _get_retry_after(resp)
                is_global = _is_global_ratelimit(resp)

                if is_global
                    @warn "Global rate limit hit" retry_after
                    rl.global_reset_at = time() + retry_after
                else
                    @warn "Bucket rate limit hit" bucket_key retry_after
                end

                sleep(retry_after)
                continue  # Retry
            end

            put!(job.result, resp)
            return
        catch e
            if attempt == max_retries
                put!(job.result, e)
                return
            end
            @warn "REST request failed, retrying" attempt exception=e
            sleep(1.0 * attempt)
        end
    end
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

function _is_global_ratelimit(resp)
    headers = Dict(lowercase(h.first) => h.second for h in resp.headers)
    haskey(headers, "x-ratelimit-global")
end
