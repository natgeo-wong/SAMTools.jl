function sammakefile(
    src :: AbstractString = ""
)

    if src == ""; src = joinpath(@__DIR__,"..","templates","run_template","Makefile") end
    fid = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template","Makefile")
    cp(src,fid,force=true)

    return

end

function samsource(
    path :: AbstractString
)

    fid = joinpath(DEPOT_PATH[1],"files","SAMTools","run_template","Build.csh")
    tid = "tmp.txt"

    open(tid,"w") do tio
        open(joinpath(fol,fid),"r") do fio
            s = read(fio,String)
            s = replace(s,"{samsourcedir}"=>path)
            write(tio,s)
        end
    end
    mv(tid,joinpath(fol,fii),force=true)

    return

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

    return

end

function samrundata(
    path :: AbstractString
)

    src = joinpath(DEPOT_PATH[1],"files","SAMTools","exp")
    tdr = pwd(); cd(src)
    symlink(path,"RUNDATA",dir_target=true)
    cd(tdr)

    return

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

    return

end
