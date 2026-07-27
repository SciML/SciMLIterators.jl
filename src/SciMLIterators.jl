module SciMLIterators

using SciMLBase: AbstractTimeseriesSolution, DEIntegrator, step!, get_tmp_cache, isinplace

export tuples, intervals, TimeChoiceIterator

# ──────────────────────────────────────────────────────────────────────────────
# Integrator Tuples: iterate (u, t) pairs from an integrator
# ──────────────────────────────────────────────────────────────────────────────

struct IntegratorTuples{I}
    integrator::I
end

function Base.iterate(tup::IntegratorTuples, state = nothing)
    next = isnothing(state) ? iterate(tup.integrator) : iterate(tup.integrator, state)
    isnothing(next) && return nothing
    integrator, next_state = next
    return (integrator.u, integrator.t), next_state
end

function Base.eltype(
        ::Type{IntegratorTuples{I}},
    ) where {U, T, I <: DEIntegrator{<:Any, <:Any, U, T}}
    return Tuple{U, T}
end

Base.IteratorSize(::Type{<:IntegratorTuples{I}}) where {I} = Base.IteratorSize(I)
Base.length(tup::IntegratorTuples) = length(tup.integrator)

# ──────────────────────────────────────────────────────────────────────────────
# Integrator Intervals: iterate (uprev, tprev, u, t) tuples from an integrator
# ──────────────────────────────────────────────────────────────────────────────

struct IntegratorIntervals{I}
    integrator::I
end

function Base.iterate(tup::IntegratorIntervals, state = nothing)
    next = isnothing(state) ? iterate(tup.integrator) : iterate(tup.integrator, state)
    isnothing(next) && return nothing
    integrator, next_state = next
    return (
            integrator.uprev, integrator.tprev,
            integrator.u, integrator.t,
        ), next_state
end

function Base.eltype(
        ::Type{IntegratorIntervals{I}},
    ) where {U, T, I <: DEIntegrator{<:Any, <:Any, U, T}}
    return Tuple{U, T, U, T}
end

Base.IteratorSize(::Type{<:IntegratorIntervals{I}}) where {I} = Base.IteratorSize(I)
Base.length(tup::IntegratorIntervals) = length(tup.integrator)

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

The integrator method follows the `SciMLBase.DEIntegrator` iterator contract. Its
`Base.iterate(integrator, state)` method must either return `nothing` or
`(integrator, next_state)` after advancing the integrator. The returned integrator
must expose readable `u` and `t` fields. `tuples` neither calls solver internals
nor assumes a particular concrete integrator implementation. The solution method
requires `sol.u` and `sol.t` to have matching iteration lengths.

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
function tuples end

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

`integrator` must follow the `SciMLBase.DEIntegrator` iterator contract:
`Base.iterate(integrator, state)` returns `nothing` when iteration is complete or
`(integrator, next_state)` after advancing. The returned integrator must expose
readable `uprev`, `tprev`, `u`, and `t` fields. This API is intended for solver
implementers and analysis tools; callers must treat the input integrator as
consumed and should not concurrently step it through another interface.

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
