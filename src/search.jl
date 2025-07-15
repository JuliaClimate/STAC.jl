
function FeatureCollection(url,query; method=:get, _enctype = :form_urlencoded)
    next_request =
        if method == :get
            Dict(
                :method => "GET",
                :href => string(URI(URI(url), query = query)))
        else
            Dict(
                :method => "POST",
                :href => url,
                :body => query
            )
        end

    ch = Channel{STAC.Item}() do c
        while true
            url = next_request[:href]

            if get(next_request,:method,"GET") == "POST"
                @debug "post $url" query
                if _enctype == :form_urlencoded
                    r = HTTP.post(url,[],body=next_request[:body])
                elseif _enctype == :json
                    b = JSON3.write(next_request[:body])
                    r = HTTP.post(url,[],b)
                else
                    error("unknown encoding for POST $_enctype")
                end
            else
                @debug "get $url"
                r = HTTP.get(url)
            end
            data = JSON3.read(String(r.body))

            for d in data[:features]
                geojson = GeoJSON.read(JSON3.write(d))
                put!(c,STAC.Item("",d,geojson,STAC._assets(d),nothing))
            end

            # check if there is a next page
            next = filter(d -> get(d,"rel",nothing) == "next",data[:links])

            if length(next) == 0
                # no more next page
                break
            else
                next_request = next[1]
                @debug "next " next_request
            end
        end
    end
end

format_datetime(x::Union{Dates.Date,Dates.DateTime}) = Dates.format(x,Dates.dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
format_datetime(x::Union{AbstractVector,Tuple}) = join(format_datetime.(x),"/")
format_bbox(bbox) = join(string.(bbox),',')


"""
    search(cat::Catalog, collections, lon_range, lat_range, datetime;
           limit = 100,
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

Currently only POST search requests are supported.
"""
function search(cat::Catalog, collections, lon_range, lat_range, time_range;
                query = nothing,
                filter = nothing,
                extra_query = nothing,
                limit = cat.limit)

    if collections isa AbstractString
        collections = [collections]
    end

    west, east = lon_range
    south, north = lat_range

    # for POST request in JSON format
    # e.g. do not join bbox elements as a string

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
    return FeatureCollection(
        cat.url * "/search",full_query,
        method = :post,
        _enctype = :json
    )
end

export search
