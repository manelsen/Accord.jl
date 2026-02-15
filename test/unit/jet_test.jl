@testitem "JET" tags=[:jet] begin
    using JET, Accord

    #   2 reports: take!(::Compiler.Future) union split in gateway loop — JET artifact
    #   2 reports: send(::Nothing, ::Any) in voice/connection.jl (union split)
    #
    # If the count INCREASES, a real bug may have been introduced.
    # If the count DECREASES, tighten the threshold.
    const JET_BASELINE = 4
        # Use target_modules (JET ≥ 0.11) or target_defined_modules (JET ≤ 0.10)
    jet_kwargs = if pkgversion(JET) >= v"0.11"
        (; target_modules = (Accord,))
    else
        (; target_defined_modules = true)
    end

    result = report_package(Accord; jet_kwargs...)
    reports = JET.get_reports(result)

    # ── Report details for CI logs ──
    n = length(reports)
    if n > 0
        @info "JET found $n report(s)" details=sprint(show, result)
    end

    @test n ≤ JET_BASELINE
end
