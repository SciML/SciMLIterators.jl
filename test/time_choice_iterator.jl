using SciMLIterators, OrdinaryDiffEq, Test

f(u, p, t) = -u
prob = ODEProblem(f, 1.0, (0.0, 1.0))

integrator = init(prob, Tsit5())
ts = 0.0:0.25:1.0
iter = TimeChoiceIterator(integrator, ts)
@test length(iter) == length(ts)
results = collect(iter)
@test length(results) == length(ts)
for ((u, t), t_expected) in zip(results, ts)
    @test t == t_expected
end
