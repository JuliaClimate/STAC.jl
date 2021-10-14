struct Catalog
    url::String
    data
    parent
    children
    items
end

function Base.show(io::IO,cat::Catalog)
    # TODO use preferences for color
    title_color = Base.warn_color()
    cat_color = Base.info_color()
    item_color = Base.info_color()

    printstyled(io, id(cat), "\n", bold=true, color=title_color)
    printstyled(io, description(cat), "\n")

    ident = "  "
    if length(cat.children) > 0
        println("Children:")
        for (id,child) in cat.children
            print(ident," * ")
            printstyled(io, id, "\n", color=cat_color)
        end
    end

    if length(cat.items) > 0
        println("Items:")
        for (id,item) in cat.items
            print(ident," * ")
            printstyled(io, id, "\n", color=item_color)
        end
    end
end

for prop in [:id,:description]
    @eval $prop(cat::Union{Catalog,Item}) = cat.data[$prop]
    @eval export $prop
end


"""
    cat = STACatalog(url)

Open a SpatioTemporal Asset Catalog (STAC) using the provided `url`.
The `url` should point to a JSON object conforming to the
[STAC specification](https://stacspec.org/).

`cat` behaves as a julia dictionary with all STAC subcatalogs. `cat.items` is a
dictionary with all STAC items.

```jldoctest
using STACatalogs
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
cat = STACatalog(url)
subcat = cat["stac-catalog-eo"]
subcat1 = subcat["landsat-8-l1"]
@show subcat1

item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
@show item.assets[:B4][:href]
```
"""
function STACatalog(url)
    data = cached_resolve(url)

    listc = filter(l -> l[:rel] == "child",data[:links])
    children = LazyOrderedDict{String,Catalog}(listc,nothing) do link
        subcat = _subcat(STACatalog,link,url)
        id(subcat) => subcat
    end

    listi = filter(l -> l[:rel] == "item",data[:links])
    items = LazyOrderedDict{String,Item}(listi,nothing) do link
        subcat = _subcat(Item,link,url)
        id(subcat) => subcat
    end

    parent = nothing

    return Catalog(url,data,parent,children,items)
end

function _subcat(T,child,url)
    cc = child[:href]

    c = URI(url)
    cc = string(absuri(URI(path=joinpath(dirname(c.path),URI(cc).path)),c))
    return T(cc)
end

Base.keys(cat::Catalog) = keys(cat.children)
Base.getindex(cat::Catalog,child_id::String) = cat.children[child_id]

function eachcatalog(catalog::Catalog)
    function _each(channel,cat)
        for (id,child) in cat.children
            push!(channel,child)
            _each(channel,child)
        end
    end
    return Channel{Catalog}(channel -> _each(channel,catalog))
end

function eachitem(catalog::Catalog)
    function _each(channel,cat)
        for (id,item) in cat.items
            push!(channel,item)
        end
        for (id,child) in cat.children
            _each(channel,child)
        end
    end
    return Channel{Item}(channel -> _each(channel,catalog))
end

export STACatalog
export eachitem, eachcatalog
