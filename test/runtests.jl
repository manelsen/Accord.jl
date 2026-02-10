using Test
using Dates
using Accord
using Accord: has_flag, JSON3, BucketState, url,
    compute_base_permissions, compute_channel_permissions

@testset "Accord.jl" begin
    include("unit/test_snowflake.jl")
    include("unit/test_flags.jl")
    include("unit/test_types.jl")
    include("unit/test_permissions.jl")
    include("unit/test_ratelimiter.jl")
    include("unit/test_components.jl")
end
