using SAMTools
using Documenter

makedocs(;
    modules=[SAMTools],
    authors="Nathanael Wong <natgeo.wong@outlook.com>",
    repo="https://github.com/natgeo-wong/SAMTools.jl/blob/{commit}{path}#L{line}",
    sitename="SAMTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
