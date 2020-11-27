"""
This file contains functions to compute the radiative balance at the surface to see if the model has approached/is approaching equilibrium.  As output, the data is saved in two different forms:
    - 2D (lon,lat) format, taken from 2D output
    - domain-averaged format, taken from STAT output
"""

function sfcradbal(
    config::AbstractString,
    experiment::AbstractString="";
    tmppath::AbstractString="",
    prjpath::AbstractString,
    fname::AbstractString,
    loadinit::Bool=true,
    do2D::Bool=false
)

    if tmppath == ""; tmppath = joinpath(prjpath,experiment,config); end

    init,sroot = samstartup(
        tmppath=tmppath,prjpath=prjpath,fname=fname,
        experiment=experiment,config=config,
        loadinit=loadinit,welcome=false
    )

    sfcradbaldomain(init,sroot)

    if do2D; sfcradbal2D(init,sroot) end

end

function sfcradbaldomain(init::AbstractDict,sroot::AbstractDict)

    _,separ,setime = saminitialize(init,modID="c2D",parID="ebal_sfc");
    ntst = length(setime["tst"]); fst = sroot["flistst"]; nfnc = length(fst)
    sw = zeros(ntst); lw = zeros(ntst); sh = zeros(ntst); lh = zeros(ntst);

    for inc = 1 : nfnc

        @info "$(Dates.now()) - Extracting surface fluxes from OUT_STAT file $inc ..."
        ds = NCDataset(fst[inc])

        beg = (inc-1)*setime["ntst"]+1
        if inc != nfnc; fin = inc*setime["ntst"]
              sw[beg:fin] .= ds["SWNS"][:]; sh[beg:fin] .= ds["SHF"][:]
              lw[beg:fin] .= ds["LWNS"][:]; lh[beg:fin] .= ds["LHF"][:]
        else; sw[beg:end] .= ds["SWNS"][:]; sh[beg:end] .= ds["SHF"][:]
              lw[beg:end] .= ds["LWNS"][:]; lh[beg:end] .= ds["LHF"][:]
        end

        close(ds)

    end

    rb = sw .- (lw .+ sh .+ lh)
    sfcradbalsave(rb,sw,lw,sh,lh,separ,setime,sroot)

end

function sfcradbal2D(init::AbstractDict,sroot::AbstractDict)

    samresort(init,sroot,modID="r2D",parID="hflux_s")
    samresort(init,sroot,modID="r2D",parID="hflux_l")
    samresort(init,sroot,modID="r2D",parID="sw_net_sfc")
    samresort(init,sroot,modID="r2D",parID="lw_net_sfc")

    shmod,shpar,shtime = saminitialize(init,modID="r2D",parID="hflux_s")
    lhmod,lhpar,lhtime = saminitialize(init,modID="r2D",parID="hflux_l")
    swmod,swpar,swtime = saminitialize(init,modID="r2D",parID="sw_net_sfc")
    lwmod,lwpar,lwtime = saminitialize(init,modID="r2D",parID="lw_net_sfc")
    semod,separ,setime = saminitialize(init,modID="c2D",parID="ebal_sfc")

    fol = samrawfolder(shmod,sroot); nfnc = length(glob("*.nc",fol));

    for ifnc = 1 : nfnc

        if inc == nfnc
            nt = length(setime["tst"]); it = mod(nt,setime["it"])
            if it != 0; setime["it"] = it end
        end

        @info "$(Dates.now()) - Calculating 2D surface flux budget for CYCLE $ifnc ..."

        shds,shvar = samrawread(shpar,sroot,irun=ifnc); sh = shvar[:]*1; close(shds)
        lhds,lhvar = samrawread(lhpar,sroot,irun=ifnc); lh = lhvar[:]*1; close(lhds)
        swds,swvar = samrawread(swpar,sroot,irun=ifnc); sw = swvar[:]*1; close(swds)
        lwds,lwvar = samrawread(lwpar,sroot,irun=ifnc); lw = lwvar[:]*1; close(lwds)

        seb = sw .- (lw .+ sh .+ lh)

        sfcradbalsave(seb,ifnc,semod,separ,setime,sroot)

    end

end

function sfcradbalsave(
    radbal::Vector{<:Real},
    sw::Vector{<:Real}, lw::Vector{<:Real}, sh::Vector{<:Real}, lh::Vector{<:Real},
    spar::AbstractDict, stime::AbstractDict, sroot::AbstractDict
)

    @info "$(Dates.now()) - Saving $(uppercase(spar["name"])) domain-averaged data ..."

    fnc = joinpath(sroot["ana"],"sfcflux.nc");
    if isfile(fnc)
        @info "$(Dates.now()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions"  => "CF-1.6",
        "Date Created" => "$(Dates.now())"
    ))

    ds.dim["t"] = length(stime["tst"])

    nct = defVar(ds,"t",Float64,("t",),attrib = Dict(
        "units"     => "days since 0000-00-00 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "no_calendar",
    ))

    ncv = defVar(ds,spar["ID"],Float32,("t",),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => spar["name"],
    ))

    ncsw = defVar(ds,"sw_net_sfc",Float32,("t",),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => "Net Shortwave at Surface",
    ))

    nclw = defVar(ds,"lw_net_sfc",Float32,("t",),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => "Net Longwave at Surface",
    ))

    ncsh = defVar(ds,"hflux_s",Float32,("t",),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => "Sensible Heat Flux",
    ))

    nclh = defVar(ds,"hflux_l",Float32,("t",),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => "Latent Heat Flux",
    ))

    nct[:] = stime["tst"]
    ncv[:] = radbal; ncsw[:] = sw; nclw[:] = lw; ncsh[:] = sh; nclh[:] = lh;

    close(ds)

    @info "$(Dates.now()) - $(uppercase(spar["name"])) domain-averaged data has been saved into the file $fnc ..."

end

function sfcradbalsave(
    radbal::Array{<:Real,3}, inc::Integer,
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    @info "$(Dates.now()) - Saving $(uppercase(spar["name"])) domain-averaged data ..."

    fnc = samrawname(spar,sroot,srun=inc);
    if isfile(fnc)
        @info "$(Dates.now()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions"  => "CF-1.6",
        "Date Created" => "$(Dates.now())"
    ))

    ds.dim["x"] = smod["size"][1];
    ds.dim["y"] = smod["size"][2];
    ds.dim["t"] = stime["it"]

    nct = defVar(ds,"t",Float64,("t",),attrib = Dict(
        "units"     => "days since 0000-00-00 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "no_calendar",
    ))

    ncv = defVar(ds,spar["ID"],Float32,("x","y","t"),attrib = Dict(
        "units"         => spar["unit"],
        "long_name"     => spar["name"],
    ))

    nct[:] = stime["t2D"][(inc-1)*stime["it"] .+ (1:it)]
    ncv[:] = radbal;

    close(ds)

    @info "$(Dates.now()) - $(uppercase(spar["name"])) domain-averaged data has been saved into the file $fnc ..."

end

sfcradbalname(sroot::AbstractDict) = joinpath(sroot["ana"],"sfcflux.nc");
