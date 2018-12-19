mutable struct StepStructor{S,F,G} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,G}}
    t::Type{G}
    broadcast::Bool
    trained::Bool
    skip::Bool
    prehook::F
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
    s.params = Dict(col => s.t(s.prehook(df[col])) for col in getselectionkeys(df, s.selections))
    s.trained = true
end
function step_struct!(r::Recipe, s...; t=nothing, broadcast::Bool=true, skip::Bool=false, prehook=identity)
    t === nothing && throw(error("No struct supplied to `step_structor!`"))
    push!(r.steps,
          StepStructor([s...],
                       nothing,
                       t,
                       false,
                       skip,
                       prehook))
end
