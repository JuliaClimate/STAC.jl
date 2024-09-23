
struct Item
    url::String
    data
    assets
    parent
end

# https://github.com/radiantearth/stac-spec/blob/master/item-spec/item-spec.md

for (prop,name) in ((:id, "identifier"),
                    (:bbox, "bounding box"),
                    (:links, "links"),
                    (:properties, "properties"))
    @eval begin
        @doc """
     data = $($prop)(item)

Get the $($name) of STAC `item`.
        """
        $prop(item::Item) = item.data[$prop]
        export $prop
    end
end


"""
    dt = DateTime(item)

Get the date time of STAC `item` as a `Dates.DateTime` (or `nothing`
if this properties is not specified).
"""
function DateTime(item::Item)
    dt = get(item.data.properties,:datetime,nothing)

    if !isnothing(dt)
        return CFTime.parseDT(Dates.DateTime,dt)
    else
        return nothing
    end
end
export DateTime

"""
    data = geometry(item)

Get the geometry of STAC `item` as a GeoJSON object
"""
geometry(item::Item) = GeoJSON.geometry(GeoJSON.read(JSON3.write(item.data)))

export geometry

function Item(url; parent = nothing)
    data = cached_resolve(url)
    assets = _assets(data)
    return Item(url,data,assets,parent)
end


function Base.show(io::IO,item::Item)
    fmt(x) = @sprintf("%9.5f",x)

    bb = bbox(item);
    if isnothing(bb)
        west = south = east = north = "    ?    "
    else
        west, south, east, north = fmt.(bb)
    end
    printstyled(io, id(item), "\n", bold=true, color=title_color[])
    printstyled(io, "bounding box:\n")
    print(io,"""
    ┌──────$(north )───────┐
    │                      │
$(west)              $(east)
    │                      │
    └──────$(south )───────┘

""")

    _printstyled(io, "date time: ",DateTime(item),"\n")
    _show_assets(io,item)
end


Base.keys(item::Item) = keys(item.assets)
Base.values(item::Item) = values(item.assets)
Base.getindex(item::Item,name) = item.assets[name]
