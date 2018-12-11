struct Indexer{T,S}
    index::Dict{T,S}
    invindex::Dict{S,T}
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

function Indexer(x::Vector{T}; labels::R=nothing, forcemissing::Bool=false) where {T, R <: Union{Nothing,Vector{T},Vector{Union{Missing,T}}}}
    if labels === nothing
        labels = unique(x)
    end
    if forcemissing
        labels = vcat(missing, collect(skipmissing(labels)))
    end
    S = mininttype(length(labels))
    K = tighteltype(labels)
    Indexer(Dict{K,S}(v=>S(i) for (i,v) in enumerate(labels)),
            Dict{S,K}(S(i)=>v for (i,v) in enumerate(labels)))
end

function (i::Indexer{T,S})(x::R) where {S,T,R <: Vector{T}}
    getindex.(Ref(i.index), x)
end

function (i::Indexer{Union{Missing,T},S})(x::R) where {S,T,R<:Union{Vector{Missing},Vector{T},Vector{Union{Missing,T}}}}
    get.(Ref(i.index), x, S(1))
end

#=
Indexer(["A", "B"])(["B"])
Indexer(["A", "B", missing])(["B"])
Indexer(["A", "B", missing])([missing, "A"])
Indexer(["A", "B", missing])(["C"])
Indexer(["A", "B"])(["C"])
Indexer(["A", "B"], forcemissing=true)(["C"])
Indexer(["A", "B"])([missing, "A"])
=#

mutable struct StepIndexer{S,F} <: AbstractStep
    selections::S
    params::Union{Nothing, Dict{Symbol,Indexer}}
    labels::Bool
    forcemissing::Bool
    skip::Bool
    prehook::F
end

function transform!(s::StepIndexer, df)
    for (k,f) in s.params
        df[k] = f(df[k])
    end
    df
end

function transform(s::StepIndexer, df)
    transform!(s, copy(df))
end

function fit!(s::StepIndexer, df)
    s.params = Dict(col => Indexer(s.prehook(df[col]), labels=s.labels, forcemissing=s.forcemissing) for col in getselectionkeys(df, s.selections))
    s.trained = true
end

function step_indexer!(r::Recipe, s...; labels=nothing, forcemissing::Bool=false, prehook=identity)
    push!(r.steps,
          StepIndexer([s...],
                      nothing,
                      robust,
                      false,
                      skip,
                      prehook))
end
