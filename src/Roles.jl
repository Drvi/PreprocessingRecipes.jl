struct RoleSelection <: AbstractSelection
    r::Symbol
end
if_role(r::Symbol) = RoleSelection(r)
if_role(r::Vector{Symbol}) = RoleSelection.(r)
resolve(df, s::RoleSelection) = resolve(df, r.roles[s.r])

resolveroles(df, d) = Dict(k => first.(getselectionpairs(df, v)) for (k,v) in d)
add_roles(r, roles...) = merge!(r.roles, Dict(roles))
