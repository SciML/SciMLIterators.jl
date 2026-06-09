using SciMLIterators
using Aqua
using JET
using Test

@testset "Aqua" begin
    Aqua.test_all(SciMLIterators)
end

@testset "JET" begin
    JET.test_package(SciMLIterators; target_defined_modules = true)
end
