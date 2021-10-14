
struct Item
    url::String
    data
    assets
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
   data = geometry(item)
Get the geometry of STAC `item` as a GeoJSON object
"""
geometry(item::Item) = GeoJSON.dict2geo(item.data[:geometry])
export geometry

function Item(url)
    data = cached_resolve(url)
    assets = data[:assets]
    return Item(url,data,assets)
end
