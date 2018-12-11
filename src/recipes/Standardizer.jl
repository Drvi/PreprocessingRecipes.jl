struct Standardizer{T} <: Number
    avg::T
    std::T
end
Standardizer(x::Vector{T}) where T = (mu = mean(x); Standardizer(mu, stdm(x, mu)))
Standardizer(x::Vector{T}; robust=false) where T = Standardizer(x)
Standardizer(x::Vector{T}; robust=true) where T = (mu = median(x); Standardizer(mu, 1.482602median(abs.(x .- mu))))
(s::Standardizer)(x::Vector) = (x .- s.avg) ./ (s.std + eps(s.std))

mutable struct StepStandardize{S,F} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Standardizer}}
    robust::Bool
    trained::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepStandardize, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end
function transform(s::StepStandardize, df)
    transform!(s, copy(df))
end
function fit!(s::StepStandardize, df)
    s.params = Dict(col => Standardizer(s.prehook(df[col])) for col in getselectionkeys(df, s.selections))
    s.trained = true
end
function step_standardize!(r::Recipe, s...; robust=false, skip=false, prehook=identity)
    push!(r.steps,
          StepStandardize([s...],
                          nothing,
                          robust,
                          false,
                          skip,
                          prehook))
end
