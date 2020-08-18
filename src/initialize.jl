"""
This file initializes the samTools module by setting and determining the
ECMWF reanalysis parameters to be analyzed and the regions upon which the data
are to be extracted from.  Functionalities include:
    - Setting up of reanalysis module type
    - Setting up of reanalysis parameters to be analyzed
    - Setting up of time steps upon which data are to be downloaded
    - Setting up of region of analysis based on ClimateEasy

"""

# samTools Parameter Setup

function samparametercopy(;overwrite::Bool=false)

    jfol = joinpath(DEPOT_PATH[1],"files/SAMTools/"); mkpath(jfol);
    ftem = joinpath(@__DIR__,"../extra/partemplate.txt")
    fpar = joinpath(jfol,"samparameters.txt")

    if !overwrite
        if !isfile(fpar)
            @debug "$(Dates.now()) - Unable to find samparameters.txt, copying data from partemplate.txt ..."
            cp(ftem,fpar,force=true);
        end
    else
        @warn "$(Dates.now()) - Overwriting samparameters.txt in $jfol ..."
        cp(ftem,fpar,force=true);
    end

    return fpar

end

function samparameterload()

    @debug "$(Dates.now()) - Loading information on the output parameters from SAM."
    return readdlm(samparametercopy(),',',comments=true);

end

function samparameterload(init::AbstractDict)

    @debug "$(Dates.now()) - Loading information on the output parameters from SAM."
    allparams = readdlm(samparametercopy(),',',comments=true);

    @debug "$(Dates.now()) - Filtering out for parameters in the $(init["modulename"]) module."
    parmods = allparams[:,1]; return allparams[(parmods.==init["moduletype"]),:];

end

function samparameterdisp(parlist::AbstractArray,init::AbstractDict)
    @info "$(Dates.now()) - The following variables are offered in the $(init["modulename"]) module:"
    for ii = 1 : size(parlist,1); @info "$(Dates.now()) - $(ii)) $(parlist[ii,3])" end
end

function samparameteradd(fadd::AbstractString)

    if !isfile(fadd); error("$(Dates.now()) - The file $(fadd) does not exist."); end
    ainfo = readdlm(fadd,',',comments=true); aparID = ainfo[:,2]; nadd = length(aparID);

    for iadd = 1 : nadd
        samparameteradd(
            modID=ainfo[iadd,1],parID=ainfo[iadd,2],
            full=ainfo[iadd,3],unit=ainfo[iadd,4],throw=false
        );
    end

end

function samparameteradd(;
    modID::AbstractString, parID::AbstractString,
    full::AbstractString, unit::AbstractString,
    throw::Bool=true
)

    fpar = samparametercopy(); pinfo = samparameterload(); eparID = pinfo[:,2];

    if sum(eparID.==parID) > 0

        if throw
            error("$(Dates.now()) - Parameter ID already exists.  Please choose a new parID.")
        else
            @info "$(Dates.now()) - $(parID) has already been added to samparameters.txt"
        end

    else

        open(fpar,"a") do io
            writedlm(io,[modID ncID full unit],',')
        end

    end

end

# Initialization

function sammodule(moduleID::AbstractString,init::AbstractDict)

    smod = Dict{AbstractString,Any}()
    smod["moduletype"] = moduleID;

    if     moduleID == "d2D"; smod["modulename"] = "dry 2D";
    elseif moduleID == "r2D"; smod["modulename"] = "radiation 2D";
    elseif moduleID == "m2D"; smod["modulename"] = "moist 2D";
    elseif moduleID == "s3D"; smod["modulename"] = "general 3D";
    elseif moduleID == "c2D"; smod["modulename"] = "calc 2D";
    elseif moduleID == "c3D"; smod["modulename"] = "calc 3D";
    end

    if occursin("2D",moduleID)
        @debug "$(Dates.now()) - A 2D module was selected, and therefore we will save '2D' into the parameter level Dictionary."
        smod["levels"] = ["2D"];
    else
        @debug "$(Dates.now()) - A 3D module was selected, and therefore all available vertical levels will be saved into the parameter Dictionary."
        smod["levels"] = init["z"]
    end

    smod["x"] = init["x"]; smod["y"] = init["y"]; smod["z"] = init["z"];
    smod["size"] = init["size"]; smod["2Dsep"] = init["2Dsep"]

    return smod

end

function samparameter(
    parameterID::AbstractString, smod::AbstractDict;
    zheight::Real
)

    parlist = samparameterload(smod); mtype = smod["moduletype"];

    if sum(parlist[:,2] .== parameterID) == 0
        error("$(Dates.now()) - Invalid parameter choice for \"$(uppercase(mtype))\".  Call queryspar(modID=$(mtype),parID=$(parameterID)) for more information.")
    else
        ID = (parlist[:,2] .== parameterID);
    end

    parinfo = parlist[ID,:];
    @info "$(Dates.now()) - SAMTools will analyze $(parinfo[4]) data."

    if occursin("2D",mtype)

        if zheight != 0
            @warn "$(Dates.now()) - You asked to analyze $(uppercase(parinfo[4])) data at a vertical height of $(zheight) m, but this data is a surface module variable.  Setting vertical level to \"SFC\" by default"
        end
        return Dict(
            "ID"=>parinfo[2],"IDnc"=>parinfo[3],
            "name"=>parinfo[4],"unit"=>parinfo[5],
            "level"=>0
        );

    else

        if zheight != 0

            lvl = samvert2lvl(zheight,smod)
            @info "$(Dates.now()) - You have requested $(uppercase(parinfo[4])) data at the vertical height $(zheight) m.  Based on the given vertical levels, this corresponds to z-level $lvl out of $(length(smod["levels"]))."

            return Dict(
                "ID"=>parinfo[2],"IDnc"=>parinfo[3],
                "name"=>parinfo[4],"unit"=>parinfo[5],
                "level"=>lvl
            );

        else

            @warn "$(Dates.now()) - You asked to analyze $(uppercase(parinfo[4])) data, which is found as a 3D module but have not specified a level.  Since SAM is a CRM and is likely run with high resolution, this may cause OUT-OF-MEMORY errors.  Please ensure that enough memory has been allocated."

            return Dict(
                "ID"=>parinfo[2],"IDnc"=>parinfo[3],
                "name"=>parinfo[4],"unit"=>parinfo[5],
                "level"=>"all"
            );

        end

    end

end

function samtime(init)

    stime = deepcopy(init);
    delete!(stime,"x"); delete!(stime,"y"); delete!(stime,"z"); delete!(stime,"size");

    return stime

end

function saminitialize(
    init::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    height::Real=0
)

    smod  = sammodule(modID,init);
    spar  = samparameter(parID,smod,zheight=height);
    stime = samtime(init);

    return smod,spar,stime

end
