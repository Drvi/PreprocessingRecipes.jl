struct Scaler{T} <: Number
    s::T
end
Scaler(x::Vector{T}) where T = std(x)
Scaler(x::Vector{T}; robust=false) where T = Scaler(x)
Scaler(x::Vector{T}; robust=true) where T = 1.482602median(abs.(x .- median(x)))

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
function step_scale!(r::Recipe, s...; robust=false, abs=false, skip=false, prehook=identity)
    push!(r.steps,
          StepScaler([s...],
                     nothing,
                     robust,
                     false,
                     skip,
                     prehook))
end
