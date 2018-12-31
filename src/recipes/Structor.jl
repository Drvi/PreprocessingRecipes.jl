
struct Args{T,S}
    args::T
    kwargs::S
end

@inline function callwithargs(a::Args{T,S}, c::C, x::X) where {T,S,C,X}
    c(x, a.args...; a.kwargs...)
end
@inline function callwithargs(a::Args{T,Nothing}, c::C, x::X) where {T,C,X}
    c(x, a.args...)
end
@inline function callwithargs(a::Args{Nothing,S}, c::C, x::X) where {S,C,X}
    c(x; a.kwargs...)
end
@inline function callwithargs(a::Args{Nothing,Nothing}, c::C, x::X) where {C,X}
    c(x)
end

function tuplecast(f::F, x::NamedTuple{names,types}, a...) where {F,names,types}
    o = f.(values(x), a...)
    NamedTuple{names, typeof(o)}(o)
end
tuplecast(f::F, x::Tuple, a...) where F = f.(x, a...)
tuplecast(f::F, x::Nothing, a...) where F = nothing

function substituteargs(x::AbstractSelection, df)
    k = getselectionkeys(df, x)
    if length(k) > 1
        throw(error("Selection $(x) returned $(length(k)) columns $(k), instead of just one."))
    elseif length(k) == 0
        throw(error("Selection $(x) returned no columns."))
    else
        df[k[1]]
    end
end
substituteargs(x, df) = x
substituteargs(x::Nothing, df) = nothing

function selections_to_columns(t::Args{T,S}, df) where {T,S}
    Args(tuplecast(substituteargs, t.args, Ref(df)),
         tuplecast(substituteargs, t.kwargs, Ref(df)))
end

mutable struct StepStructor{S,F,G,A,B} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,G}}
    t::Type{G}
    broadcast::Bool
    trained::Bool
    skip::Bool
    prehook::F
    args::Args{A,B}
end

function transform!(s::StepStructor, df)
    if s.broadcast
        for (k,f) in s.params
            df[k] = f.(df[k])
        end
    else
        for (k,f) in s.params
            df[k] = f(df[k])
        end
    end
    df
end

function transform(s::StepStructor, df)
    transform!(s, copy(df))
end

function fit!(s::StepStructor, df)
    args = selections_to_columns(s.args, df)
    s.params = Dict(col => callwithargs(args, s.t, s.prehook(df[col])) for col in getselectionkeys(df, s.selections))
    s.trained = true
end

function step_struct!(r::Recipe, s...; t=nothing, broadcast::Bool=true,
    skip::Bool=false, prehook=identity, args::Union{Tuple,Nothing}=nothing,
    kwargs::Union{NamedTuple,Nothing}=nothing, names::Union{Vector{Symbol},Nothing}=nothing,
    keep::Bool=true)
    t === nothing && throw(error("No struct supplied to `step_struct!`"))
    push!(r.steps,
          StepStructor([s...],
                       nothing,
                       t,
                       broadcast,
                       false,
                       skip,
                       prehook,
                       Args(args,kwargs)))
end
