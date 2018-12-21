abstract type AbstractStep end

# create a function that gets the resolved selection names (a step between resolve and select)

mutable struct Recipe{T}
    df::T
    roles::Dict{Symbol,Vector{Symbol}}
    steps::Vector{AbstractStep}
end

# @forward Recipe.df names getindex rename! resolve
Base.names(r::Recipe) = names(r.df)
Base.getindex(r::Recipe, i...) = getindex(r.steps, i...)

update!(roles::Dict, step::AbstractStep) = roles

function recipe(df; roles...)
    if isempty(roles)
        Recipe(df, Dict{Symbol,Vector{Symbol}}(), Vector{AbstractStep}())
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

fit(r::Recipe, df) = fit!(r, copy(df))


function transform!(r::Recipe, df)
    for step in r.steps
        transform!(step, df)
    end
    df
end

transform(r::Recipe, df) = transform!(r, copy(df))
