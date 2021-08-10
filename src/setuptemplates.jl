function templaterun(
    fol :: AbstractString,
    src :: AbstractString = "";
    dst :: AbstractString = "."
)

    if src == ""; src = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template") end
    if !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","run_template")
        cp(tem,src)
        mkdir(joinpath(src,"LOGS"))
    end
    cp(src,joinpath(dst,fol),force=true)

    return

end

function templateexp(
    dst :: AbstractString = "."
)

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","exp")
    if !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","exp")
        cp(tem,src)
    end
    cp(src,joinpath(dst,"exp"),force=true)

    return

end

function templatehpc()

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","hpc.txt")
    tem = joinpath(@__DIR__,"..","templates","hpc.txt")
    cp(tem,src,force=true)

    return

end

function overwritetemplate(
    overwriteexp :: Bool = false,
    overwriterun :: Bool = false,
    overwritehpc :: Bool = false,
)

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","exp")
    if overwriteexp || !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","exp")
        cp(tem,src,force=true)
    end

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template")
    if overwriterun || !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","run_template")
        cp(tem,src,force=true)
        mkdir(joinpath(src,"LOGS"))
    end

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","hpc.txt")
    if overwritehpc || !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","hpc.txt")
        cp(tem,src,force=true)
    end

    return

end
