
"""
    search(cat::Catalog, collections, lon_range, lat_range, datetime; limit = 200)

Search items in a `STAC.Catalog` `cat` belong to the `collections` within the
longitude range `lon_range` (start and end longitude),
latitude range `lat_range`, and time range (start and end `DateTime`).

The function `search` returns an julia `Channel` with the search results over
which one can only iterate once. If the results should be saved use
`search_results = collect(search(cat,...))`.

Example:

```julia
using STAC, Dates
collections = "landsat-8-c2-l2"
time_range = (DateTime(2018,01,01), DateTime(2018,01,02))
lon_range = (2.51357303225, 6.15665815596)
lat_range = (49.5294835476, 51.4750237087)

cat = STAC.Catalog("https://planetarycomputer.microsoft.com/api/stac/v1")

search_results = collect(search(cat, collections, lon_range, lat_range, time_range))
```

"""
function search(cat::Catalog, collections, lon_range, lat_range, time_range; limit = 200)
    format_datetime(x::Union{Date,DateTime}) = Dates.format(x,dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
    format_datetime(x::Union{AbstractVector,Tuple}) = join(format_datetime.(x),"/")

    west, east = lon_range
    south, north = lat_range
    bbox = join(string.([west, south, east, north]),",")
    query = Dict(
        "collections" => collections,
        "bbox" => bbox,
        "limit" => limit,
        #"datetime" => string(datetime)
        #"datetime" => "2018-01-01T00:00:00Z/2018-01-01T23:59:59Z",
        "datetime" => format_datetime(time_range),
    )

    @show query
    url = string(URI(URI(cat.url * "/search"), query = query))

    ch = Channel{STAC.Item}() do c
        while true
            @debug "get $url"
            r = HTTP.get(url)
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
                url = next[1][:href]
            end
        end
    end
end

export search
