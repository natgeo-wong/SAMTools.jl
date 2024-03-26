#!/bin/sh

[HPC/SLURM]

module purge
module load [modules]

exproot=[expdir]
prmfile=$exproot/prm/[prmname].prm
sndfile=$exproot/snd/[sndname].snd
lsffile=$exproot/lsf/[lsfname].lsf

prmloc=./SAM/prm
sndloc=./SAM/snd
lsfloc=./SAM/lsf

cp $prmfile $prmloc
cp $sndfile $sndloc
cp $lsffile $lsfloc

scriptdir=$SLURM_SUBMIT_DIR
SAMname=`ls $scriptdir/SAM_*`

cd $scriptdir
[mpirun_extras]
[mpirun] $SAMname > ./LOGS/samrun.${SLURM_JOBID}.log

exitstatus=$?
echo SAM stopped with exit status $exitstatus

cd ./OUT_3D

for fbin3D in *$ensemblemember*.bin3D
do
    if bin3D2nc "$fbin3D" >& /dev/null
    then
        echo "Processing SAM bin3D output file $fbin3D ... done"
        rm "$fbin3D"
    else
        echo "Processing SAM bin3D output file $fbin3D ... failed"
    fi
done

for fbin2D in *$ensemblemember*.bin2D
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

for f2Dbin in *$ensemblemember*.2Dbin
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

for fstat in *$ensemblemember*.stat
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