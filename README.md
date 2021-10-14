# STAC

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Alexander-Barth.github.io/STAC.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Alexander-Barth.github.io/STAC.jl/dev)
[![Build Status](https://github.com/Alexander-Barth/STAC.jl/workflows/CI/badge.svg)](https://github.com/Alexander-Barth/STAC.jl/actions)
[![Coverage](https://codecov.io/gh/Alexander-Barth/STAC.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Alexander-Barth/STAC.jl)


This package is an experimental implementation of the SpatioTemporal Asset Catalogs (STAC) client in Julia.

Opening an issue to notify about a missing feature is not helpful for the momement. However, if somebody is interested to make a pull request to implement a missing feature, an issue is a good way to discuss its implementation.


## Example

``` julia
using STAC
url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"
cat = STAC.Catalog(url)
subcat = cat["stac-catalog-eo"]
subcat1 = subcat["landsat-8-l1"]
@show subcat1

item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
@show href(item.assets["B4"])
```
