#!/bin/sh

# {HPC}

module purge
{module load}

case=RCE
project={projectname}
experiment={expname}
config={configname}
sndname={sndtemplate}
lsfname={lsftemplate}


exproot={scratch}/{projectname}/data/{expname}/{configname}/exp
prmfile=$exproot/prm/$experiment/${config}.prm
sndfile=$exproot/snd/$sndname
lsffile=$exproot/lsf/$lsfname

prmloc=./$case/prm
sndloc=./$case/snd
lsfloc=./$case/lsf

cp $prmfile $prmloc
cp $sndfile $sndloc
cp $lsffile $lsfloc

scriptdir=$SLURM_SUBMIT_DIR
SAMname=`ls $scriptdir/SAM_*`

cd $scriptdir
export OMPI_MCA_btl="self,openib"
time srun -n $SLURM_NTASKS --mpi=pmi2 --cpu_bind=cores --hint=compute_bound $SAMname > ./LOGS/samrun.${SLURM_JOBID}.log

exitstatus=$?
echo SAM stopped with exit status $exitstatus

cd ./OUT_3D

for fbin3D in *.bin3D
do
    if bin3D2nc "$fbin3D" >& /dev/null
    then
        echo "Processing SAM bin3D output file $fbin3D ... done"
        rm "$fbin3D"
    else
        echo "Processing SAM bin3D output file $fbin3D ... failed"
    fi
done

for fbin2D in *.bin2D
do
    if bin2D2nc "$fbin2D" >& /dev/null
    then
        echo "Processing SAM bin2D output file $fbin2D ... done"
        rm "$fbin2D"
    else
        echo "Processing SAM bin2D output file $fbin2D ... failed"
    fi
done

cd ../OUT_2D

for f2Dbin in *.2Dbin
do
    if 2Dbin2nc "$f2Dbin" >& /dev/null
    then
        echo "Processing SAM 2Dbin output file $f2Dbin ... done"
        rm "$f2Dbin"
    else
        echo "Processing SAM 2Dbin output file $f2Dbin ... failed"
    fi
done

cd ../OUT_STAT

for fstat in *.stat
do
    if stat2nc "$fstat" >& /dev/null
    then
        echo "Processing SAM STAT  output file $fstat ... done"
        rm "$fstat"
    else
        echo "Processing SAM STAT  output file $fstat ... failed"
    fi
done

cd ..

exit 0
