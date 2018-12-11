
mutable struct StepDate{T,F} <: AbstractStep
    selections::T
    params::Union{Nothing,Vector{Symbol}}
    features::F
    trained::Bool
    skip::Bool
    keep::Bool
    roles::Union{Nothing,Symbol,Vector{Symbol}}
end
function fit!(step::StepDate, df)
    step.params = getselectionkeys(df, step.selections)
    step.trained = true
end

function transform!(s::StepDate, df)
    for k in s.params
        for f in s.features
            df[Symbol(string(k) * "_" * funname(f))] = f.(df[k])
        end
        if !s.keep
            deletecols!(df, k)
        end
    end
    df
end
function transform(s::StepDate, df)
    transform!(s, copy(df))
end

function update!(roles::Dict, step::StepDate)
    for k in step.params
        kroles = whichkeys(roles, k)
        newroles = step.roles === nothing ? kroles : asarray(step.roles)
        if newroles !== nothing
            for newrole in newroles
                !(newrole in keys(roles)) && get!(roles, newrole, Symbol[])
                for f in step.features
                    push!(roles[newrole], Symbol(string(k) * "_" * funname(f)))
                end
            end
        end
        if !step.keep
            if kroles !== nothing
                for role in kroles
                    roles[role] = filter(x -> !(k in x), roles[role])
                end
            end
        end
    end
    roles
end

function step_date!(r::Recipe, s...; features=[year, month, dayofweek], keep=false, roles=nothing, skip=false)
    push!(r.steps,
          StepDate([s...],
                   nothing,
                   asarray(features),
                   false,
                   skip,
                   keep,
                   roles))
end
function step_date!(r::Recipe; features=[year, month, dayofweek], keep=false, roles=nothing, skip=false)
    push!(r.steps,
          StepDate([if_eltype(Date)],
                   nothing,
                   asarray(features),
                   false,
                   skip,
                   keep,
                   roles))
end


function step_datetime!(r::Recipe, s...; features=[year, month, dayofweek, hour, minute, second], keep=false, roles=nothing, skip=false)
    push!(r.steps,
          StepDate([s...],
                   nothing,
                   asarray(features),
                   false,
                   skip,
                   keep,
                   roles))
end
function step_datetime!(r::Recipe; features=[year, month, dayofweek, hour, minute, second], keep=false, roles=nothing, skip=false)
    push!(r.steps,
          StepDate([if_eltype(DateTime)],
                   nothing,
                   asarray(features),
                   false,
                   skip,
                   keep,
                   roles))
end
