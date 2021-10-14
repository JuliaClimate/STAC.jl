using STACatalogs
using Documenter

DocMeta.setdocmeta!(STACatalogs, :DocTestSetup, :(using STACatalogs); recursive=true)

makedocs(;
    modules=[STACatalogs],
    authors="Alexander Barth <barth.alexander@gmail.com> and contributors",
    repo="https://github.com/Alexander-Barth/STACatalogs.jl/blob/{commit}{path}#{line}",
    sitename="STACatalogs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Alexander-Barth.github.io/STACatalogs.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Alexander-Barth/STACatalogs.jl",
    devbranch="main",
)
