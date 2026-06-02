module SciMLIterators

using SciMLBase: SciMLBase, AbstractTimeseriesSolution, DEIntegrator,
    done, step!, get_tmp_cache, isinplace
import RecursiveArrayTools: tuples

export tuples, intervals, TimeChoiceIterator

# ──────────────────────────────────────────────────────────────────────────────
# Integrator Tuples: iterate (u, t) pairs from an integrator
# ──────────────────────────────────────────────────────────────────────────────

"""
TYPEDEF

Iterator that steps through a `DEIntegrator` and yields `(u, t)` tuples.

Created via [`tuples`](@ref).
"""
struct IntegratorTuples{I}
    integrator::I
end

function Base.iterate(tup::IntegratorTuples, state = 0)
    done(tup.integrator) && return nothing
    step!(tup.integrator)
    state += 1
    return (tup.integrator.u, tup.integrator.t), state
end

function Base.eltype(
        ::Type{IntegratorTuples{I}},
    ) where {U, T, I <: DEIntegrator{<:Any, <:Any, U, T}}
    return Tuple{U, T}
end

Base.IteratorSize(::Type{<:IntegratorTuples}) = Base.SizeUnknown()

# ──────────────────────────────────────────────────────────────────────────────
# Integrator Intervals: iterate (uprev, tprev, u, t) tuples from an integrator
# ──────────────────────────────────────────────────────────────────────────────

"""
TYPEDEF

Iterator that steps through a `DEIntegrator` and yields
`(uprev, tprev, u, t)` tuples representing solution intervals.

Created via [`intervals`](@ref).
"""
struct IntegratorIntervals{I}
    integrator::I
end

function Base.iterate(tup::IntegratorIntervals, state = 0)
    done(tup.integrator) && return nothing
    state += 1
    step!(tup.integrator)
    return (
            tup.integrator.uprev, tup.integrator.tprev,
            tup.integrator.u, tup.integrator.t,
        ), state
end

function Base.eltype(
        ::Type{IntegratorIntervals{I}},
    ) where {U, T, I <: DEIntegrator{<:Any, <:Any, U, T}}
    return Tuple{U, T, U, T}
end

Base.IteratorSize(::Type{<:IntegratorIntervals}) = Base.SizeUnknown()

# ──────────────────────────────────────────────────────────────────────────────
# TimeChoiceIterator: iterate at specific time points
# ──────────────────────────────────────────────────────────────────────────────

"""
TYPEDEF

Iterator that steps an integrator to specific time points and yields
`(u, t)` pairs at each requested time.

## Fields

Fields
"""
struct TimeChoiceIterator{T, T2}
    "The integrator to step"
    integrator::T
    "The time points to evaluate at"
    ts::T2
end

function Base.iterate(iter::TimeChoiceIterator, state = 1)
    state > length(iter.ts) && return nothing
    t = iter.ts[state]
    integrator = iter.integrator
    if isinplace(integrator.sol.prob)
        tmp = first(get_tmp_cache(integrator))
        if t == integrator.t
            tmp .= integrator.u
        elseif t < integrator.t
            integrator(tmp, t)
        else
            step!(integrator, t - integrator.t)
            integrator(tmp, t)
        end
        return (tmp, t), state + 1
    else
        if t == integrator.t
            tmp = integrator.u
        elseif t < integrator.t
            tmp = integrator(t)
        else
            step!(integrator, t - integrator.t)
            tmp = integrator(t)
        end
        return (tmp, t), state + 1
    end
end

Base.length(iter::TimeChoiceIterator) = length(iter.ts)

# ──────────────────────────────────────────────────────────────────────────────
# Solution Tuples: iterate (u, t) pairs from a solution
# ──────────────────────────────────────────────────────────────────────────────

"""
    tuples(integrator::DEIntegrator)

Create an iterator that steps the integrator and yields `(u, t)` tuples at each step.

    tuples(sol::AbstractTimeseriesSolution)

Return an array of `(u, t)` tuples from a solved solution object.
"""
tuples(integrator::DEIntegrator) = IntegratorTuples(integrator)
tuples(sol::AbstractTimeseriesSolution) = tuple.(sol.u, sol.t)

"""
    intervals(integrator::DEIntegrator)

Create an iterator that steps the integrator and yields `(uprev, tprev, u, t)` tuples
representing each solution interval.
"""
function intervals end

intervals(integrator::DEIntegrator) = IntegratorIntervals(integrator)

end # module
