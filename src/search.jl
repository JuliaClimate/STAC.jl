

function FeatureCollection(url,query)
    ch = Channel{STAC.Item}() do c
        while true
            @debug "post $url" query
            if !isempty(query)
                r = HTTP.post(url,[],JSON3.write(query))
            else
                r = HTTP.post(url)
                #r=HTTP.get(url)
        end
            data = JSON3.read(String(r.body))
            for d in data[:features]
                put!(c,STAC.Item("",d,STAC._assets(d)))
            end

            # check if there is a next page
            next = filter(d -> get(d,"rel",nothing) == "next",data[:links])
            # no more next page
            if length(next) == 0
                break
            else
				a=next[1][:body][:collection_concept_id]
				b=next[1][:body][:page_num]
				url = next[1][:href]*"?collection_concept_id=$(a)&page_num=$(b)"
            end
        end
    end
end


"""
    search(cat::Catalog, collections, lon_range, lat_range, datetime;
           limit = 200,
           filter = nothing,
           query = nothing,
    )

Search items in a `STAC.Catalog` `cat` belong to the `collections` within the
longitude range `lon_range` (start and end longitude),
latitude range `lat_range`, and time range (start and end `DateTime`).


The optional `filter` parameter allows to filter the resuts using
[CQL2](https://github.com/stac-api-extensions/filter) (see example below).
[STACQL](https://github.com/stac-api-extensions/query/blob/3c42ab316dbba0089803e77fb572dc0cfc4ee4fe/README.md) is also supported via the optional `query` parameter.
It is recommended to use CQL2 instead of STACQL.
This `filter` and `query` are experimental and currently only part of the STAC
as a "candiate" or "pilot".

The function `search` returns an julia `Channel` with the search results over
which one can only iterate once. If the results should be saved use
`search_results = collect(search(cat,...))`.

Example:

```julia
using STAC, Dates
collections = ["landsat-8-c2-l2"]
time_range = (DateTime(2018,01,01), DateTime(2018,01,02))
lon_range = (2.51357303225, 6.15665815596)
lat_range = (49.5294835476, 51.4750237087)

catalog = STAC.Catalog("https://planetarycomputer.microsoft.com/api/stac/v1")

search_results = collect(search(catalog, collections, lon_range, lat_range, time_range))
```

Example with additional CQL2 filter

```julia
filter = Dict(
   "op" => "<=",
   "args" => [Dict("property" => "eo:cloud_cover"), 61]
)

search_results = collect(
        search(cat, collections,
               lon_range, lat_range, time_range,
               filter = filter,
))
```


"""
function search(cat::Catalog, collections, lon_range, lat_range, time_range;
                query = nothing,
                filter = nothing,
                extra_query = nothing,
                limit = 200)
    format_datetime(x::Union{Dates.Date,Dates.DateTime}) = Dates.format(x,Dates.dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
    format_datetime(x::Union{AbstractVector,Tuple}) = join(format_datetime.(x),"/")

    if collections isa AbstractString
        collections = [collections]
    end

    west, east = lon_range
    south, north = lat_range

    full_query = Dict(
        "collections" => collections,
        "bbox" => [west, south, east, north],
        "limit" => limit,
        "datetime" => format_datetime(time_range),
    )

    if !isnothing(query)
        full_query["query"] = query
    end

    if !isnothing(filter)
        full_query["filter-lang"] = "cql2-json"
        full_query["filter"] = filter
    end

    if !isnothing(extra_query)
        merge!(full_query,extra_query)
    end

    @debug "full query:" full_query
    return FeatureCollection(cat.url * "/search",full_query)
end

export search
