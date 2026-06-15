using SciMLIterators, OrdinaryDiffEq, Test

f(u, p, t) = -u
prob = ODEProblem(f, 1.0, (0.0, 1.0))

integrator = init(prob, Tsit5())
count = 0
for (uprev, tprev, u, t) in intervals(integrator)
    global count += 1
    @test t > tprev || count == 1  # first step tprev == t == 0
    @test t >= 0.0
end
@test count > 0
