using Aqua

@testset "Aqua quality checks" begin
    Aqua.test_all(Accord)
end
