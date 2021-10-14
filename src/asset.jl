struct Asset
    data
end

for (prop,name) in ((:href, "URI"),
                    (:title, "title"),
                    (:description, "description"),
                    (:type, "type"))
    @eval begin
        @doc """
     data = $($prop)(asset)

Get the $($name) of STAC `asset`.
        """
        $prop(asset::Asset) = asset.data[$prop]
        export $prop
    end
end

function Base.show(io::IO,asset::Asset)
    # TODO use preferences for color
    title_color = Base.warn_color()

    printstyled(io, title(asset), "\n", bold=true, color=title_color)
    try
        printstyled(io, description(asset), "\n")
    catch
    end
    try
        printstyled(io, "type: ",type(asset), "\n")
    catch
    end
end
