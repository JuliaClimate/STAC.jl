```@meta
CurrentModule = STAC
```

# STAC

Documentation for [STAC](https://github.com/JuliaClimate/STAC.jl), a Julia client implementation of the [SpatioTemporal Asset Catalogs](https://stacspec.org/).


## STAC catalog

```@docs
STAC.Catalog
keys(cat::Catalog)
getindex(cat::Catalog,child_id::AbstractString)
eachcatalog(catalog::Catalog)
eachitem(catalog::Catalog)
STAC.search
type(cat::Catalog)
stac_version(cat::Catalog)
stac_extensions(cat::Catalog)
id(cat::Catalog)
title(cat::Catalog)
description(cat::Catalog)
keywords(cat::Catalog)
license(cat::Catalog)
providers(cat::Catalog)
extent(cat::Catalog)
summaries(cat::Catalog)
```

## STAC item

```@docs
id(item::Item)
bbox(item::Item)
links(item::Item)
properties(item::Item)
DateTime(item::Item)
geometry(item::Item)
```

## STAC asset

```@docs
href(asset::Asset)
title(asset::Asset)
description(asset::Asset)
type(asset::Asset)
```

## Cache

```@docs
STAC.set_cache_max_size
STAC.empty_cache()
```

## Customize

The color scheme used of the STAC client can be customized by the following functions:

```@docs
STAC.set_catalog_color
STAC.set_asset_color
STAC.set_item_color
STAC.set_title_color
```
