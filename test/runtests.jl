using SciMLIterators
using Test
using OrdinaryDiffEq

@testset "SciMLIterators.jl" begin
    # Simple ODE: du/dt = -u
    f(u, p, t) = -u
    prob = ODEProblem(f, 1.0, (0.0, 1.0))

    @testset "Solution tuples" begin
        sol = solve(prob, Tsit5())
        tups = tuples(sol)
        @test length(tups) == length(sol.u)
        @test tups[1] == (sol.u[1], sol.t[1])
        @test tups[end] == (sol.u[end], sol.t[end])
    end

    @testset "Integrator tuples" begin
        integrator = init(prob, Tsit5())
        count = 0
        for (u, t) in tuples(integrator)
            count += 1
            @test t >= 0.0
            @test t <= 1.0 + eps()
        end
        @test count > 0
    end

    @testset "Integrator intervals" begin
        integrator = init(prob, Tsit5())
        count = 0
        for (uprev, tprev, u, t) in intervals(integrator)
            count += 1
            @test t > tprev || count == 1  # first step tprev == t == 0
            @test t >= 0.0
        end
        @test count > 0
    end

    @testset "TimeChoiceIterator" begin
        integrator = init(prob, Tsit5())
        ts = 0.0:0.25:1.0
        iter = TimeChoiceIterator(integrator, ts)
        @test length(iter) == length(ts)
        results = collect(iter)
        @test length(results) == length(ts)
        for ((u, t), t_expected) in zip(results, ts)
            @test t == t_expected
        end
    end

    @testset "Inplace ODE" begin
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
    end
end
