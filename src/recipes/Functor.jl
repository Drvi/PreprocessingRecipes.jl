mutable struct StepFunction{S,F,G} <: AbstractStep
    selections::S
    params::Union{Nothing, Vector{Symbol}}
    f::F
    trained::Bool
    skip::Bool
    prehook::G
end

function transform!(s::StepFunction, df)
    for k in s.params
        df[k] = s.f(df[k])
    end
    df
end
function transform(s::StepFunction, df)
    transform!(s, copy(df))
end
function fit!(s::StepFunction, df)
    s.params = getselectionkeys(df, s.selections)
end
function step_function!(r::Recipe, s...; f=nothing, skip=false, prehook=identity)
    f === nothing && throw(error("No function supplied to `step_function!`"))
    push!(r.steps,
          StepFunction([s...],
                       nothing,
                       f,
                       true,
                       skip,
                       prehook))
end
