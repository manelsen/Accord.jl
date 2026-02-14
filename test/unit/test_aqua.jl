using Aqua

@testset "Aqua quality checks" begin
    Aqua.test_all(Accord;
        stale_deps=(ignore=[:Mocking],),
    )
end
