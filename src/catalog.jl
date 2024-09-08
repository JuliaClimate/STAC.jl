struct Catalog
    url::String
    data
    parent
    assets
end

function Base.show(io::IO,cat::Catalog)
    printstyled(io, id(cat), "\n", bold=true, color=title_color[])
    _printstyled(io, title(cat), "\n")
    _printstyled(io, description(cat), "\n")
    _printstyled(io, "License: ",license(cat), "\n")
    _printstyled(io, "DOI: ",doi(cat), "\n")


    ident = "  "
    first_iteration = true
    for (id,child) in cat.children
        if first_iteration
            println(io,"Children:")
            first_iteration = false
        end

        print(io,ident," * ")
        printstyled(io, id, color=catalog_color[])
        printstyled(io, ": ",title(cat[id]), "\n")
    end

    first_iteration = true
    for (id,item) in cat.items
        if first_iteration
            println(io,"Items:")
            first_iteration = false
        end

        print(io,ident," * ")
        printstyled(io, id, "\n", color=item_color[])
    end

    _show_assets(io,cat)
end


for (prop,name) in (
    (:type, "type"),
    (:stac_version, "stac version"),
    (:stac_extensions, "stac extensions"),
    (:id, "identifier"),
    (:title, "title"),
    (:description, "description"),
    (:keywords, "keywords"),
    (:license, "license"),
    (:providers, "providers"),
    (:extent, "extent"),
    (:summaries, "summaries"),
    )
    @eval begin
        @doc """
    data = $($prop)(cat::Catalog; default = nothing)

Get the $($name) of a STAC catalog (or `default` if it is not specified).
        """
        $prop(cat::Catalog; default=nothing) = get(cat.data,$prop,default)
        export $prop
    end
end


"""
    data = doi(cat::Catalog; default = nothing)

Get the doi of a STAC catalog (or `default` if it is not specified).
"""
doi(cat::Catalog; default=nothing) = get(cat.data,"sci:doi",default)

function _getindex_guess(listc,fun,id)
    for item in listc
        probable_id = split(item.href,"/")[end]
        if id == probable_id
            (k,v) = fun(item)
            if k == id
                @debug "guess getindex: found $id"
                # bingo!
                return v
            end
        end
    end
    return nothing
end

"""
    cat = STAC.Catalog(url)

Open a SpatioTemporal Asset Catalog (STAC) using the provided `url`.
The `url` should point to a JSON object conforming to the
[STAC specification](https://stacspec.org/).

`cat` behaves as a julia dictionary with all STAC subcatalogs. `cat.items` is a
dictionary with all STAC items.

```julia
using STAC
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
cat = STAC.Catalog(url)
subcat = cat["stac-catalog-eo"]
subcat1 = subcat["landsat-8-l1"]
@show subcat1

item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
@show href(item.assets["B4"])
```
"""
function Catalog(url::String; parent = nothing)
    data = cached_resolve(url)
    assets = _assets(data)

    return Catalog(url,data,parent,assets)
end

function root(catalog::Catalog)
    if isnothing(catalog.parent)
        return catalog
    else
        return root(catalog.parent)
    end
end

function _from_link(T,catalog,link)
    cc = link[:href]
    c_url = string(URIs.resolvereference(catalog.url, cc))
    return T(c_url,parent = catalog)
end

function _each_direct_rel(T,catalog::Catalog,rel)
    limit = 100
    data = catalog.data
    listc = filter(l -> l[:rel] == String(rel),data[:links])

    items_links = filter(l -> l[:rel] == "items",data[:links])

    if ((rel == :item) &&
        conforms(root(catalog),CONFORMANCE.item_search) &&
        (length(items_links) > 0))

        url = first(items_links).href
        query = Dict(
            "limit" => limit,
        )
        return STAC.FeatureCollection(url,query)
    end

    Channel{T}() do c
        for child in listc
            put!(c,_from_link(T,catalog,child))
        end
    end
end

_each_direct_child(catalog::Catalog) =
    _each_direct_rel(Catalog,catalog,:child)

_each_direct_item(catalog::Catalog) =
    _each_direct_rel(Item,catalog,:item)

function _rel_ids(T,catalog::Catalog,rel)
    Channel{String}() do c
        for child in _each_direct_rel(T,catalog,rel)
            put!(c,id(child))
        end
    end
end

function _rel(T,catalog::Catalog,rel,rel_id)
    data = catalog.data
    # listc = filter(l -> l[:rel] == String(rel),data[:links])

    # # try to guess the link
    # # but check if it is correct
    # for link in listc
    #     probable_id = split(link.href,"/")[end]
    #     if rel_id == probable_id
    #         rel = _from_link(T,catalog,link)
    #         @show probable_id
    #         if id(rel) == rel_id
    #             @debug "found $rel_id"
    #             @show "found $rel_id"
    #             return rel
    #         end
    #     end
    # end

    # slow path
    for child in _each_direct_rel(T,catalog,rel)
        if id(child) == rel_id
            return child
        end
    end
    error("no $rel with the id '$rel_id' found")
end

children_ids(catalog::Catalog) = _rel_ids(Catalog,catalog,:child)
child(catalog::Catalog,id::AbstractString) = _rel(Catalog,catalog,:child,id)

items_ids(catalog::Catalog) = _rel_ids(Item,catalog,:item)
item(catalog::Catalog,id::AbstractString) = _rel(Item,catalog,:item,id)

@inline function Base.getproperty(catalog::Catalog,name::Symbol)
    if (name == :children)
        return OrderedDictWrapper(catalog,children_ids,child,_each_direct_child)
    elseif (name == :items)
        return OrderedDictWrapper(catalog,items_ids,item,_each_direct_item)
    else
        return getfield(catalog,name)
    end
end

"""
    child_ids = keys(cat::Catalog)
    subcat = cat[child_id]

Returns all subcatalog identifiers of the STAC catalog `cat`.

```julia
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
cat = STAC.Catalog(url);
keys(cat)
```
"""
Base.keys(cat::Catalog) = collect(keys(cat.children))


"""
    subcat = getindex(cat::Catalog,child_id::AbstractString)
    subcat = cat[child_id]

Returns the subcatalogs with the identifier `child_id`

```julia
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
cat = STAC.Catalog(url);
subcat = cat["stac-catalog-eo"]
```
"""
Base.getindex(cat::Catalog,child_id::AbstractString) = cat.children[child_id]


"""
    cats = eachcatalog(catalog::Catalog)

Returns resursively all subcatalogs in `catalog`.
This can take a long time for deeply nested catalogs.

```julia
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"

cat = STAC.Catalog(url)
for c in eachcatalog(cat)
    @show id(c)
end
```
"""
function eachcatalog(catalog::Catalog)
    function _each(channel,cat)
        for (id,child) in cat.children
            push!(channel,child)
            _each(channel,child)
        end
    end
    return Channel{Catalog}(channel -> _each(channel,catalog))
end

"""
    cats = eachitem(catalog::Catalog)

Returns resursively all items in `catalog`.
This can take a long time for deeply nested catalogs.

```julia
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"

cat = STAC.Catalog(url)
for c in eachitem(cat)
    @show id(c)
end
```
"""
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



function links(entry::STAC.Catalog)
    Link.(entry.data.links)
end

export eachitem, eachcatalog
