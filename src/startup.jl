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

    sroot = Dict{AbstractString,AbstractString}()

    sroot["tmp"] = tmppath; sroot["root"] = prjpath;
    sroot["raw"] = joinpath(prjpath,"raw",experiment,config)
    sroot["ana"] = joinpath(prjpath,"ana",experiment,config)
    sroot["experiment"] = experiment; sroot["configuration"] = config;
    sroot["spinup"] = ""; sroot["control"] = ""; sroot["ncname"] = fname;

    @info """$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))
      $(BOLD("Temporary Directory:")) $tmppath
      $(BOLD("Project Directory:")) $prjpath
      $(BOLD("File Prefix:")) $fname
      $(BOLD("Experiment | Configuration:")) $experiment | $config
    """

     "$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))\n  $(BOLD("Temporary Directory:")) $tmppath\n  $(BOLD("Root Directory:")) $prjpath\n  $(BOLD("Experiment:")) $experiment\n  $(BOLD("Configuration:")) $config"
    @info "$(Dates.now()) - SAM RAW DATA directory: $(sroot["raw"])."
    @info "$(Dates.now()) - SAM ANALYSIS directory: $(sroot["ana"])."

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

function samstartup(;
    tmppath::AbstractString,
    prjpath::AbstractString,
    experiment::AbstractString="",
    config::AbstractString,
    welcome::Bool=true
)

    if welcome; samwelcome() end
    sroot = samroot(;
        tmppath=tmppath,prjpath=prjpath,
        experiment=experiment,config=config
    )

    init,fnc = retrievename(tmppath);

    ds = Dataset(fnc[1]);
    init["x"] = ds["x"][:]*1; init["y"] = ds["y"][:]*1;
    init["z"] = ds["z"][:]*1; init["p"] = ds["p"][:]*100;
    close(ds);

    return init,sroot

end

function retrievename(tmppath::AbstractString)

    init  = Dict{AbstractString,Any}()
    fnc   = glob(tmppath,"*.nc"); nfid = length(fnc); init["ntime"] = nfid
    fname = splitext(fnc[1]);
    init["fstep"] = parse(Int,split(fname,"_")[end]);
    init["fname"] = replace(fname,"_$(init["fstep"])"=>"")
    init["zeros"] = length(init["fstep"])

    return init,fnc

end
