@testitem "Aqua" tags=[:quality] begin
    using Aqua, Accord
    Aqua.test_all(Accord)
end
