using SciMLIterators, OrdinaryDiffEq, Test

f!(du, u, p, t) = (du .= -u)
prob_ip = ODEProblem(f!, [1.0, 2.0], (0.0, 1.0))
sol = solve(prob_ip, Tsit5())

tups = tuples(sol)
@test length(tups) == length(sol.u)
@test tups[1][1] == sol.u[1]

integrator = init(prob_ip, Tsit5())
ts = [0.0, 0.5, 1.0]
iter = TimeChoiceIterator(integrator, ts)
results = collect(iter)
@test length(results) == 3
