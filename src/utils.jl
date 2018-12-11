funname(x) = split(string(x), ".")[end]
asarray(x) = [x]
asarray(x::Tuple) = collect(x)
asarray(x::AbstractArray) = x

getselectionpairs(df, s...) = reduce_renames(postprocess(df, resolve_query(df, [s...])))
getselectionkeys(df, s...) = first.(getselectionpairs(df, s...))

function whichkeys(d, v)
    out = Vector{Symbol}()
    for (k,vals) in d
        if v in vals
            push!(out, k)
        end
    end
    length(out) == 0 ? nothing : out
end
