module SAMTools

## Modules Used
using CFTime
using Crayons, Crayons.Box
using Dates
using DelimitedFiles
using Glob
using JLD2
using NCDatasets
using Printf
using Statistics

## Exporting the following functions:
export
        templaterun, templateexp, templatehpc, overwritetemplate,
        sammakefile, sammodules, samscratch


function __init__()
    samfol = joinpath(DEPOT_PATH[1],"files","SAMTools")
    if !isdir(samfol); mkpath(samfol) end
    overwritetemplate()
end

## Including other files in the module
include("setup.jl")

# include("analysis/topofatmosbalance.jl")

end
