#!/usr/bin/env julia

fixtures_dir = isempty(ARGS) ?
    joinpath(@__DIR__, "..", "test", "integration", "fixtures") :
    ARGS[1]

include(joinpath(@__DIR__, "..", "test", "integration", "fixture_coverage_check.jl"))

result = run_fixture_coverage_check(fixtures_dir)
exit(result.ok ? 0 : 1)
