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

    jfol = joinpath(DEPOT_PATH[1],"files/samTools/"); mkpath(jfol);
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

    imod = Dict{AbstractString,Any}()
    imod["moduletype"] = moduleID;

    if     moduleID == "d2D"; imod["modulename"] = "dry 2D";
    elseif moduleID == "r2D"; imod["modulename"] = "radiation 2D";
    elseif moduleID == "m2D"; imod["modulename"] = "moist 2D";
    elseif moduleID == "s3D"; imod["modulename"] = "general 3D";
    elseif moduleID == "c2D"; imod["modulename"] = "calc 2D";
    elseif moduleID == "c3D"; imod["modulename"] = "calc 3D";
    end

    if occursin("2D",moduleID)
        @debug "$(Dates.now()) - A 2D module was selected, and therefore we will save '2D' into the parameter level Dictionary."
        imod["levels"] = ["2D"];
    else
        @debug "$(Dates.now()) - A pressure module was selected, and therefore all available pressure levels will be saved into the parameter Dictionary."
        imod["levels"] = init["p"]
    end

    imod["z"] = init["z"];

    return imod

end

function samparameter(parameterID::AbstractString,pressure::Real,imod::AbstractDict)

    parlist = samparameterload(imod); mtype = imod["moduletype"];

    if sum(parlist[:,2] .== parameterID) == 0
        error("$(Dates.now()) - Invalid parameter choice for \"$(uppercase(mtype))\".  Call queryipar(modID=$(mtype),parID=$(parameterID)) for more information.")
    else
        ID = (parlist[:,2] .== parameterID);
    end

    parinfo = parlist[ID,:];
    @info "$(Dates.now()) - samTools will analyze $(parinfo[3]) data."

    if occursin("sfc",mtype)

        if pressure != 0
            @warn "$(Dates.now()) - You asked to analyze data at pressure $(pressure) Pa but have chosen a surface module variable.  Setting pressure level to \"SFC\" by default"
        end
        return Dict("ID"=>parinfo[2],"name"=>parinfo[3],"unit"=>parinfo[4],"level"=>"sfc");

    else

        if pressure == 0

            @warn "$(Dates.now()) - You defined a pressure module \"$(uppercase(mtype))\" but you did not specify a pressure.  Setting pressure level to \"ALL\" - this may prevent usage of some samTool functionalities."
            return Dict(
                "ID"=>parinfo[2],"name"=>parinfo[3],
                "unit"=>parinfo[4],"level"=>"all"
            );

        else

            lvl = sampre2lvl(pressure,imod)
            @info "$(Dates.now()) - You have requested $(uppercase(parinfo[3])) data at pressure $(pressure) Pa.  Based on a reference pressure of $(imod["sealp"]) Pa, this corresponds to σ-level $lvl out of $(length(imod["levels"]))."

            return Dict(
                "ID"=>parinfo[2],"name"=>parinfo[3],
                "unit"=>parinfo[4],"level"=>lvl
            );

        end

    end

end

function samtime(init)

    itime = deepcopy(init);
    delete!(itime,"halfs"); delete!(itime,"fulls"); delete!(itime,"sealp");
    delete!(itime,"lon"); delete!(itime,"lat");

    return itime

end

function saminitialize(
    init::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    pressure::Real=0
)

    imod  = sammodule(modID,init);
    ipar  = samparameter(parID,pressure,imod);
    itime = samtime(init);

    return imod,ipar,itime

end
