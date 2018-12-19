struct Closure{T}
    params::T
end
(s::Closure)(x::Vector) = s.apply(x, s.params)

mutable struct StepClosure{S,F,G,H} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Closure}}
    get_params::F
    apply::G
    broadcast::Bool
    trained::Bool
    skip::Bool
    prehook::H
end

function transform!(s::StepClosure, df)
    if s.broadcast
        for (k,f) in s.params
            df[k] = s.apply.(df[k], Ref(f.params))
        end
    else
        for (k,f) in s.params
            df[k] = s.apply(df[k], f.params)
        end
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
function step_closure!(r::Recipe, s...; get_params=nothing, apply=nothing, broadcast::Bool=true, skip::Bool=false, prehook=identity)
    get_params === nothing || apply === nothing && throw(error("`get_params` or `apply` kwargs not set for `step_closure!`"))
    push!(r.steps,
          StepClosure([s...],
                       nothing,
                       get_params,
                       apply,
                       broadcast,
                       false,
                       skip,
                       prehook))
end
