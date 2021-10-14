using STAC
using Documenter

DocMeta.setdocmeta!(STAC, :DocTestSetup, :(using STAC); recursive=true)

makedocs(;
    modules=[STAC],
    authors="Alexander Barth <barth.alexander@gmail.com> and contributors",
    repo="https://github.com/JuliaClimate/STAC.jl/blob/{commit}{path}#{line}",
    sitename="STAC.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaClimate.github.io/STAC.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaClimate/STAC.jl",
    devbranch="main",
)
