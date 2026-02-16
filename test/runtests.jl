using ReTestItems
using Accord

# ── Accord.jl Granular Test Runner ─────────────────────────────────────────

function run_accord_tests()
    category = !isempty(ARGS) ? ARGS[1] : "default"
    println("▶ Accord.jl Runner | Category: $category")

    # Definimos a função de filtro baseada na categoria
    function ti_filter(ti)
        if category == "unit"
            return :unit in ti.tags
        elseif category == "integration"
            return :integration in ti.tags
        elseif category == "aqua"
            return :aqua in ti.tags
        elseif category == "jet"
            return :jet in ti.tags
        elseif category == "quality"
            return :aqua in ti.tags || :jet in ti.tags
        elseif category == "all"
            return true
        else
            # Local default: Unit + Integration (no JET/Aqua)
            return !(:aqua in ti.tags || :jet in ti.tags)
        end
    end

    # ReTestItems.runtests(filter_func, Module; ...)
    nworkers = parse(Int, get(ENV, "ACCORD_TEST_WORKERS", "6"))
    ReTestItems.runtests(
        ti_filter,
        Accord;
        nworkers = nworkers,
        report = true,
        verbose_results = true
    )
end

run_accord_tests()
