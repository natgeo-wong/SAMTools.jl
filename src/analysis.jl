function samanalysis(
    smod::AbstractDict, spar::AbstractDict, stime::AbstractDict,
    sroot::AbstractDict
)

    if occursin("2D",smod["moduletype"]);
          samanalysis2D(smod,spar,stime,sroot)
    else; samanalysis3D(smod,spar,stime,sroot)
    end

end

function samanalysis(
    init::AbstractDict, sroot::AbstractString;
    modID::AbstractString, parID::AbstractString,
    height::Real=0
)

    smod,spar,stime = saminitialize(init,modID=modID,parID=parID,height=height)
    samanalysis(smod,spar,stime,sroot)

end
