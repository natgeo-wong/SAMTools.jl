"""
This file initializes the SAMTools module by defining the directories relevant to the particular SAM experiment being resorted and analysed by SAMTools.
"""

function samspin(sroot::AbstractDict)

    efol = joinpath(sroot["root"],"raw",sroot["experiment"]);
    sfol = joinpath(sroot["root"],"raw",sroot["experiment"],"spinup");
    if isdir(sfol)
        @info "$(Dates.now()) - A spinup configuration folder has been identified in $(efol)."
        return true;
    else
        @info "$(Dates.now()) - No spinup configuration folder was identified in $(efol)."
        return false;
    end

end

function samwelcome()

    ftext = joinpath(@__DIR__,"../extra/welcome.txt");
    lines = readlines(ftext); count = 0; nl = length(lines);
    for l in lines; count += 1;
       if any(count .== [1,2]); print(Crayon(bold=true),"$l\n");
       elseif count == nl;      print(Crayon(bold=false),"$l\n\n");
       else;                    print(Crayon(bold=false),"$l\n");
       end
    end

end

function samroot(;
    tmppath::AbstractString,
    prjpath::AbstractString,
    experiment::AbstractString="",
    config::AbstractString,
    fname::AbstractString
)

    sroot = Dict{AbstractString,Any}()

    sroot["tmp"] = tmppath; sroot["root"] = prjpath;
    sroot["raw"] = joinpath(prjpath,"raw",experiment,config)
    sroot["ana"] = joinpath(prjpath,"ana",experiment,config)
    sroot["experiment"] = experiment; sroot["configuration"] = config;
    sroot["spinup"] = ""; sroot["control"] = ""; sroot["ncname"] = fname;

    @info """$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))
      $(BOLD("Temporary Directory:")) $tmppath
      $(BOLD("Project Directory:")) $prjpath
      $(BOLD("Raw Data Directory:")) $(sroot["raw"])
      $(BOLD("Analysis Directory:")) $(sroot["ana"])
      $(BOLD("File Prefix:")) $fname
      $(BOLD("Experiment | Configuration:")) $experiment | $config
    """

    if samspin(sroot)
        sroot["spinup"]  = replace(sroot["raw"],config=>"spinup")
        sroot["control"] = replace(sroot["raw"],config=>"control")
        @info """$(Dates.now()) - $(BOLD("SPINUP DIRECTORIES:"))
          $(BOLD("Spinup Directory:"))  $(sroot["spinup"])
          $(BOLD("Control Directory:")) $(sroot["control"])
        """
    end

    return sroot

end

function retrievename(fname::AbstractString,tmppath::AbstractString)

    @info "$(Dates.now()) - Retrieving list of 2D and 3D NetCDF output files ..."

    init = Dict{AbstractString,Any}()
    f3D  = glob("$(fname)*.nc",joinpath(tmppath,"OUT_3D"));
    f2D  = glob("$(fname)*.nc",joinpath(tmppath,"OUT_2D"));
    nf2D = length(f2D); init["n2Dtime"] = nf2D
    nf3D = length(f3D); init["n3Dtime"] = nf3D

    return init,f3D,f2D

end

function retrievedims!(
    init::AbstractDict,
    f3D::Vector{<:AbstractString}
)

    @info "$(Dates.now()) - Retrieving X,Y,Z-dimensions of data output ..."

    ds = Dataset(f3D[end]);
    init["x"] = ds["x"][:]; init["y"] = ds["y"][:]; init["z"] = ds["z"][:];
    init["size"] = [length(init["x"]),length(init["y"]),length(init["z"])]
    close(ds);

    return

end

function retrievetime!(
    init::AbstractDict,
    f3D::Vector{<:AbstractString}, f2D::Vector{<:AbstractString}
)

    @info "$(Dates.now()) - Retrieving details on time start, step and end for 2D and 3D outputs ..."

    ds = Dataset(f2D[1]);
    t2D = ds["time"][:]; t2D1 = t2D[1]; t2D2 = t2D[2]; nt = length(t2D);
    close(ds);

    ds = Dataset(f2D[end]);
    t2De = ds["time"]; nte = length(t2De); t2De = t2De[end]
    close(ds);

    ds = Dataset(f3D[1]);   t3D1 = ds["time"][1]; close(ds);
    ds = Dataset(f3D[end]); t3De = ds["time"][1]; close(ds);

    nt2D = nt * (length(f2D) - 1) + nte
    nt3D = length(f3D)

    init["tstep2D"] = (t2De - t2D1) / (nt2D - 1)
    init["tstep3D"] = (t3De - t3D1) / (nt3D - 1)
    init["tbegin"]  = t2De - init["tstep2D"] * nt2D
    init["t2D"] = init["tbegin"] .+ collect(1:nt2D) * init["tstep2D"]
    init["t3D"] = init["tbegin"] .+ collect(1:nt3D) * init["tstep3D"]

    return

end

function extractpressure!(
    init::AbstractDict,
    f3D::Vector{<:AbstractString},
    sroot::AbstractDict
)

    @info "$(Dates.now()) - Retrieving details on pressure coordinates over the course of the experiment ..."

    nz = init["size"][3]; nf3D = length(f3D); n3Drun = floor(Int64,nf3D/360)+1;
    p = zeros(nz,360*n3Drun)
    for inc in 1 : nf3D; ds = Dataset(f3D[inc]); p[:,inc] = ds["p"][:]; close(ds) end
    p = reshape(p,nz,360,n3Drun)*100; scale,offset = samncoffsetscale(p);

    if !isdir(sroot["raw"]); mkpath(sroot["raw"]); end
    if !isdir(sroot["ana"]); mkpath(sroot["ana"]); end

    @info "$(Dates.now()) - Saving pressure coordinate information ..."

    fp = joinpath(sroot["raw"],"p.nc"); ds = Dataset(fp,"c")
    ds.dim["z"] = nz; ds.dim["t"] = 360; ds.dim["nruns"] = n3Drun
    ncp = defVar(ds,"p",Float32,("z","t","nruns"),attrib = Dict(
        "units"         => "Pa",
        "long_name"     => "Pressure",
    ))
    ncp[:] = p
    close(ds)

    fp = joinpath(sroot["ana"],"p.nc"); ds = Dataset(fp,"c")
    ds.dim["z"] = nz; ds.dim["t"] = 360; ds.dim["nruns"] = n3Drun
    ncp = defVar(ds,"p",Float32,("z","t","nruns"),attrib = Dict(
        "units"         => "Pa",
        "long_name"     => "Pressure",
    ))
    ncp[:] = p
    close(ds)

    return

end

function samstartup(;
    tmppath::AbstractString,
    prjpath::AbstractString,
    experiment::AbstractString="",
    config::AbstractString,
    fname::AbstractString,
    welcome::Bool=true
)

    if welcome; samwelcome() end
    sroot = samroot(;
        tmppath=tmppath,prjpath=prjpath,
        experiment=experiment,config=config,
        fname=fname
    )

    init,f3D,f2D = retrievename(fname,tmppath);
    sroot["flist3D"] = f3D; sroot["flist2D"] = f2D;
    retrievedims!(init,f3D); retrievetime!(init,f3D,f2D)
    extractpressure!(init,f3D,sroot)

    return init,sroot

end
