struct Closure{T}
    params::T
end
(s::Closure)(x::Vector) = s.apply(x, s.params)

mutable struct StepClosure{S,F,G,H} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Closure}}
    get_params::F
    apply::G
    trained::Bool
    skip::Bool
    prehook::H
end

function transform!(s::StepClosure, df)
    for (k,f) in s.params
        df[k] = s.apply(df[k], f.params)
    end
    df
end
function transform(s::StepClosure, df)
    transform!(s, copy(df))
end
function fit!(s::StepClosure, df)
    s.params = Dict(col => Closure(s.get_params(s.prehook(df[col]))) for col in getselectionkeys(df, s.selections))
    s.trained = true
end
function step_closure!(r::Recipe, s...; get_params, apply, skip=false, prehook=identity)
    push!(r.steps,
          StepClosure([s...],
                       nothing,
                       get_params,
                       apply,
                       false,
                       skip,
                       prehook))
end