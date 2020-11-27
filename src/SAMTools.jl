module SAMTools

## Modules Used
using CFTime
using Crayons, Crayons.Box
using Dates
using DelimitedFiles
using Dierckx
using Glob
using JLD2
using NCDatasets
using NumericalIntegration
using Printf
using Statistics

## Exporting the following functions:
export
        samwelcome, samstartup, saminitialize, samresort, samanalysis, samroot,
        samparametercopy, samparameterload, samparameteradd,
        samrawfolder, samrawname, samrawread,
        sampre2lvl, samvert2lvl,
        sndinit, sndprint, samstat2snd,
        lsfinit, lsfprint,
        sfcradbal, sfcradbalname
        #toaradbal, toaradbalname

## Including other files in the module
include("startup.jl")
include("initialize.jl")
include("resort.jl")
include("frontend.jl")
include("backend.jl")

include("casesetup/snd.jl")
include("casesetup/lsf.jl")

include("analysis/surfacefluxbalance.jl")
# include("analysis/topofatmosbalance.jl")

end
