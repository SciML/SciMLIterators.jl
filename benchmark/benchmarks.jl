using SciMLBase, SciMLIterators, BenchmarkTools

const SUITE = BenchmarkGroup()

# Minimal mock integrator/solution implementing the SciMLBase interface
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

n = 1000
states = collect(1.0:n)
times = collect(range(0.0, 10.0, length = n))

sol = GenericSolution(states, times)
integrator = GenericIntegrator(states, times, 0.0, 0.0, 0.0, 0.0)
dense_int = GenericDenseIntegrator(GenericIntegratorSolution(GenericProblem()), 0.0, 0.0)
ts = collect(range(0.0, 10.0, length = 200))

# =============================================================================
# Iterators
# =============================================================================

SUITE["iterate"] = BenchmarkGroup()

SUITE["iterate"]["tuples_solution"] = @benchmarkable collect(tuples($sol))
SUITE["iterate"]["tuples_integrator"] = @benchmarkable collect(tuples($integrator))
SUITE["iterate"]["intervals"] = @benchmarkable collect(intervals($integrator))
SUITE["iterate"]["time_choice"] = @benchmarkable collect(
    TimeChoiceIterator($dense_int, $ts)
)
