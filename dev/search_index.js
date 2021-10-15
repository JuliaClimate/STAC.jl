var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = STAC","category":"page"},{"location":"#STAC","page":"Home","title":"STAC","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for STAC.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [STAC]","category":"page"},{"location":"#Dates.DateTime-Tuple{STAC.Item}","page":"Home","title":"Dates.DateTime","text":"dt = DateTime(item)\n\nGet the date time of STAC item as a Dates.DateTime (or nothing if this properties is not specified).\n\n\n\n\n\n","category":"method"},{"location":"#STAC.Catalog-Tuple{String}","page":"Home","title":"STAC.Catalog","text":"cat = STAC.Catalog(url)\n\nOpen a SpatioTemporal Asset Catalog (STAC) using the provided url. The url should point to a JSON object conforming to the STAC specification.\n\ncat behaves as a julia dictionary with all STAC subcatalogs. cat.items is a dictionary with all STAC items.\n\nusing STAC\nurl = \"https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json\"\ncat = STAC.Catalog(url)\nsubcat = cat[\"stac-catalog-eo\"]\nsubcat1 = subcat[\"landsat-8-l1\"]\n@show subcat1\n\nitem = subcat1.items[\"LC08_L1TP_152038_20200611_20200611_01_RT\"]\n@show href(item.assets[\"B4\"])\n\n\n\n\n\n","category":"method"},{"location":"#STAC.bbox-Tuple{STAC.Item}","page":"Home","title":"STAC.bbox","text":" data = bbox(item)\n\nGet the bounding box of STAC item.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.description-Tuple{STAC.Asset}","page":"Home","title":"STAC.description","text":" data = description(asset)\n\nGet the description of STAC asset.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.description-Tuple{STAC.Catalog}","page":"Home","title":"STAC.description","text":"data = description(cat::Catalog)\n\nGet the description of STAC catalog.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.eachcatalog-Tuple{STAC.Catalog}","page":"Home","title":"STAC.eachcatalog","text":"cats = eachcatalog(catalog::Catalog)\n\nReturns resursively all subcatalogs in catalog. This can take a long time for deeply nested catalogs.\n\nurl = \"https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json\"\n\ncat = STAC.Catalog(url)\nfor c in eachcatalog(cat)\n    @show id(c)\nend\n\n\n\n\n\n","category":"method"},{"location":"#STAC.eachitem-Tuple{STAC.Catalog}","page":"Home","title":"STAC.eachitem","text":"cats = eachitem(catalog::Catalog)\n\nReturns resursively all items in catalog. This can take a long time for deeply nested catalogs.\n\nurl = \"https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json\"\n\ncat = STAC.Catalog(url)\nfor c in eachitem(cat)\n    @show id(c)\nend\n\n\n\n\n\n","category":"method"},{"location":"#STAC.geometry-Tuple{STAC.Item}","page":"Home","title":"STAC.geometry","text":"data = geometry(item)\n\nGet the geometry of STAC item as a GeoJSON object\n\n\n\n\n\n","category":"method"},{"location":"#STAC.href-Tuple{STAC.Asset}","page":"Home","title":"STAC.href","text":" data = href(asset)\n\nGet the URI of STAC asset.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.id-Tuple{STAC.Catalog}","page":"Home","title":"STAC.id","text":"data = id(cat::Catalog)\n\nGet the identifier of STAC catalog.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.id-Tuple{STAC.Item}","page":"Home","title":"STAC.id","text":" data = id(item)\n\nGet the identifier of STAC item.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.links-Tuple{STAC.Item}","page":"Home","title":"STAC.links","text":" data = links(item)\n\nGet the links of STAC item.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.properties-Tuple{STAC.Item}","page":"Home","title":"STAC.properties","text":" data = properties(item)\n\nGet the properties of STAC item.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.set_cache_max_size-Tuple{Integer}","page":"Home","title":"STAC.set_cache_max_size","text":"STAC.set_cache_max_size(cache_max_size::Integer)\n\nSet the maximum number of URLs saved in cache (permanentaly). The default is 1000. The Julia session need to be restated for this change to take effect.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.title-Tuple{STAC.Asset}","page":"Home","title":"STAC.title","text":" data = title(asset)\n\nGet the title of STAC asset.\n\n\n\n\n\n","category":"method"},{"location":"#STAC.type-Tuple{STAC.Asset}","page":"Home","title":"STAC.type","text":" data = type(asset)\n\nGet the type of STAC asset.\n\n\n\n\n\n","category":"method"}]
}