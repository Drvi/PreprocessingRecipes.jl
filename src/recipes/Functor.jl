mutable struct StepFunction{S,F,G} <: AbstractStep
    selections::S
    params::Union{Nothing, Vector{Symbol}}
    f::F
    broadcast::Bool
    trained::Bool
    skip::Bool
    prehook::G
end

function transform!(s::StepFunction, df)
    if s.broadcast
        for k in s.params
            df[k] = s.f.(df[k])
        end
    else
        for k in s.params
            df[k] = s.f(df[k])
        end
    end
    df
end
function transform(s::StepFunction, df)
    transform!(s, copy(df))
end
function fit!(s::StepFunction, df)
    s.params = getselectionkeys(df, s.selections)
end
function step_function!(r::Recipe, s...; f=nothing, broadcast::Bool=true, skip::Bool=false, prehook=identity)
    f === nothing && throw(error("No function supplied to `step_function!`"))
    push!(r.steps,
          StepFunction([s...],
                       nothing,
                       f,
                       broadcast,
                       true,
                       skip,
                       prehook))
end
