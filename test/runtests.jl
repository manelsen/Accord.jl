using ReTestItems
using Accord

# ── Accord.jl Test Suite ───────────────────────────────────────────────────

function run_accord_tests()
    # Se o primeiro argumento não for uma tag conhecida, tratamos como filtro de nome
    target_name = !isempty(ARGS) && !(ARGS[1] in ("all", "quality", "jet", "aqua")) ? ARGS[1] : nothing
    
    wants_all = "all" in ARGS
    wants_quality = any(arg -> arg in ("quality", "jet", "aqua"), ARGS)
    
    function ti_filter(ti)
        # Se houver um nome alvo, roda APENAS ele (feedback instantâneo)
        if !isnothing(target_name)
            return contains(ti.name, target_name)
        end

        if wants_quality
            return :quality in ti.tags
        elseif wants_all
            return true
        else
            return !(:quality in ti.tags)
        end
    end

    ReTestItems.runtests(
        ti_filter,
        Accord;
        nworkers = 0, 
        report = true,
        verbose_results = !isnothing(target_name) # Se for focado, mostre detalhes
    )
end

run_accord_tests()
