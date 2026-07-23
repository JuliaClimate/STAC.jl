using STAC
using Test
using Dates

function testshow(s,substr)
    io = IOBuffer()
    show(io,s)
    @test occursin(substr,String(take!(io)))
end

function testshow(mime::Type{<:MIME},s,substr)
    io = IOBuffer()
    show(io,mime(),s)
    @test occursin(substr,String(take!(io)))
end

@testset "STAC.jl" begin

    url = "https://raw.githubusercontent.com/sat-utils/sat-stac/master/test/catalog/catalog.json"

    cat = STAC.Catalog(url)

    testshow(MIME"text/plain",cat,"STAC")

    @test id(cat) == "stac-catalog"
    @test occursin("1.",stac_version(cat))
    @test stac_extensions(cat) == nothing
    @test title(cat) == nothing
    @test description(cat) == "An example STAC catalog"
    @test keywords(cat) == nothing
    @test license(cat) == nothing
    @test providers(cat) == nothing
    @test extent(cat) == nothing
    @test summaries(cat, default = "foobar") == "foobar"

    @test length(keys(cat)) > 0
    @test keys(cat) == ["stac-catalog-eo"]

    subcat = cat["stac-catalog-eo"]
    @test subcat isa STAC.Catalog
    @test keys(subcat) isa AbstractVector{<:String}

    subcat1 = subcat["landsat-8-l1"]

    @test subcat1 isa STAC.Catalog
    testshow(MIME"text/plain",subcat1,"Items")
    subitems = subcat1.items
    testshow(subitems, "Parent Catalog")

    item = subcat1.items["LC08_L1TP_152038_20200611_20200611_01_RT"]
    itemint = subcat1.items[1]
    @test item == itemint
    @test_throws BoundsError subcat1.items[2]
    testshow(MIME"text/plain",item,"box")
    testshow(item, "LC08_L1TP_152038_20200611_20200611_01_RT")
    testshow(MIME"text/plain",item, "date time:")

    @test DateTime(item) == DateTime("2020-06-11T05:54:44.65")
    @test STAC.datetime(item, :datetime) == DateTime("2020-06-11T05:54:44.65")
    @test STAC.datetime(item, :start_datetime) === nothing
    
    @test STAC.parse_datetime("2026-07-31T11:50:12.123Z") == DateTime("2026-07-31T11:50:12.123")
    @test STAC.parse_datetime("2026-07-31T11:50:12.123") == DateTime("2026-07-31T11:50:12.123")
    @test STAC.parse_datetime("2026-07-31T11:50:12") == DateTime("2026-07-31T11:50:12")
    @test STAC.parse_datetime("2026-07-31T11:50:12Z") == DateTime("2026-07-31T11:50:12")
    @test STAC.parse_datetime("2026-07-31T11:50") == DateTime("2026-07-31T11:50")
    @test STAC.parse_datetime("2026-07-31") == DateTime("2026-07-31")
    @test STAC.parse_datetime("foo") === nothing

    @test geometry(item) isa STAC.GeoJSON.Polygon
    @test bbox(item) isa AbstractVector
    @test links(item) isa AbstractVector
    @test properties(item) isa AbstractDict

    assetB4 = item.assets["B4"]
    @test href(assetB4) isa AbstractString

    assetB4 = item["B4"]
    @test href(assetB4) isa AbstractString

    @test keys(item) == keys(item.assets)
    @test values(item) == values(item.assets)

    # plain text show methods
    testshow(MIME"text/plain", assetB4, "type")
    testshow(MIME"text/plain", cat, "STAC")

    # compact show methods
    testshow(assetB4, "Band 4")  # compact Asset show prints title
    testshow(cat, "stac-catalog")  # compact Catalog show prints id

    STAC.set_cache_max_size(10000)

    @test length(collect(eachcatalog(cat))) > 0

    @test length(collect(eachitem(cat))) > 0

    #=
    for item in eachitem(cat)
        @show id(item)
        @test length(bbox(item)) == 4
    end
    =#

    STAC.set_title_color(:light_red)
    @test STAC.title_color[] == :light_red

    STAC.set_catalog_color(:green)
    @test STAC.catalog_color[] == :green

    STAC.set_item_color(:cyan)
    @test STAC.item_color[] == :cyan

    STAC.empty_cache()
    @test length(STAC.CACHE) == 0
end


# broken
# @testset "Malformed URL" begin
#     @test_throws ArgumentError STAC.Catalog("https://geoservice.dlr.de/eoc/ogc/stac/v1/collections/TDM_FNF_50")
#     @test_throws ArgumentError STAC.Catalog("https://stac.core.eopf.eodc.eu/collections")
# end


@testset "search" begin
    collections = ["landsat-8-c2-l2"]
    time_range = (DateTime(2018,01,01), DateTime(2018,01,02))
    lon_range = (2.51357303225, 6.15665815596)
    lat_range = (49.5294835476, 51.4750237087)
    cat = STAC.Catalog("https://planetarycomputer.microsoft.com/api/stac/v1")

    search_results = collect(search(cat, collections, lon_range, lat_range, time_range))
    @test length(search_results) == 2


    search_results = collect(search(cat, collections[1], lon_range, lat_range, time_range))
    @test length(search_results) == 2

    # test STACQL

    query = Dict("eo:cloud_cover" =>  Dict("lt" => 61))
    search_results = collect(
        search(cat, collections,
               lon_range, lat_range, time_range,
               query = query,
               ))
    @test length(search_results) == 1

    # test CQL2

    filter = Dict(
        "op" => "<=",
        "args" => [Dict( "property" => "eo:cloud_cover" ), 61]
    )

    search_results = collect(
        search(cat, collections,
               lon_range, lat_range, time_range,
               filter = filter,
               )
    )
    @test length(search_results) == 1


    filter = Dict(
        "op" => "and",
        "args" => [
            Dict(
                "op" => "<=",
                "args" => [Dict("property" => "eo:cloud_cover"), 61]
            ),
            Dict(
                "op" => "=",
                "args" => [Dict("property" => "platform"), "landsat-8"]
            ),
        ]
    )

    search_results = collect(
        search(cat, collections,
               lon_range, lat_range, time_range,
               filter = filter,
               )
    )
    @test length(search_results) == 1
end

@testset "providers" begin
    include("test_earth_data.jl")
    include("test_cdse.jl")
end
