struct Asset
    data
end

for (prop,name) in ((:href, "URI"),
                    (:title, "title"),
                    (:description, "description"),
                    (:type, "type"))
    @eval begin
        @doc """
     data = $($prop)(asset; default = nothing)

Get the $($name) of a STAC `asset` (or `default` if it is not specified).
        """
        $prop(asset::Asset; default = nothing) = get(asset.data,$prop,default)
        export $prop
    end
end

(==)(a1::Asset, a2::Asset) = a1.data == a2.data

function Base.show(io::IO,asset::Asset)
    _printstyled(io, "title: ",title(asset), "\n", bold=true, color=title_color[])
    _printstyled(io, description(asset), "\n")
    _printstyled(io, "type: ",type(asset), "\n")
    _printstyled(io, "href: ",href(asset), "\n")
end
