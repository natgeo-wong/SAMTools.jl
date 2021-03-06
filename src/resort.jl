function samresort2Dall(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nx,ny,nz = smod["size"]; nt = length(stime["t2D"]); nct = stime["nt2D"];
    it = stime["it"]
    nfnc = floor(Int64,nt/it); if rem(nt,it) != 0; nfnc += 1 end
    data = Array{Float32,3}(undef,nx,ny,it);

    for inc = 1 : nfnc

        @info "$(Dates.now()) - Resorting $(uppercase(spar["name"])) data into chunks of $(stime["it"]) timesteps ... CYCLE $(inc)"

        if inc == nfnc
            it = mod(nt,it); if it == 0; it = stime["it"]; end
            data = Array{Float32,3}(undef,nx,ny,it)
        end

        ids1 = findids(inc,nct)
        ids2 = findids(inc,nct,it)
        beg  = convert(Int64,mod((inc-1)*stime["it"]+init["is01t"]+1,nct));

        if inc == nfnc
              fin = convert(Int64,mod(nt,nct));
        else; fin = convert(Int64,mod((inc-1)*stime["it"]+init["is01t"]+it,nct));
        end

        if ids1 == ids2
            if beg == 0; beg = nct; end
            if fin == 0; fin = nct; end
            ds1 = Dataset(sroot["flist2D"][ids1])
            data .= ds1[spar["IDnc"]][:,:,beg:fin]
            close(ds1)
        else
            beg1 = beg;                    if beg1 == 0; beg1 = nct end
            beg2 = mod(1-fin,stime["it"]); if beg2 == 0; beg2 = it; end
            fin1 = mod(-fin,stime["it"]);  if fin1 == 0; fin1 = it; end
            fin2 = fin;                    if fin2 == 0; fin2 = nct end
            ds1  = Dataset(sroot["flist2D"][ids1])
            ds2  = Dataset(sroot["flist2D"][ids2])
            data[:,:,1:fin1]   .= ds1[spar["IDnc"]][:,:,beg1:end]
            if inc != nfnc
                  data[:,:,beg2:end] .= ds2[spar["IDnc"]][:,:,1:fin2]
            else; data[:,:,beg2:end] .= ds2[spar["IDnc"]][:,:,1:end]
            end
            close(ds1); close(ds2)
        end

        samresortsave(data,[inc,it],smod,spar,stime,sroot)

    end

end

function samresort2Dsep(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nx,ny,nz = smod["size"]; nt = length(stime["t2D"]); it = stime["it"]; tt = 0;
    nfnc = floor(Int64,nt/it); if rem(nt,it) != 0; nfnc += 1 end
    data = Array{Float32,3}(undef,nx,ny,it);


    for inc = 1 : nfnc

        @info "$(Dates.now()) - Resorting $(uppercase(spar["name"])) data into chunks of $(stime["it"]) timesteps ... FILE $(inc)"

        if inc == nfnc
            it = mod(nt,it); if it == 0; it = stime["it"]; end
            data = Array{Float32,3}(undef,nx,ny,it);
        end

        for ii = 1 : it; tt = tt + 1
            ds = Dataset(sroot["flist2D"][tt])
            data[:,:,ii] .= ds[spar["IDnc"]][:,:,1]
            close(ds)
        end

        samresortsave(data,[inc,it],smod,spar,stime,sroot)

    end

end

function samresort3D(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    nx,ny,nz = smod["size"]; nt = length(stime["t3D"]); it = stime["it"]; tt = 0;
    nfnc = floor(Int64,nt/it); if rem(nt,it) != 0; nfnc += 1 end
    data = Array{Float32,4}(undef,nx,ny,nz,it);

    for inc = 1 : nfnc

        @info "$(Dates.now()) - Resorting $(uppercase(spar["name"])) data into chunks of $(stime["it"]) timesteps ... CYCLE $(inc)"

        if inc == nfnc
            it = mod(nt,it); if it == 0; it = stime["it"]; end
            data = Array{Float32,4}(undef,nx,ny,nz,it);
        end

        for ii = 1 : it; tt = tt + 1
            ds = Dataset(sroot["flist3D"][tt])
            data[:,:,:,ii] .= ds[spar["IDnc"]][:,:,:,1]
            close(ds)
        end

        samresortsave(data,[inc,it],smod,spar,stime,sroot)

    end

end

function samresortsave(
    data::Union{Array{<:Real,3},Array{<:Real,4}},
    runinfo::AbstractArray,
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    inc,it = runinfo; mtype = smod["moduletype"]

    @info "$(Dates.now()) - Saving $(uppercase(spar["name"])) data for CYCLE $(inc) ..."

    rfnc = samrawname(spar,sroot,irun=inc);
    if isfile(rfnc)
        @info "$(Dates.now()) - Stale NetCDF file $(rfnc) detected.  Overwriting ..."
        rm(rfnc);
    end

    ds = NCDataset(rfnc,"c",attrib = Dict(
        "Conventions"  => "CF-1.6",
        "Date Created" => "$(Dates.now())"
    ))

    if occursin("3D",mtype);
        scale,offset = samncoffsetscale(data);
    end

    ds.dim["x"] = smod["size"][1];
    ds.dim["y"] = smod["size"][2];
    if occursin("3D",mtype); ds.dim["z"] = smod["size"][3]; end
    ds.dim["t"] = convert(Integer,it)

    ncx = defVar(ds,"x",Float32,("x",),attrib = Dict(
        "units"     => "km",
        "long_name" => "X",
    ))

    ncy = defVar(ds,"y",Float32,("y",),attrib = Dict(
        "units"     => "km",
        "long_name" => "Y",
    ))

    nct = defVar(ds,"t",Float64,("t",),attrib = Dict(
        "units"     => "days since 0000-00-00 00:00:00.0",
        "long_name" => "time",
        "calendar"  => "no_calendar",
    ))

    if occursin("2D",mtype);

        ncv = defVar(ds,spar["ID"],Float32,("x","y","t"),attrib = Dict(
            "units"         => spar["unit"],
            "long_name"     => spar["name"],
        ))

    else

        ncz = defVar(ds,"z",Float32,("z",),attrib = Dict(
            "units"     => "km",
            "long_name" => "Z",
        ))

        ncv = defVar(ds,spar["ID"],Int16,("x","y","z","t"),attrib = Dict(
            "units"         => spar["unit"],
            "long_name"     => spar["name"],
            "scale_factor"  => scale,
            "add_offset"    => offset,
            "_FillValue"    => Int16(-32767),
            "missing_value" => Int16(-32767),
        ))

    end

    ncx[:] = smod["x"]/1000
    ncy[:] = smod["y"]/1000

    if occursin("2D",mtype)
          nct[:] = stime["t2D"][(inc-1)*stime["it"] .+ (1:it)]
    else; ncz[:] = smod["z"] / 1000
          nct[:] = stime["t3D"][(inc-1)*stime["it"] .+ (1:it)]
    end

    ncv[:] = data;

    close(ds)

    @info "$(Dates.now()) - $(uppercase(spar["name"])) data for CYCLE $(inc) has been saved into the file $rfnc ..."

end

function samresort(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    if occursin("2D",smod["moduletype"]);
          if smod["2Dsep"]
                samresort2Dsep(smod,spar,stime,sroot)
          else; samresort2Dall(smod,spar,stime,sroot)
          end
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
