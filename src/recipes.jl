abstract type AbstractStep end
abstract type AbstractRecipe end

# create a function that gets the resolved selection names (a step between resolve and select)

mutable struct Recipe{T} <: AbstractRecipe where T
    df::T
    roles::Dict{Symbol,Vector{Symbol}}
    steps::Vector{AbstractStep}
end
mutable struct DynamicRecipe{T} <: AbstractRecipe where T
    df::T
    roles::Dict{Symbol,Vector{AbstractSelection}}
    steps::Vector{AbstractStep}
end
# @forward Recipe.df names getindex rename! resolve
Base.names(r::Recipe) = names(r.df)
Base.getindex(r::Recipe, i...) = getindex(r.steps, i...)

struct RoleSelection <: AbstractSelection
    r::Symbol
end
if_role(r::Symbol) = RoleSelection(r)
if_role(r::Vector{Symbol}) = RoleSelection.(r)
resolve(df, s::RoleSelection) = resolve(df, r.roles[s.r])

resolveroles(df, d) = Dict(k => first.(getselectionpairs(df, v)) for (k,v) in d)
update!(roles::Dict, step::AbstractStep) = roles

function recipe(df; dynamic=false, roles...)
    if dynamic
        DynamicRecipe(df, Dict(roles), Vector{AbstractStep}())
    else
        Recipe(df, resolveroles(df, Dict(roles)), Vector{AbstractStep}())
    end
end

function fit!(r::Recipe, df)
    for step in r.steps
        fit!(step, df)
        update!(r.roles, step)
        transform!(step, df)
    end
    df
end

function transform(r::Recipe, df)
    for step in r.steps
        transform!(step, df)
    end
    df
end

add_roles(r, roles...) = merge!(r.roles, Dict(roles))
