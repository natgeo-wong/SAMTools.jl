function samresort2D(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nt = length(stime["t2D"]); it = 360; nfnc = floor(nt/it) + 1; tt = 0;
    nx,ny,nz = smod["size"]; data = Array{Float32,4}(undef,nx,ny,it);

    for inc = 1 : nfnc

        if inc == nfnc; it = mod(nt,it); data = Array{Int16,3}(undef,nx,ny,it) end

        ids1 = floor(((inc-1)*360+1)/1000); ids2 = floor((inc*360)/1000)
        beg  = mod((inc-1)*360+1,1000);
        fin  = mod(inc*360,1000);

        if ids1 == ids2
            ds1 = Dataset(sroot["flist3D"][ids1])
            data .= ds[spar["IDnc"]][:,:,beg:fin]
            close(ds1)
        else
            ds1 = Dataset(sroot["flist3D"][ids1])
            ds2 = Dataset(sroot["flist3D"][ids2])
            data[:,:,1:(360-fin)]   .= ds1[spar["IDnc"]][:,:,beg:end]
            data[:,:,(361-fin):end] .= ds1[spar["IDnc"]][:,:,1:fin]
            close(ds1); close(ds2)
        end

        samresortsave(data,[inc,it,0],smod,spar,stime,sroot)

    end

end

function samresort3D(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nt = stime["ntime"]; it = 360; nfnc = floor(nt/it) + 1; tt = 0;
    nx,ny,nz = smod["size"]; data = Array{Float32,4}(undef,nx,ny,it);
    lvl = spar["level"]; if lvl == "all"; lvl = collect(1:nz) end

    for ilvl in lvl, inc = 1 : nfnc

        if inc == nfnc; it = mod(nt,it); data = Array{Int16,3}(undef,nx,ny,it) end
        for ii = 1 : it; tt = tt + 1;
            ds = Dataset(sroot["flist3D"][tt])
            data[:,:,ii] .= ds[spar["IDnc"]][:,:,ilvl,1]
            close(ds)
        end

        samresortsave(data,[inc,it,ilvl],smod,spar,stime,sroot)

    end

end

function samresortsave(
    data::Union{Array{<:Real,3},Array{<:Real,4}}, runinfo::AbstractArray,
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    inc,it,ilvl = runinfo; mtype = smod["moduletype"]
    rfnc = samrawname(smod,spar,irun=inc,ilvl=ilvl);
    if isfile(fnc)
        @info "$(Dates.now()) - Stale NetCDF file $(fnc) detected.  Overwriting ..."
        rm(fnc);
    end

    ds = NCDataset(fnc,"c",attrib = Dict(
        "Conventions"  => "CF-1.6",
        "Date Created" => "$(Dates.now())"
    ))

    scale,offset = samncoffsetscale(data);

    ds.dim["x"] = smod["size"][1];
    ds.dim["y"] = smod["size"][2];
    if occursin("2D",mtype); ds.dim["z"] = 1; end
    ds.dim["t"] = length(it)

    ncx = defVar(ds,"x",Int16,("x",),attrib = Dict(
        "units"     => "km",
        "long_name" => "X",
    ))

    ncy = defVar(ds,"y",Int16,("y",),attrib = Dict(
        "units"     => "km",
        "long_name" => "Y",
    ))

    if occursin("2D",mtype)
        ncz = defVar(ds,"z",Int16,("z",),attrib = Dict(
            "units"     => "km",
            "long_name" => "Z",
            "level"     => ilvl
        ))
    end

    nct = defVar(ds,"t",Float64,("t",),attrib = Dict(
        "units"     => "days since 0000-00-00 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "no_calendar",
    ))

    ncv = defVar(ds,spar["ID"],Int16,("x","y","t"),attrib = Dict(
        "scale_factor"  => scale,
        "add_offset"    => offset,
        "_FillValue"    => Int16(-32767),
        "missing_value" => Int16(-32767),
        "units"         => spar["unit"],
        "long_name"     => spar["name"],
    ))

    ncx[:] = smod["x"]
    ncy[:] = smod["y"]
    if occursin("2D",mtype); ncz[:] = smod["z"][ilvl] end

    if occursin("2D",mtype)
          nct[:] = ((inc-1)*360 .+ collect(1:it)) * stime["t2Dstep"] + stime["tbegin"]
    else; nct[:] = ((inc-1)*360 .+ collect(1:it)) * stime["t3Dstep"] + stime["tbegin"]
    end

    ncv[:] = data;

    close(ds)

end

function samresort(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    if occursin("2D",smod["moduletype"]);
          samresort2D(smod,spar,stime,sroot)
    else; samresort3D(smod,spar,stime,sroot)
    end

end

function samresort(
    init::AbstractDict, sroot::AbstractString;
    modID::AbstractString, parID::AbstractString,
    height::Real=0
)

    smod,spar,stime = saminitialize(init,modID=modID,parID=parID,height=height)
    samresort(smod,spar,stime,sroot)

end
