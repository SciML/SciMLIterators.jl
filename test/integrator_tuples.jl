using SciMLIterators, OrdinaryDiffEq, Test

f(u, p, t) = -u
prob = ODEProblem(f, 1.0, (0.0, 1.0))

integrator = init(prob, Tsit5())
count = 0
for (u, t) in tuples(integrator)
    global count += 1
    @test t >= 0.0
    @test t <= 1.0 + eps()
end
@test count > 0
