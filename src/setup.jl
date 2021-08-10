function templaterun(
    fol :: AbstractString,
    src :: AbstractString = "";
    dst :: AbstractString = "."
)

    if src == ""; src = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template") end
    if !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","run_template")
        cp(tem,src)
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
    end

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","hpc.txt")
    if overwritehpc || !isdir(src)
        tem = joinpath(@__DIR__,"..","templates","hpc.txt")
        cp(tem,src,force=true)
    end

end

function sammakefile(
    src :: AbstractString = ""
)

    if src == ""; src = joinpath(@__DIR__,"..","templates","run_template","Makefile") end
    fid = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template","Makefile")
    cp(src,fid,force=true)

end

function sammodules(
    modulelist :: Vector{<:AbstractString}
)

    for ii = 1 : length(modulelist)
        modulelist[ii] = string("module load ",modulelist[ii])
    end

    modprint = modulelist[1]

    if length(modulelist) > 1
        for ii = 2 : length(modulelist)
            modprint = modprint * "\n" * modulelist[ii]
        end
    end

    fol = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template")
    fid = ["bin2nc.slm","Build","ensemblexx.sh","modelrun.sh"]
    tid = "tmp.txt"

    for fii in fid
        open(tid,"w") do tio
            open(joinpath(fol,fii),"r") do fio
                s = read(fio,String)
                s = replace(s,"{module load}"=>modprint)
                write(tio,s)
            end
        end
        mv(tid,joinpath(fol,fii),force=true)
    end

end

function samscratch(
    path :: AbstractString
)

    fol = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template")
    fid = ["Build.csh","ensemblexx.sh","modelrun.sh"]
    tid = "tmp.txt"

    for fii in fid
        open(tid,"w") do tio
            open(joinpath(fol,fii),"r") do fio
                s = read(fio,String)
                s = replace(s,"{scratch}"=>path)
                write(tio,s)
            end
        end
        mv(tid,joinpath(fol,fii),force=true)
    end

end
