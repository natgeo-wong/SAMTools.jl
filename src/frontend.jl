sampre2lvl(pressure::Real,smod::AbstractDict)  = argmin(abs.(smod["p"] .- pressure))
samvert2lvl(vertical::Real,smod::AbstractDict) = argmin(abs.(smod["z"] .- vertical))

function samrawfolder(
    spar::AbstractDict, sroot::AbstractDict
)

    if spar["level"] == 0
          return joinpath(sroot["raw"],"$(spar["ID"])");
    else; return joinpath(sroot["raw"],"$(spar["ID"])-lvl$(@sprintf("%03d",spar["level"]))")
    end

end

function samrawname(
    spar::AbstractDict, sroot::AbstractDict;
    irun::Real
)

    fol = samrawfolder(spar,sroot); lvl = spar["level"];

    if spar["level"] == 0
          fnc = "$(spar["ID"])-sfc-run$(@sprintf("%04d",irun)).nc";
    else; fnc = "$(spar["ID"])-lvl$(@sprintf("%03d",lvl))-run$(@sprintf("%04d",irun)).nc"
    end

    return joinpath(fol,fnc)

end

function samrawread(
    spar::AbstractDict, sroot::AbstractDict;
    irun::Real
)

    fnc = samrawname(spar,sroot,irun=irun)
    ds = Dataset(joinpath(rfol,rfnc))
    return ds,ds[spar["ID"]]

end
