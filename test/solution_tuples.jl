using SciMLIterators, OrdinaryDiffEq, Test

f(u, p, t) = -u
prob = ODEProblem(f, 1.0, (0.0, 1.0))

sol = solve(prob, Tsit5())
tups = tuples(sol)
@test length(tups) == length(sol.u)
@test tups[1] == (sol.u[1], sol.t[1])
@test tups[end] == (sol.u[end], sol.t[end])
