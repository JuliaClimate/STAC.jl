
struct Item
    url::String
    data
    geojson
    assets
    parent
end

function (==)(item1::Item, item2::Item)
    comps = [getproperty(item1,k)==getproperty(item2,k) for k in fieldnames(Item)]
    all(comps) 
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

function parse_datetime(s::AbstractString;
    date_format::Dates.DateFormat=Dates.dateformat"yyyy-mm-ddTHH:MM:SS.sZ")
    
    # remove default UTC zone
    if endswith(s,"Z")
        s = s[1:end-1]
    end
    
    try
        dt = DateTime(s, date_format)
        return dt
    catch e
        e isa ArgumentError && return nothing
        rethrow()
    end
end

function datetime(item::Item, prop::Symbol)
    s = get(item.data.properties, prop, nothing)
    isnothing(s) && return nothing
    return parse_datetime(s)
end


"""
    dt = DateTime(item)

Get the date time of STAC `item` as a `Dates.DateTime` (or `nothing`
if this properties is not specified).
Get the start date time if the item has a timespan instead.
"""
function DateTime(item::Item)
    # mainly in field datetime
    dt = datetime(item, :datetime)
    !isnothing(dt) && return dt

    # may be a range, take the start
    dt = datetime(item, :start_datetime)
    !isnothing(dt) && return dt

    # found nothing
    return nothing
end
export DateTime

"""
    data = geometry(item)

Get the geometry of STAC `item` as a GeoJSON object
"""
geometry(item::Item) = geometry(item.geojson)

export geometry

function Item(url; parent = nothing)
    data = cached_resolve(url)
    # is there a better way?
    geojson = GeoJSON.read(JSON3.write(data))
    assets = _assets(data)
    return Item(url,data,geojson,assets,parent)
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

    if :start_datetime in keys(item.data.properties) && :end_datetime in keys(item.data.properties)
        printstyled(io, "start date time: ",datetime(item,:start_datetime),"\n")
        printstyled(io, "  end date time: ",datetime(item,:end_datetime),"\n")
    elseif :datetime in keys(item.data.properties)
        printstyled(io, "date time: ",datetime(item,:datetime),"\n")
    end

    _show_assets(io,item)
end


Base.keys(item::Item) = keys(item.assets)
Base.values(item::Item) = values(item.assets)
Base.getindex(item::Item,name) = item.assets[name]
