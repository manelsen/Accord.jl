using Test
using Dates
using Accord
using Accord: has_flag, JSON3, StructTypes, BucketState, url,
    compute_base_permissions, compute_channel_permissions,
    @discord_struct, @discord_flags, @_flags_structtypes_int,
    CommandTree, register_command!, register_component!, register_modal!, register_autocomplete!

@testset "Accord.jl" begin
    include("unit/test_snowflake.jl")
    include("unit/test_flags.jl")
    include("unit/test_types.jl")
    include("unit/test_permissions.jl")
    include("unit/test_ratelimiter.jl")
    include("unit/test_components.jl")
        include("unit/test_macros.jl")
        include("unit/test_checks_waitfor.jl")
            include("unit/test_parsing.jl")
        
            # Integration tests - run with: julia --project=. -e 'using Pkg; Pkg.test()' -- integration
        
    # Or set ACCORD_INTEGRATION_TESTS=1
    if "integration" in ARGS || get(ENV, "ACCORD_INTEGRATION_TESTS", "") == "1"
        @testset "Integration" begin
            include("integration/test_fixtures.jl")
        end
    end
end
