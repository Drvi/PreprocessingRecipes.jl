module PreprocessingRecipes
    import Selections: AbstractSelection, resolve, resolve_query, postprocess, selection, getfieldvec, reduce_renames
    using Statistics: mean, std
    using Dates: year, month, dayofweek, hour, minute, second

    using Optim: minimizer, optimize
    #using MultivariateStats
    #using MixedModels
    #using NearestNeighbors

    export recipe, add_roles, fit!, transform,
           step_standardize!, step_selection!, step_scale!, step_center!, step_closure!,
           step_function!, step_powertransform!, step_enumerate!, step_struct!

    include("utils.jl")
    include("Roles.jl")
    include("recipes.jl")

    include("recipes/Centerer.jl")
    include("recipes/Datetimes.jl")
    include("recipes/Scaler.jl")
    include("recipes/Selector.jl")
    include("recipes/Standardizer.jl")
    include("recipes/Closurer.jl")
    include("recipes/Functor.jl")
    include("recipes/Enumerator.jl")
    include("recipes/PowerTransformer.jl")
    include("recipes/Structor.jl")

end
