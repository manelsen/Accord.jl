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
end
