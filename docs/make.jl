using SAMTools
using Documenter

makedocs(;
    modules  = [SAMTools],
    doctest  = false,
    format   = Documenter.HTML(
        collapselevel = 1,
        prettyurls    = false
    ),
    authors  = "Nathanael Wong <natgeo.wong@outlook.com>",
    sitename = "SAMTools.jl",
    pages    = [
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/natgeo-wong/SAMTools.jl.git",
)
