struct Centerer{T} <: Number
    s::T
end
Centerer(x::Vector{T}) where T = mean(x)
Centerer(x::Vector{T}; robust=false) where T = Centerer(x)
Centerer(x::Vector{T}; robust=true) where T = median(x)

(s::Centerer)(x::Vector) = x .- s.s

mutable struct StepCenterer{S,F} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Centerer}}
    robust::Bool
    trained::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepCenterer, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end
function transform(s::StepCenterer, df)
    transform!(s, copy(df))
end
function fit!(s::StepCenterer, df)
    s.params = Dict(col => Centerer(s.prehook(df[col])) for col in getselectionkeys(df, s.selections))
    s.trained = true
end
function step_center!(r::Recipe, s...; robust=false, abs=false, skip=false, prehook=identity)
    push!(r.steps,
          StepCenterer([s...],
                       nothing,
                       robust,
                       false,
                       skip,
                       prehook))
end
