# Rate Limiter Actor for Accord.jl

using Actors

"""
    SubmitRest(job::RestJob)

Message to submit a REST job to the rate limiter.
"""
struct SubmitRest job::RestJob end

function ratelimiter_actor(rl::RateLimiter, msg)
    if msg isa SubmitRest
        # We use the existing _process_job logic
        # Note: This still blocks the actor during sleep()
        # To truly match Nostrum, we'd need per-bucket actors.
        _process_job(rl, msg.job)
    else
        @warn "RateLimiterActor received unknown message" msg_type=typeof(msg)
    end
    return nothing
end

function spawn_ratelimiter_actor(rl::RateLimiter)
    return spawn(ratelimiter_actor, rl)
end
