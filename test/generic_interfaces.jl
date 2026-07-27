using SciMLBase, SciMLIterators, Test

mutable struct GenericIntegrator <: SciMLBase.DEIntegrator{Nothing, false, Float64, Float64}
    states::Vector{Float64}
    times::Vector{Float64}
    u::Float64
    t::Float64
    uprev::Float64
    tprev::Float64
end

function Base.iterate(integrator::GenericIntegrator, state::Int = 1)
    state > length(integrator.states) && return nothing
    integrator.uprev, integrator.tprev = integrator.u, integrator.t
    integrator.u, integrator.t = integrator.states[state], integrator.times[state]
    return integrator, state + 1
end

Base.length(integrator::GenericIntegrator) = length(integrator.states)

struct GenericSolution <: SciMLBase.AbstractTimeseriesSolution{Float64, 1, Vector{Float64}}
    u::Vector{Float64}
    t::Vector{Float64}
end

struct GenericProblem end

SciMLBase.isinplace(::GenericProblem) = false

struct GenericIntegratorSolution
    prob::GenericProblem
end

mutable struct GenericDenseIntegrator
    sol::GenericIntegratorSolution
    u::Float64
    t::Float64
end

function SciMLBase.step!(integrator::GenericDenseIntegrator, dt)
    integrator.t += dt
    integrator.u = integrator.t^2
    return integrator
end

(integrator::GenericDenseIntegrator)(t) = t^2

@testset "Generic SciML interfaces" begin
    @test collect(tuples(GenericSolution([1.0, 2.0], [0.0, 1.0]))) ==
        [(1.0, 0.0), (2.0, 1.0)]

    tuple_integrator = GenericIntegrator([1.0, 4.0], [0.5, 1.0], 0.0, 0.0, 0.0, 0.0)
    @test collect(tuples(tuple_integrator)) == [(1.0, 0.5), (4.0, 1.0)]

    interval_integrator = GenericIntegrator([1.0, 4.0], [0.5, 1.0], 0.0, 0.0, 0.0, 0.0)
    @test collect(intervals(interval_integrator)) ==
        [(0.0, 0.0, 1.0, 0.5), (1.0, 0.5, 4.0, 1.0)]

    dense_integrator = GenericDenseIntegrator(GenericIntegratorSolution(GenericProblem()), 0.0, 0.0)
    @test collect(TimeChoiceIterator(dense_integrator, [0.0, 1.0, 0.5])) ==
        [(0.0, 0.0), (1.0, 1.0), (0.25, 0.5)]
end
