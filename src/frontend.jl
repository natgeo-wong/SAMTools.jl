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
    irun::Integer
)

    fol = samrawfolder(spar,sroot);
    fnc = "$(spar["ID"])-run$(@sprintf("%04d",irun)).nc";

    return joinpath(fol,fnc)

end

function samrawread(
    spar::AbstractDict, sroot::AbstractDict;
    irun::Integer
)

    fnc = samrawname(spar,sroot,irun=irun); ds = Dataset(fnc)
    return ds,ds[spar["ID"]]

end

function samstatread(
    statvar::AbstractString, sroot::AbstractDict;
    irun::Integer=1
)

    tnc = sroot["flistst"][irun]
    fnc = joinpath(sroot["stat"],split(tnc,"/")[end]);

    return ds,ds[statvar]

end
