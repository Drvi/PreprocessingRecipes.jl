# Taken from https://github.com/tk3369/YeoJohnsonTrans.jl/blob/master/src/YeoJohnsonTrans.jl

struct PowerTransform{T}
    λ::T
end

function yj(x, λ)
    y = float.(x)
    for (i, x) in enumerate(x)
        if x >= 0
            y[i] = λ ≈ 0 ? log(x + 1) : ((x + 1)^λ - 1)/λ
        else
            y[i] = λ ≈ 2 ? -log(-x + 1) : -((-x + 1)^(2 - λ) - 1) / (2 - λ)
        end
    end
    y
end

function (r::PowerTransform)(x)
    yj(x, r.λ)
end

mutable struct StepPowerTransform{S,F} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,PowerTransform}}
    trained::Bool
    skip::Bool
    prehook::F
end

function log_likelihood(x, λ)
    N = length(x)
    y = yj(float.(x), λ)
    σ² = var(y, corrected = false)
    c = sum(sign.(x) .* log.(abs.(x) .+ one(eltype(x))))
    -N / 2.0 * log(σ²) + (λ - 1) * c
end

function lambda(x; interval = (-2.0, 3.0), optim_args...)
    i1, i2 = interval
    res = optimize(λ -> -log_likelihood(x, λ), i1, i2; optim_args...)
    round(0.1minimizer(res))/0.1
end

function transform!(s::StepPowerTransform, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end
function transform(s::StepPowerTransform, df)
    transform!(s, copy(df))
end

function fit!(s::StepPowerTransform, df)
    s.params = Dict(col => PowerTransform(lambda(s.prehook(df[col]))) for col in getselectionkeys(df, s.selections))
    s.trained = true
end

function step_powertransform!(r::Recipe, s...; skip::Bool=false, prehook=identity)
    push!(r.steps,
          StepPowerTransform([s...],
                             nothing,
                             false,
                             skip,
                             prehook))
end
