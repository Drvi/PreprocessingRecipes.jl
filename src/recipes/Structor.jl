mutable struct StepStructor{S,F,G} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,G}}
    t::Type{G}
    trained::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepStructor, df)
    for (k,f) in s.params
        df[k] = f(df[k])
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
function step_struct!(r::Recipe, s...; t, skip=false, prehook=identity)
    push!(r.steps,
          StepStructor([s...],
                       nothing,
                       t,
                       false,
                       skip,
                       prehook))
end
