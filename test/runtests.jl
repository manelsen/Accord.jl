using ReTestItems
using Accord

# ── Accord.jl Granular Test Runner ─────────────────────────────────────────

function run_accord_tests()
    # Se passarmos um argumento, tratamos como a tag da categoria (unit, integration, aqua, jet)
    # Se não passar nada ou for "all", roda tudo (exceto jet/aqua por padrão local)
    
    category = !isempty(ARGS) ? ARGS[1] : "default"
    
    if category == "unit"
        selected_tags = [:unit]
    elseif category == "integration"
        selected_tags = [:integration]
    elseif category == "aqua"
        selected_tags = [:aqua]
    elseif category == "jet"
        selected_tags = [:jet]
    elseif category == "quality"
        selected_tags = [:aqua, :jet]
    elseif category == "all"
        selected_tags = nothing # Tudo
    else
        # Local default: Unit + Integration
        selected_tags = ti_tags -> !(:aqua in ti_tags || :jet in ti_tags)
    end

    println("▶ Accord.jl Runner | Category: $category")

    ReTestItems.runtests(
        Accord;
        tags = selected_tags,
        nworkers = 0, # Processo principal para melhor aproveitamento de cache/cobertura
        report = true,
        verbose_results = true
    )
end

run_accord_tests()
