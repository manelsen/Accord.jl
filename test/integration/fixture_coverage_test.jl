@testitem "Fixture Coverage Guard" tags=[:integration] begin
    include("fixture_coverage_check.jl")

    result = run_fixture_coverage_check(joinpath(@__DIR__, "fixtures"))
    @test result.ok
end
