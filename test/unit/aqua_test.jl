@testitem "Aqua" tags=[:aqua] begin
    using Aqua, Accord
    # Keep deterministic CI runtime by running the fast/static Aqua checks only.
    Aqua.test_undefined_exports(Accord)
    Aqua.test_unbound_args(Accord)
    Aqua.test_project_extras(Accord)
    Aqua.test_stale_deps(Accord)
    Aqua.test_deps_compat(Accord)
end
