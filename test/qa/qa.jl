using SciMLIterators
using JET
using SciMLTesting
using Test

# Aqua: piracies currently fails (two `tuples` methods extend the
# RecursiveArrayTools function on SciMLBase-owned argument types). Tracked in
# https://github.com/SciML/SciMLIterators.jl/issues/9
run_qa(
    SciMLIterators;
    aqua_kwargs = (; piracies = false),
    explicit_imports = true,
    # The remaining ExplicitImports violations are unavoidable non-public
    # dependency names with no public equivalent:
    #   * SciMLBase's integrator/solution interface (`AbstractTimeseriesSolution`,
    #     `DEIntegrator`, `done`) is the entire surface this package iterates over,
    #     and none of those names are exported or declared public by SciMLBase.
    #   * `Base.IteratorSize` (the iterator trait this package overloads) and its
    #     documented return value `Base.SizeUnknown` are both non-public Base
    #     internals with no public spelling.
    ei_kwargs = (;
        all_explicit_imports_are_public = (;
            ignore = (:AbstractTimeseriesSolution, :DEIntegrator, :done),
        ),
        all_qualified_accesses_are_public = (;
            ignore = (:IteratorSize, :SizeUnknown),
        ),
    ),
)

@testset "Aqua piracies (known issue #9)" begin
    @test_broken false  # Aqua piracies: 2 `tuples` methods on SciMLBase types — tracked in https://github.com/SciML/SciMLIterators.jl/issues/9
end
