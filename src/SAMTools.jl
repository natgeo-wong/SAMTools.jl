module SAMTools

## Modules Used
using CFTime
using Crayons, Crayons.Box
using Dates
using DelimitedFiles
using Glob
using JLD2
using NCDatasets
using NumericalIntegration
using Printf
using Statistics

## Exporting the following functions:
export
        samwelcome, samstartup, samresort, samanalysis,
        samparametercopy, samparameterload, samparameteradd,
        sampre2lvl, samvert2lvl

## Including other files in the module
include("startup.jl")
include("initialize.jl")
include("resort.jl")
include("analysis.jl")

include("frontend.jl")
include("backend.jl")

end