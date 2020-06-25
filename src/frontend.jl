sampre2lvl(pressure::Real,smod::AbstractDict)  = argmin(abs.(smod["p"] .- pressure))
samvert2lvl(vertical::Real,smod::AbstractDict) = argmin(abs.(smod["z"] .- vertical))

function samrawfolder(
    spar::AbstractDict, sroot::AbstractDict
)

    fol = joinpath(sroot["raw"],"$(spar["ID"])");
    if !isdir(fol); mkpath(fol) end

    return fol

end

function samrawname(
    spar::AbstractDict, sroot::AbstractDict;
    irun::Real
)

    fol = samrawfolder(spar,sroot);
    fnc = "$(spar["ID"])-run$(@sprintf("%04d",irun)).nc";

    return joinpath(fol,fnc)

end

function samrawread(
    spar::AbstractDict, sroot::AbstractDict;
    irun::Real
)

    fnc = samrawname(spar,sroot,irun=irun); ds = Dataset(fnc)
    return ds,ds[spar["ID"]]

end
