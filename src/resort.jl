function samresort2D(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nx,ny,nz = smod["size"]; nt = length(stime["t2D"]); it = 360; tt = 0;
    nfnc = floor(nt/it) + 1;
    data = Array{Float32,3}(undef,nx,ny,it);

    for inc = 1 : nfnc

        if inc == nfnc
            it = mod(nt,it); if it == 0; it = 360; end
            data = Array{Float32,3}(undef,nx,ny,it)
        end

        ids1 = convert(Int64,floor(((inc-1)*360+1)/1000)) + 1;
        ids2 = convert(Int64,floor((inc*360)/1000)) + 1;
        beg  = convert(Int64,mod((inc-1)*360+1,1000));

        if inc == nfnc
              fin = convert(Int64,mod(nt,1000));
        else; fin = convert(Int64,mod(inc*360,1000));
        end

        if ids1 == ids2
            if fin == 0; fin = 1000; end
            ds1 = Dataset(sroot["flist2D"][ids1])
            data .= ds1[spar["IDnc"]][:,:,beg:fin]
            close(ds1)
        else
            beg1 = beg; beg2 = mod(1-fin,360);
            fin1 = mod(-fin,360); if fin1 == 0; fin1 = 360;  end
            fin2 = fin;           if fin2 == 0; fin2 = 1000; end
            ds1  = Dataset(sroot["flist2D"][ids1])
            ds2  = Dataset(sroot["flist2D"][ids2])
            data[:,:,1:fin1]   .= ds1[spar["IDnc"]][:,:,beg1:end]
            data[:,:,beg2:end] .= ds2[spar["IDnc"]][:,:,1:fin2]
            close(ds1); close(ds2)
        end

        samresortsave(data,[inc,it],smod,spar,stime,sroot)

    end

end

function samresort3D(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nt = stime["ntime"]; it = 360; nfnc = floor(nt/it) + 1; tt = 0;
    nx,ny,nz = smod["size"]; data = Array{Float32,3}(undef,nx,ny,it);
    lvl = spar["level"]; if lvl == "all"; lvl = collect(1:nz) end

    for ilvl in lvl, inc = 1 : nfnc; spar["level"] = ilvl

        if inc == nfnc
            it = mod(nt,it); if it == 0; it = 360; end
            data = Array{Float32,3}(undef,nx,ny,it)
        end
        
        for ii = 1 : it; tt = tt + 1;
            ds = Dataset(sroot["flist3D"][tt])
            data[:,:,ii] .= ds[spar["IDnc"]][:,:,ilvl,1]
            close(ds)
        end

        samresortsave(data,[inc,it],smod,spar,stime,sroot)

    end

end

function samresortsave(
    data::Union{Array{<:Real,3},Array{<:Real,4}}, runinfo::AbstractArray,
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    inc,it = runinfo; mtype = smod["moduletype"]
    rfnc = samrawname(spar,sroot,irun=inc);
    if isfile(rfnc)
        @info "$(Dates.now()) - Stale NetCDF file $(rfnc) detected.  Overwriting ..."
        rm(rfnc);
    end

    ds = NCDataset(rfnc,"c",attrib = Dict(
        "Conventions"  => "CF-1.6",
        "Date Created" => "$(Dates.now())"
    ))

    scale,offset = samncoffsetscale(data);

    ds.dim["x"] = smod["size"][1];
    ds.dim["y"] = smod["size"][2];
    if occursin("3D",mtype); ds.dim["z"] = 1; end
    ds.dim["t"] = convert(Integer,it)

    ncx = defVar(ds,"x",Float32,("x",),attrib = Dict(
        "units"     => "km",
        "long_name" => "X",
    ))

    ncy = defVar(ds,"y",Float32,("y",),attrib = Dict(
        "units"     => "km",
        "long_name" => "Y",
    ))

    if occursin("3D",mtype)
        ncz = defVar(ds,"z",Float32,("z",),attrib = Dict(
            "units"     => "km",
            "long_name" => "Z",
            "level"     => spar["level"]
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

    ncx[:] = smod["x"]/1000
    ncy[:] = smod["y"]/1000
    if occursin("3D",mtype); ncz[:] = smod["z"][spar["level"]] / 1000 end

    if occursin("2D",mtype)
          nct[:] = ((inc-1)*360 .+ collect(1:it)) * stime["tstep2D"] .+ stime["tbegin"]
    else; nct[:] = ((inc-1)*360 .+ collect(1:it)) * stime["tstep3D"] .+ stime["tbegin"]
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
    init::AbstractDict, sroot::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    height::Real=0
)

    smod,spar,stime = saminitialize(init,modID=modID,parID=parID,height=height)
    samresort(smod,spar,stime,sroot)

end
