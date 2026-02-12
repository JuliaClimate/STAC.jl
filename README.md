# STAC

<!--
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaClimate.github.io/STAC.jl/stable)
-->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaClimate.github.io/STAC.jl/dev)
[![Build Status](https://github.com/JuliaClimate/STAC.jl/workflows/CI/badge.svg)](https://github.com/JuliaClimate/STAC.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaClimate/STAC.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaClimate/STAC.jl)


This package is an experimental implementation of the [SpatioTemporal Asset Catalogs](https://stacspec.org/) (STAC) client in Julia.

Opening an issue to notify about a missing feature is not helpful for the momement. However, if somebody is interested to make a pull request to implement a missing feature, an issue is a good way to discuss its implementation.


## Installation

You need [Julia](https://julialang.org/downloads) (version 1.9 or later).
Inside a Julia terminal, you can download and install `STAC` issuing these Julia commands:

```julia
using Pkg
Pkg.add("STAC")
```

## Example

Accessing a catalog and sub-catalogs are indexed with their identitiers. To find all subcatalog identifiers, one can simply display the catalog structure in a julia session.

``` julia
using STAC
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
catalog = STAC.Catalog(url)
subcat = catalog["stac-catalog-eo"]
subcat1 = subcat["landsat-8-l1"]
@show subcat1

item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
@show href(item.assets["B4"])
```

### Copernicus Data Space Ecosystem STAC

Entries in a STAC catalog can be searched by date range and bounding box:


``` julia
using STAC, Dates

collections = ["sentinel-2-l1c"]
time_range = (DateTime(2026,2,9,10,20), DateTime(2026,2,9,10,30))
lon_range = (0, 20)  # west, east
lat_range = (32, 45)  # south, north

catalog = STAC.Catalog("https://stac.dataspace.copernicus.eu/v1/")

search_results = collect(search(catalog, collections, lon_range, lat_range, time_range))

@info "$(length(search_results)) item(s) found"
```

A full example is Copernicus Data Space Ecosystem STAC Catalog is [here](examples/copernicus_data_space_ecosystem.jl).

### NASA EarthData

Retrieve a list of OPeNDAP URLs from the NASA [Common Metadata Repository (CMR)](https://www.earthdata.nasa.gov/eosdis/science-system-description/eosdis-components/cmr) of the collection [C1996881146-POCLOUD](https://cmr.earthdata.nasa.gov/search/concepts/C1996881146-POCLOUD.html). If asked, a token can be obtained from [https://urs.earthdata.nasa.gov/home](https://urs.earthdata.nasa.gov/home) (after registration and login) and clicking on `Generate Token`:


```julia
using STAC, Dates

timerange = (DateTime(2019,1,1),DateTime(2019,12,31))
collection_concept_id = "C1996881146-POCLOUD"
baseurl = "https://cmr.earthdata.nasa.gov/search/granules.stac"

query = Dict(
    "collection_concept_id" => collection_concept_id,
    "temporal" => join(string.(timerange),','),
    "pageSize" => 1000,
)

url = baseurl
collection = STAC.FeatureCollection(url,query)

opendap_url = [href(item.assets["opendap"]) for item in collection]
@show length(opendap_url)
# output 365, one URL per day
```

To load the dataset, the NetCDF library need to be made aware of your EarthData username and password as explained [here](https://juliageo.org/NCDatasets.jl/stable/tutorials/#Data-from-NASA-EarthData).
