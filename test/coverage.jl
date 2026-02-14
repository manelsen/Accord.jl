using Pkg

# 1. Run tests with coverage
project_path = joinpath(@__DIR__, "..")
Pkg.activate(project_path)
try
    Pkg.test("Accord"; coverage=true)
catch e
    @warn "Tests failed, but proceeding to generate coverage report."
end

# 2. Use a temporary environment for coverage tools
Pkg.activate(temp=true)
Pkg.add([
    PackageSpec(name="Coverage"),
    PackageSpec(name="LocalCoverage", uuid="5f6e1e16-694c-5876-87ef-16b5274f298e")
])

using Coverage
using LocalCoverage

# 3. Process coverage results
# process_folder finds all .cov files in the src directory
coverage = process_folder(joinpath(project_path, "src"))

# 4. Show summary
relevant, covered = get_summary(coverage)
println("----------------------------------------------")
println("Coverage Summary:")
println("Relevant lines: ", relevant)
println("Covered lines:  ", covered)
println("Total Coverage: ", round(covered / relevant * 100, digits=2), "%")
println("----------------------------------------------")

# 5. Generate LCOV file
lcov_path = joinpath(project_path, "lcov.info")
LCOV.writefile(lcov_path, coverage)

# 6. Generate HTML report (LocalCoverage needs lcov.info)
# We use generate_pages which is available in newer LocalCoverage or manual call
try
    # Try to use LocalCoverage to generate the HTML report from lcov.info
    # We use the internal html_coverage if needed
    LocalCoverage.generate_coverage(project_path; run_test=false)
catch e
    @warn "Could not generate HTML report using LocalCoverage: $e"
end

# 7. Clean up .cov files
clean_folder(joinpath(project_path, "src"))

println("Coverage data written to lcov.info")
