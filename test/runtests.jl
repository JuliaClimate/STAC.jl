using STAC
using Test


function testshow(s,substr)
    io = IOBuffer()
    show(io,s)
    @test occursin(substr,String(take!(io)))
end

@testset "STAC.jl" begin

    url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"

    cat = STAC.Catalog(url)
    @show id(cat)
    @show type(cat)
    @show stac_version(cat)
    @show stac_extensions(cat)
    @show title(cat)
    @show description(cat)
    @show keywords(cat)
    @show license(cat)
    @show providers(cat)
    @show extent(cat)
    @test summaries(cat, default = "foobar") == "foobar"

    @test length(keys(cat)) > 0
    @show keys(cat)

    subcat = cat["stac-catalog-eo"]
    @show subcat
    @show keys(subcat)

    subcat1 = subcat["landsat-8-l1"]


    @show subcat1


    item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]

    testshow(item,"box")

    bbox(item)
    geometry(item)
    links(item)
    properties(item)

    assetB4 = item.assets["B4"]
    @show href(assetB4)

    testshow(assetB4,"type")


    STAC.set_cache_max_size(10000)

    for c in eachcatalog(cat)
        @show id(c)
    end

    for item in eachitem(cat)
        @show id(item)
        @test length(bbox(item)) == 4
    end

    STAC.set_title_color(:light_red)
    @test STAC.title_color[] == :light_red

    STAC.set_catalog_color(:green)
    @test STAC.catalog_color[] == :green

    STAC.set_item_color(:cyan)
    @test STAC.item_color[] == :cyan

    STAC.empty_cache()
    @test length(STAC.CACHE) == 0
end
