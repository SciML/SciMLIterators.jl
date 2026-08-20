struct _PrecompileProblem end

SciMLBase.isinplace(::_PrecompileProblem) = false

struct _PrecompileDenseSolution
    prob::_PrecompileProblem
end

struct _PrecompileTimeseriesSolution <: AbstractTimeseriesSolution{Float64, 1, Vector{Float64}}
    u::Vector{Float64}
    t::Vector{Float64}
end

mutable struct _PrecompileIntegrator <:
    SciMLBase.DEIntegrator{Nothing, false, Float64, Float64}
    sol::_PrecompileDenseSolution
    states::Vector{Float64}
    times::Vector{Float64}
    u::Float64
    t::Float64
    uprev::Float64
    tprev::Float64
end

function Base.iterate(integrator::_PrecompileIntegrator, state::Int = 1)
    state > length(integrator.states) && return nothing
    integrator.uprev, integrator.tprev = integrator.u, integrator.t
    integrator.u, integrator.t = integrator.states[state], integrator.times[state]
    return integrator, state + 1
end

Base.length(integrator::_PrecompileIntegrator) = length(integrator.states)

function SciMLBase.step!(integrator::_PrecompileIntegrator, dt)
    integrator.t += dt
    integrator.u = integrator.t^2
    return integrator
end

(integrator::_PrecompileIntegrator)(t) = t^2

@setup_workload begin
    @compile_workload begin
        solution = _PrecompileTimeseriesSolution([1.0, 2.0], [0.0, 1.0])
        tuples(solution)

        problem = _PrecompileProblem()
        integrator = _PrecompileIntegrator(
            _PrecompileDenseSolution(problem),
            [1.0, 4.0], [0.5, 1.0], 0.0, 0.0, 0.0, 0.0
        )
        collect(tuples(integrator))

        integrator = _PrecompileIntegrator(
            _PrecompileDenseSolution(problem),
            [1.0, 4.0], [0.5, 1.0], 0.0, 0.0, 0.0, 0.0
        )
        collect(intervals(integrator))

        integrator = _PrecompileIntegrator(
            _PrecompileDenseSolution(problem),
            Float64[], Float64[], 0.0, 0.0, 0.0, 0.0
        )
        collect(TimeChoiceIterator(integrator, [0.0, 0.5, 0.25]))
    end
end
