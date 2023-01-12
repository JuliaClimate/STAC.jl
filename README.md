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

You need [Julia](https://julialang.org/downloads) (version 1.6 or later).
Inside a Julia terminal, you can download and install `STAC` issuing these commands:

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

Searching by date range and bounding box:

``` julia
using STAC, Dates
collections = "landsat-8-c2-l2"
time_range = (DateTime(2018,01,01), DateTime(2018,01,02)) # start and end time
lon_range = (2.51357303225, 6.15665815596)  # west, east
lat_range = (49.5294835476, 51.4750237087)  # south, north

catalog = STAC.Catalog("https://planetarycomputer.microsoft.com/api/stac/v1")

search_results = collect(search(catalog, collections, lon_range, lat_range, time_range))
```


### NASA EarthData

Retrieve a list of OPeNDAP URLs from the NASA [Common Metadata Repository (CMR)](https://www.earthdata.nasa.gov/eosdis/science-system-description/eosdis-components/cmr) of the collection [C1996881146-POCLOUD](https://cmr.earthdata.nasa.gov/search/concepts/C1996881146-POCLOUD.html). A token is obtained from [https://urs.earthdata.nasa.gov/home](https://urs.earthdata.nasa.gov/home) (after registration and login) and clicking on `Generate Token`:


```julia
using STAC, URIs, Dates

token = "put_your_user_token_here"
timerange = (DateTime(2019,1,1),DateTime(2019,12,31))
collection_concept_id = "C1996881146-POCLOUD"
baseurl = "https://cmr.earthdata.nasa.gov/search/granules.stac"

url = string(URI(URI(baseurl), query = Dict(
    "collection_concept_id" => collection_concept_id,
    "temporal" => join(string.(timerange),','),
    "pageSize" => 1000, # default is 100
    "token" => token)))

collection = STAC.FeatureCollection(url)
opendap_url = [href(item.assets["opendap"]) for item in collection]

@show length(opendap_url)
# output 365, one URL per day
```

To load the dataset, the NetCDF library need to be made aware of your EarthData username and password as explained [here](https://alexander-barth.github.io/NCDatasets.jl/latest/tutorials/#NASA-EarthData). 
