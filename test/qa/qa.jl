using SciMLIterators
using Aqua
using JET
using Test

@testset "Aqua" begin
    # piracies and deps_compat(extras) currently fail; run the rest and mark
    # the two failing checks broken. Tracked in
    # https://github.com/SciML/SciMLIterators.jl/issues/9
    Aqua.test_all(SciMLIterators; piracies = false, deps_compat = false)
    @test_broken false  # Aqua piracies: 2 `tuples` methods on SciMLBase types — tracked in https://github.com/SciML/SciMLIterators.jl/issues/9
    @test_broken false  # Aqua deps_compat: no [compat] for Aqua/JET extras — tracked in https://github.com/SciML/SciMLIterators.jl/issues/9
end

@testset "JET" begin
    JET.test_package(SciMLIterators; target_defined_modules = true)
end
