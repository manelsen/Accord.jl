@testitem "Aqua" tags=[:aqua] begin
    using Aqua, Accord
    Aqua.test_all(Accord)
end
