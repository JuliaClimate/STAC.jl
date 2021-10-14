using STACatalogs
using Test

@testset "STACatalogs.jl" begin

    url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"

    cat = STACatalog(url)
    @show id(cat)

    @test length(keys(cat)) > 0
    @show keys(cat)

    subcat = cat["stac-catalog-eo"]
    @show subcat
    @show keys(subcat)

    subcat1 = subcat["landsat-8-l1"]
    io = IOBuffer()
    show(io,subcat)
    @test occursin("cat",String(take!(io)))

    @show subcat1

    item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
    @show item.assets[:B4][:href]

    for c in eachcatalog(cat)
        @show id(c)
    end

    for item in eachitem(cat)
        @show id(item)
        @test length(bbox(item)) == 4
    end
end
