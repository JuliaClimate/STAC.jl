struct Catalog
    url::String
    data
    parent
    children
    items
    assets
end

function Base.show(io::IO,cat::Catalog)
    printstyled(io, id(cat), "\n", bold=true, color=title_color[])
    _printstyled(io, title(cat), "\n")
    _printstyled(io, description(cat), "\n")
    _printstyled(io, "License: ",license(cat), "\n")
    _printstyled(io, "DOI: ",doi(cat), "\n")


    ident = "  "
    if length(cat.children) > 0
        println(io,"Children:")
        for (id,child) in cat.children
            print(io,ident," * ")
            printstyled(io, id, color=catalog_color[])
            printstyled(io, ": ",title(cat[id]), "\n")
        end
    end

    if length(cat.items) > 0
        println(io,"Items:")
        for (id,item) in cat.items
            print(io,ident," * ")
            printstyled(io, id, "\n", color=item_color[])
        end
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
function Catalog(url::String)
    data = cached_resolve(url)

    listc = filter(l -> l[:rel] == "child",data[:links])
    children = LazyOrderedDict{String,Catalog}(_getindex_guess,listc,nothing) do link
        subcat = _subcat(Catalog,link,url)
        id(subcat) => subcat
    end

    listi = filter(l -> l[:rel] == "item",data[:links])
    items = LazyOrderedDict{String,Item}(nothing,listi,nothing) do link
        subcat = _subcat(Item,link,url)
        id(subcat) => subcat
    end

    parent = nothing
    assets = _assets(data)

    return Catalog(url,data,parent,children,items,assets)
end

function _subcat(T,child,url)
    cc = child[:href]
    c_url = string(URIs.resolvereference(url, cc))
    return T(c_url)
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
Base.keys(cat::Catalog) = keys(cat.children)


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

export eachitem, eachcatalog
