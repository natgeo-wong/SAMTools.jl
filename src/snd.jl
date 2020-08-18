"""
This file creates sounding files (snd) for potential temperature (tp), specific humidity (q), u- and v- winds based on the statistical output (OUT_STAT) files from SAM.

Features include:
    - statistical averages over either the WHOLE timeseries, or only the last N days
    - setting horizontal winds to either zero or some specified scalar/profile

Limitations:
    - currently only supports creating snd files in z- coordinates
    - we assume that there is only 1 OUT_STAT file, since data is only in the time (and if applicable, vertical) dimensions
    - you can only manually input 1 sounding each for zonal and meridional winds
    - the only way to specify multiple values of zonal/meridional wind soundings at different levels is to use a sounding file, one each for u- and v- winds
"""

function samstat2snd(
    sroot::AbstractDict,
    ndays::Integer=0
)

    fst = sroot["flistst"]

    ds = Dataset(fst[1]);   tst1 = ds["time"][1];   nt1 = ds.dim["time"]; close(ds);
    ds = Dataset(fst[end]); tste = ds["time"][end]; nte = ds.dim["time"]; close(ds);
    ntst = nt1 * (length(fst) - 1) + nte; tstep = (tste - tst1) / (ntst - 1)
    dystep = round(Int,1/tstep); beg = ndays*dystep-1

    ds = Dataset(fst[1]); nz = ds.dim["z"]; p = mean(ds["Ps"][:,(end-beg):end])
    snddata = zeros(nz,6)
    snddata[:,1] .= ds["z"][:]; snddata[:,2] .= -999.0
    snddata[:,3] .= dropdims(mean(ds["THETA"][:,(end-beg):end],dims=2),dims=2)
    snddata[:,4] .= dropdims(mean(ds["QT"][:,(end-beg):end],dims=2),dims=2)
    close(ds)

    return snddata,p

end

function snduv!(
    snddata::Vector{<:Real}, z::Vector{<:Real},
    snd::Real=0, zlow::Real=0, zhigh::Real=0
)

    if (zlow == 0) && (zhigh == 0); snddata .= usnd
    else

        nz = length(z)
        if zlow  != 0; beg = argmin(abs.(z.-zlow));  else; beg = 1  end
        if zhigh != 0; fin = argmin(abs.(z.-zhigh)); else; fin = nz end
        snddata[beg:fin] .= snd

    end

    return

end

function snduv!(
    snddata::Vector{<:Real}, z::Vector{<:Real}, sndfile::AbstractString
)

    snd = readdlm(fadd,',',comments=true); zobs = snd[:,1]; windobs = snd[:,2]
    spl = Spline1D(zobs,windobs); snddata .= spl(z)

    return

end

function sndcopy(fsnd::AbstractString;overwrite::Bool=true)

    ftem = joinpath(@__DIR__,"../extra/snd")

    if overwrite || !isfile(fsnd)
        @debug "$(Dates.now()) - Unable to find sounding file, copying data from SAMTools repository ..."
        cp(ftem,fsnd,force=true);
    end

end

function sndprint(fsnd::AbstractString,snddata::Array{<:Real,2},p::Real)

    nz = size(snddata,1)

    sndcopy(fsnd); open(fsnd,"a") do io
        @printf(io,"%10.2f, %10d, %10.2f\n",0.00,nz,p)
    end

    open(fsnd,"a") do io
        for iz = 1 : nz
            @printf(
                io,"%16.8f\t%16.8f\t%16.8f\t%16.8f\t%16.8f\t%16.8f\n",
                snddata[iz,1],snddata[iz,2],snddata[iz,3],
                snddata[iz,4],snddata[iz,5],snddata[iz,6]
            )
        end
    end

    open(fsnd,"a") do io
        @printf(io,"%10.2f, %10d, %10.2f\n",10000.00,nz,p)
    end

    open(fsnd,"a") do io
        for iz = 1 : nz
            @printf(
                io,"%16.8f\t%16.8f\t%16.8f\t%16.8f\t%16.8f\t%16.8f\n",
                snddata[iz,1],snddata[iz,2],snddata[iz,3],
                snddata[iz,4],snddata[iz,5],snddata[iz,6]
            )
        end
    end

end

function samsnd(
    fsnd::AbstractString="snd";
    tmppath::AbstractString="", prjpath::AbstractString,
    experiment::AbstractString="", config::AbstractString, fname::AbstractString,
    usndfile::AbstractString="", vsndfile::AbstractString="",
    usnd::Real=0, uzlow::Real=0, uzhigh::Real=0,
    vsnd::Real=0, vzlow::Real=0, vzhigh::Real=0,
    ndays::Integer=0
)

    init,sroot = samstartup(
        prjpath=prjpath,fname=fname,
        experiment=experiment,config=config,
        welcome=false
    )

    snddata,p = samstat2snd(sroot,ndays); z = @view snddata[:,1];
    if usnd != 0; snduv!(snddata[:,5],z,usnd,uzlow,uzhigh) end
    if vsnd != 0; snduv!(snddata[:,6],z,vsnd,vzlow,vzhigh) end

    if usndfile != ""; snduv!(snddata[:,5],z,usndfile) end
    if vsndfile != ""; snduv!(snddata[:,6],z,vsndfile) end

    sndprint(fsnd,snddata,p)

end
