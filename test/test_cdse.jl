# Copernicus Data Space Ecosystem STAC Catalog

using STAC
using Dates

collections = ["sentinel-2-l1c"]
time_range = (DateTime(2026,2,9,10,20), DateTime(2026,2,9,10,30))
lon_range = (0, 20)  # west, east
lat_range = (32, 45)  # south, north

catalog = STAC.Catalog("https://stac.dataspace.copernicus.eu/v1/")

search_results = collect(search(catalog, collections, lon_range, lat_range, time_range))

@test length(search_results) > 0

item1 = first(search_results)

@test haskey(item1.assets,"Product")

