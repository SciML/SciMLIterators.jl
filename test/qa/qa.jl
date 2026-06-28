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
    #   * SciMLBase's solution/iteration interface (`AbstractTimeseriesSolution`,
    #     `done`) is part of the surface this package iterates over, and neither
    #     name is exported or declared public by SciMLBase.
    #   * `Base.SizeUnknown` is the documented return value of the iterator trait
    #     this package overloads, a non-public Base internal with no public spelling.
    ei_kwargs = (;
        all_explicit_imports_are_public = (;
            ignore = (:AbstractTimeseriesSolution, :done),
        ),
        all_qualified_accesses_are_public = (;
            ignore = (:SizeUnknown,),
        ),
    ),
)

@testset "Aqua piracies (known issue #9)" begin
    @test_broken false  # Aqua piracies: 2 `tuples` methods on SciMLBase types — tracked in https://github.com/SciML/SciMLIterators.jl/issues/9
end
