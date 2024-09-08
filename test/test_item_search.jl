using STAC
using URIs
using Test
using STAC: CONFORMANCE, conforms, match
using JSON3

c = "https://api.stacspec.org/v1.0.0/item-search"

class = CONFORMANCE.item_search

catalog = STAC.Catalog("https://stac.geobon.org/")




entry = catalog["chelsa-clim"]


@test match(CONFORMANCE.item_search, "https://api.stacspec.org/v1.0.0/item-search")
@test !match(CONFORMANCE.item_search, "http://www.opengis.net/spec/ogcapi-features-1/1.0/conf/core")
@test match(CONFORMANCE.context,"https://api.stacspec.org/v1.0.0-rc.2/item-search#context")


@test conforms(catalog,CONFORMANCE.item_search)



#link(entry::STAC.Catalog)

rel = "items"
type = nothing

data = Dict(
    :rel  => "items",
    :type => "application/geo+json",
    :href => "https://stac.geobon.org/collections/chelsa-clim/items",
)

@test STAC.Link(data).type == MIME("application/geo+json")

links(entry)

l0 = STAC.firstlink(entry; rel = :items)

url = l0.href
query = Dict()

items = STAC.FeatureCollection(url,query)

itemsc = collect(items)

#STAC.links(entry)


catalog = STAC.Catalog("https://stac.geobon.org/")
entry = catalog["chelsa-clim"]

entry.items["bio1"]

#kk = collect(keys(catalog.children))

#catalog.children[kk[1]]

#display(catalog.children)
