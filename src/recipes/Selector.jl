mutable struct StepSelector{T} <: AbstractStep
    selections::T
    params::Union{Nothing,Vector{Symbol}}
    trained::Bool
    skip::Bool
end
function fit!(step::StepSelector, df)
    step.params = getselectionkeys(df, step.selections)
    step.trained = true
end
function transform(s::StepSelector, df)
    df[s.params]
end
function transform!(s::StepSelector, df)
    delete!(df, setdiff(names(df), s.params))
end
function step_selection!(r::Recipe, s...; skip=false)
    push!(r.steps,
          StepSelector([s...],
                       nothing,
                       false,
                       skip))
end
