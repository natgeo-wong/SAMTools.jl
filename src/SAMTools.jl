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
        samroot

## Including other files in the module
include("startup.jl")

end
