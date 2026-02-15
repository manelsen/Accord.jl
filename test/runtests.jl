using ReTestItems
using Accord

# ── Accord.jl Test Suite ───────────────────────────────────────────────────

# wants_all: Default to true in CI, false locally
wants_all = get(ENV, "CI", "") == "true" || "all" in ARGS
wants_quality = any(arg -> arg in ("quality", "jet", "aqua"), ARGS)

# Filtragem de itens
function ti_filter(ti)
    if wants_quality
        return :quality in ti.tags
    elseif wants_all
        return true
    else
        # Local default: skip quality
        return !(:quality in ti.tags)
    end
end

# Execução
# nworkers=0 é essencial para cobertura e velocidade no REPL.
ReTestItems.runtests(
    ti_filter,
    Accord;
    nworkers = 0,
    report = true,
    verbose_results = true
)
