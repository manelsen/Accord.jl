using Pkg

# Check if LocalCoverage is available, if not, install it in the global environment
try
    using LocalCoverage
catch
    @info "LocalCoverage not found. Installing..."
    Pkg.add("LocalCoverage")
    using LocalCoverage
end

# Generate coverage report
# This will run the tests with coverage=true and generate an HTML report in the 'coverage' directory.
generate_pages(joinpath(@__DIR__, ".."))
