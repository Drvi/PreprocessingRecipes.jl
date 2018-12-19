struct Scaler{T} <: Number
    s::T
end

function Scaler(x::Vector{T}; robust::Bool=false) where T
    s = robust ? 1.482602median(abs.(x .- median(x))) : std(x)
    Scaler(s)
end

(s::Scaler)(x::Vector) = x ./ s.s

mutable struct StepScaler{S,F} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Scaler}}
    robust::Bool
    trained::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepScaler, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end
function transform(s::StepScaler, df)
    transform!(s, copy(df))
end
function fit!(s::StepScaler, df)
    s.params = Dict(col => Scaler(s.prehook(df[col])) for col in getselectionkeys(df, s.selections))
    s.trained = true
end
function step_scale!(r::Recipe, s...; robust::Bool=false, abs::Bool=false, skip::Bool=false, prehook=identity)
    push!(r.steps,
          StepScaler([s...],
                     nothing,
                     robust,
                     false,
                     skip,
                     prehook))
end
