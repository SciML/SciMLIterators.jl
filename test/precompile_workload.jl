using OrdinaryDiffEq, SciMLIterators, Test

f(u, p, t) = -u
sol = solve(ODEProblem(f, 1.0, (0.0, 1.0)), Tsit5())

@testset "Representative public workflows" begin
    @test length(tuples(sol)) == length(sol.t)

    integrator = init(ODEProblem(f, 1.0, (0.0, 1.0)), Tsit5())
    @test !isempty(collect(tuples(integrator)))

    integrator = init(ODEProblem(f, 1.0, (0.0, 1.0)), Tsit5())
    @test !isempty(collect(intervals(integrator)))

    integrator = init(ODEProblem(f, 1.0, (0.0, 1.0)), Tsit5())
    @test length(collect(TimeChoiceIterator(integrator, 0.0:0.25:1.0))) == 5
end
