mutable struct Enumerator{T,S}
    index::Dict{T,S}
    n::Int
end

tighteltype(x::Vector{Union{Missing,T}}) where T = any(ismissing, x) ? Union{Missing,T} : T
tighteltype(x::Vector{T}) where T = T
tighteltype(x::T) where T = T

function mininttype(x::I) where I <: Integer
    for T in [UInt8, UInt16, UInt32]
        x <= typemax(T) && return T
    end
    UInt64
end

function Enumerator(x::Vector{T}; initlabels::Union{Vector{T},Nothing}=nothing, expandinit::Bool=true, zerolabel::Union{T,Missing,Nothing}=missing) where T
    if initlabels === nothing
        labels = unique(x)
    elseif expandinit
        labels = union(initlabels, x)
    else
        throw(error("initlabels !== nothing || expandinit == true"))
    end

    if zerolabel !== nothing
        if ismissing(zerolabel)
            labels = filter(!ismissing, labels)
        else
            labels = filter(s->!s==zerolabel, labels)
        end
    end

    S = mininttype(length(labels))
    K = tighteltype(labels)

    d = Dict{promote_type(K, typeof(zerolabel)),S}(v=> S(i) for (i,v) in enumerate(labels))
    push!(d, zerolabel=>S(0))
    Enumerator(d, length(labels))
end

# TODO: widening a la PooledArrays
function (i::Enumerator{T,S})(xs::AbstractVector; expand::Bool=true) where {S,T}
    n = S(i.n)
    out = Vector{S}(undef, length(xs))
    for (j,x) in enumerate(xs)
        v = get(i.index, x, missing)
        if ismissing(v)
            !expand && throw(KeyError(x))
            out[j] = n+=S(1)
            push!(i.index, x=>n)
        else
            out[j] = v
        end
    end
    i.n = n
    out
end


mutable struct StepEnumerator{S,F,P,R} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Enumerator}}
    initlabels::P
    expandinit::Bool
    zerolabel::R
    trained::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepEnumerator, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end

function transform(s::StepEnumerator, df)
    transform!(s, copy(df))
end

function fit!(s::StepEnumerator, df)
    s.params = Dict(col => Enumerator(s.prehook(df[col]), initlabels=s.initlabels, expandinit=s.expandinit, zerolabel=s.zerolabel) for col in getselectionkeys(df, s.selections))
    s.trained = true
end

function step_enumerate!(r::Recipe, s...; initlabels=nothing, expandinit::Bool=true, zerolabel=missing, skip::Bool=false, prehook=identity)
    initlabels===nothing && !expandinit && throw(error("initlabels !== nothing || expandinit == true"))
    push!(r.steps,
          StepEnumerator([s...],
                      nothing,
                      initlabels,
                      expandinit,
                      zerolabel,
                      false,
                      skip,
                      prehook))
end
