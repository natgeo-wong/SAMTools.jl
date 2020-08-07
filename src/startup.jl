"""
This file initializes the SAMTools module by defining the directories relevant to the particular SAM experiment being resorted and analysed by SAMTools.
"""

function samspin(sroot::AbstractDict)

    efol = joinpath(sroot["root"],sroot["experiment"]);
    sfol = joinpath(sroot["root"],sroot["experiment"],"spinup");
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

    sroot = Dict{AbstractString,Any}(); sroot["root"] = prjpath;

    sroot["tmp"] = tmppath
    sroot["raw"] = joinpath(prjpath,experiment,config,"RAW")
    sroot["ana"] = joinpath(prjpath,experiment,config,"ANA")
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
    fst  = glob("$(fname)*.nc",joinpath(tmppath,"OUT_STAT"));

    if f2D != []; if occursin("001.",f2D[1]); f2D = f2D[2:end] end; end
    if f3D != []; if occursin("001.",f3D[1]); f3D = f3D[2:end] end; end

    nf2D = length(f2D); init["n2Dtime"] = nf2D
    nf3D = length(f3D); init["n3Dtime"] = nf3D
    nfst = length(fst); init["nstatnc"] = nf3D

    return init,f3D,f2D,fst

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
    f3D::Vector{<:AbstractString},
    f2D::Vector{<:AbstractString},
    fst::Vector{<:AbstractString},
    it::Integer
)

    @info "$(Dates.now()) - Retrieving details on time start, step and end for 2D and 3D outputs ..."

    ds = Dataset(fst[1]);   tst1 = ds["time"][1];   nt1 = ds.dim["time"]; close(ds);
    ds = Dataset(fst[end]); tste = ds["time"][end]; nte = ds.dim["time"]; close(ds);
    ntst = nt1 * (length(fst) - 1) + nte

    init["day0"] = tste - (tste-tst1)/(ntst-1) * ntst
    init["dayh"] = mod(init["day0"],1)

    ds = Dataset(f2D[1]);
    t2D = ds["time"]; nt = ds.dim["time"]; t2D1 = t2D[1];
    if nt == 1
          ds2 = Dataset(f2D[2]); t2D2 = ds2["time"][1]; close(ds2);
    else; t2D2 = t2D[2]
    end
    close(ds);

    ds = Dataset(f2D[end]);
    t2De = ds["time"]; t2De = t2De[end]; nte = ds.dim["time"];
    close(ds);

    ds = Dataset(f3D[1]);   t3D1 = ds["time"][1]; close(ds);
    ds = Dataset(f3D[end]); t3De = ds["time"][1]; close(ds);

    sep = (t2D2 + init["day0"]) - 2 * t2D1

    # if nt = 1, then f2D by extension does not include the 00000001.bin_1.nc file and
    # therefore t2D2 - t2D1 should be equal to t2D1 - tbegin, so sep = 0 and no change to
    # nt2D
    #
    # if nt > 1, then if sep < 0, then must subtract nt2D by 1.  But if sep = 0, then
    # everything remains as is.  If sep > 0, then we must consider another case ...

    nt2D = nt * (length(f2D) - 1) + nte
    nt3D = length(f3D)

    if sep < 0; t2D1 = t2D2; nt2D = nt2D - 1; init["is01t"] = 1
    else; init["is01t"] = 0
    end

    init["tstep2D"] = (t2De - t2D1) / (nt2D - 1)
    init["tstep3D"] = (t3De - t3D1) / (nt3D - 1)
    init["tstepst"] = (tste - tst1) / (ntst - 1)

    init["t2D"] = t2D1 .+ collect(0:(nt2D-1)) * init["tstep2D"]
    init["t3D"] = t3D1 .+ collect(0:(nt3D-1)) * init["tstep3D"]
    init["nt2D"] = nt; init["it"] = it;

    if nt == 1; init["2Dsep"] = true; else; init["2Dsep"] = false end

    return

end

function extractpressure!(
    init::AbstractDict,
    f3D::Vector{<:AbstractString},
    sroot::AbstractDict
)

    @info "$(Dates.now()) - Retrieving details on pressure coordinates over the course of the experiment ..."

    nz = init["size"][3]; nf3D = length(f3D);
    n3Drun = floor(Int64,nf3D/init["it"]); if rem(nf3D,init["it"]) != 0; n3Drun += 1 end
    p = zeros(nz,init["it"]*n3Drun)
    for inc in 1 : nf3D; ds = Dataset(f3D[inc]); p[:,inc] = ds["p"][:]; close(ds) end
    p = reshape(p,nz,init["it"],n3Drun)*100; scale,offset = samncoffsetscale(p);

    if !isdir(sroot["raw"]); mkpath(sroot["raw"]); end
    if !isdir(sroot["ana"]); mkpath(sroot["ana"]); end

    @info "$(Dates.now()) - Saving pressure coordinate information ..."

    fp = joinpath(sroot["raw"],"p.nc"); ds = Dataset(fp,"c")
    ds.dim["z"] = nz; ds.dim["t"] = init["it"]; ds.dim["nruns"] = n3Drun
    ncp = defVar(ds,"p",Float32,("z","t","nruns"),attrib = Dict(
        "units"         => "Pa",
        "long_name"     => "Pressure",
    ))
    ncp[:] = p
    close(ds)

    fp = joinpath(sroot["ana"],"p.nc"); ds = Dataset(fp,"c")
    ds.dim["z"] = nz; ds.dim["t"] = init["it"]; ds.dim["nruns"] = n3Drun
    ncp = defVar(ds,"p",Float32,("z","t","nruns"),attrib = Dict(
        "units"         => "Pa",
        "long_name"     => "Pressure",
    ))
    ncp[:] = p
    close(ds)

    return

end

function samstartup(;
    tmppath::AbstractString="",
    prjpath::AbstractString,
    experiment::AbstractString="",
    config::AbstractString,
    fname::AbstractString,
    welcome::Bool=true,
    loadinit=true,
    it::Integer=1000
)

    if welcome; samwelcome() end
    if tmppath == ""; tmppath = joinpath(prjpath,experiment,config); end

    sroot = samroot(;
        tmppath=tmppath,prjpath=prjpath,
        experiment=experiment,config=config,
        fname=fname
    )


    if loadinit && isfile("$(sroot["raw"])/init.jld2")
        @load "$(sroot["raw"])/init.jld2" init
        _,f3D,f2D,fst = retrievename(fname,tmppath);
        sroot["flist3D"] = f3D; sroot["flist2D"] = f2D; sroot["flistst"] = fst
    else
        if isdir(tmppath)
            init,f3D,f2D,fst = retrievename(fname,tmppath);
            sroot["flist3D"] = f3D; sroot["flist2D"] = f2D; sroot["flistst"] = fst
            retrievedims!(init,f3D); retrievetime!(init,f3D,f2D,fst,it)
            extractpressure!(init,f3D,sroot)
            @save "$(sroot["raw"])/init.jld2" init
        else
            error("$(Dates.now()) - Unable to retrieve information required for initialization.  Please ensure you have specified the correct project directories, or compiled the information from the temporary SAM data storage folder.")
        end
    end


    return init,sroot

end
