#!/usr/bin/env julia
# scripts/run_all_smokes.jl
#
# Runner to execute all Accord smoke tests and produce a consolidated report.
# Requires: DISCORD_TOKEN, TEST_GUILD_ID, TEST_CHANNEL_ID env vars.

using Dates, Printf

function run_script(path, name)
    println("-"^60)
    @printf("RUNNING: %s (%s)
", name, path)
    println("-"^60)
    
    start_time = time()
    # Run with current project and inherit env vars
    cmd = `julia --project=@. $path`
    
    success_status = true
    try
        run(cmd)
    catch e
        success_status = false
        @error "Script $name failed" exception=e
    end
    
    elapsed = time() - start_time
    return success_status, elapsed
end

function main()
    scripts = [
        ("scripts/smoketest_exercise.jl", "Exercise (Core REST/Gateway)"),
        ("scripts/smoketest_slash.jl",    "Slash Commands & Interactions"),
        ("scripts/smoketest_endurance.jl", "Endurance (Stability)")
    ]
    
    results = []
    
    println("="^60)
    println("ACCORD.JL SMOKE TEST RUNNER")
    println("Started at: ", now())
    println("="^60)
    
    all_ok = true
    for (path, name) in scripts
        if !isfile(path)
            @warn "Script not found: $path"
            continue
        end
        
        ok, dt = run_script(path, name)
        push!(results, (name, ok, dt))
        all_ok &= ok
    end
    
    println("
" * "="^60)
    println("FINAL SUMMARY REPORT")
    println("-"^60)
    @printf("%-40s | %-8s | %-10s
", "Test Suite", "Status", "Duration")
    println("-"^60)
    
    for (name, ok, dt) in results
        status = ok ? "PASS" : "FAIL"
        @printf("%-40s | %-8s | %6.2fs
", name, status, dt)
    end
    println("-"^60)
    
    if all_ok
        println("✅ ALL SMOKE TESTS PASSED")
        exit(0)
    else
        println("❌ SOME SMOKE TESTS FAILED")
        exit(1)
    end
end

main()
