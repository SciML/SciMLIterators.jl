module SciMLIterators

using SciMLBase: SciMLBase, AbstractTimeseriesSolution, DEIntegrator,
    done, step!, get_tmp_cache, isinplace
import RecursiveArrayTools: tuples

export tuples, intervals, TimeChoiceIterator

# ──────────────────────────────────────────────────────────────────────────────
# Integrator Tuples: iterate (u, t) pairs from an integrator
# ──────────────────────────────────────────────────────────────────────────────

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
    TimeChoiceIterator(integrator, ts)

Iterator that evaluates an integrator at specified time points and yields `(u, t)`
pairs for each entry of `ts`.

# Fields

  - `integrator`: A `SciMLBase.DEIntegrator`-compatible object. Iteration mutates
    this integrator when a requested time is ahead of the current integrator time.
  - `ts`: A finite collection of requested time points. `length(ts)` defines the
    length of the iterator, and `ts[state]` must return the requested time for
    each iteration state.

# Interface

`integrator` must support the SciML integrator operations used for dense output:
`SciMLBase.isinplace(integrator.sol.prob)`, `SciMLBase.get_tmp_cache(integrator)`
for in-place problems, `SciMLBase.step!(integrator, dt)` for forward movement,
and callable dense output as `integrator(t)` or `integrator(out, t)`. Requested
times may move backward relative to the current integrator time only when the
integrator supports interpolation at that time.

# Examples

```julia
iter = init(prob, Tsit5())
for (u, t) in TimeChoiceIterator(iter, 0.0:0.25:1.0)
    # `u` is the state evaluated at the requested `t`
end
```
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
    tuples(sol::AbstractTimeseriesSolution)

Return `(u, t)` pairs from a SciML integrator or solution.

# Arguments

  - `integrator`: A `SciMLBase.DEIntegrator`. Returns an iterator that mutates the
    integrator by stepping it and yielding `(integrator.u, integrator.t)` after
    each step.
  - `sol`: A `SciMLBase.AbstractTimeseriesSolution`. Returns an array formed from
    `tuple.(sol.u, sol.t)` without mutating the solution.

# Interface

The integrator method requires the SciML integrator interface used by
`IntegratorTuples`: `SciMLBase.done`, `SciMLBase.step!`, and readable `u` and `t`
fields. The solution method requires `sol.u` and `sol.t` to have matching
iteration lengths.

# Examples

```julia
sol = solve(prob, Tsit5())
history = tuples(sol)

iter = init(prob, Tsit5())
for (u, t) in tuples(iter)
    # stream states as the integrator advances
end
```
"""
tuples(integrator::DEIntegrator) = IntegratorTuples(integrator)
tuples(sol::AbstractTimeseriesSolution) = tuple.(sol.u, sol.t)

"""
    intervals(integrator::DEIntegrator)

Create an iterator that steps the integrator and yields `(uprev, tprev, u, t)` tuples
representing each solution interval.

# Arguments

  - `integrator`: A `SciMLBase.DEIntegrator`. Iteration mutates this integrator by
    stepping it forward.

# Interface

`integrator` must implement the SciML integrator interface used by
`IntegratorIntervals`: `SciMLBase.done`, `SciMLBase.step!`, and readable
`uprev`, `tprev`, `u`, and `t` fields after each step.

# Examples

```julia
iter = init(prob, Tsit5())
for (uprev, tprev, u, t) in intervals(iter)
    dt = t - tprev
end
```
"""
function intervals end

intervals(integrator::DEIntegrator) = IntegratorIntervals(integrator)

end # module
