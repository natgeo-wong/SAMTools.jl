sampre2lvl(pressure::Real,smod::AbstractDict)  = argmin(abs.(smod["p"] .- pressure))
samvert2lvl(vertical::Real,smod::AbstractDict) = argmin(abs.(smod["z"] .- vertical))

function samrawfolder(
    spar::AbstractDict, sroot::AbstractDict;
    ilvl::Real=0
)

    if ilvl == 0
          return joinpath(sroot["raw"],"$(spar["ID"])");
    else; return joinpath(sroot["raw"],"$(spar["ID"])-lvl$(@sprintf("%03d",lvl))")
    end

end

function samrawname(
    spar::AbstractDict, sroot::AbstractDict;
    ilvl::Real=0, irun::Real
)

    fol = samrawfolder(spar,sroot,ilvl=ilvl)

    if ilvl == 0
          fnc = "$(spar["ID"])-sfc-run$(@sprintf("%04d",irun)).nc";
    else; fnc = "$(spar["ID"])-lvl$(@sprintf("%03d",ilvl))-run$(@sprintf("%04d",irun)).nc"
    end

    return joinpath(fol,fnc)

end

function samrawread(
    spar::AbstractDict, sroot::AbstractDict;
    ilvl::Real=0, irun::Real
)

    fnc = samrawname(spar,sroot,ilvl=ilvl,irun=irun)
    ds = Dataset(joinpath(rfol,rfnc))
    return ds,ds[spar["ID"]]

end
