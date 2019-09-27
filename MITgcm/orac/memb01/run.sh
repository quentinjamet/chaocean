#!/bin/bash
### Job Name
#PBS -N orac_mem01
### Project code
#PBS -A UFSU0011
#PBS -l walltime=12:00:00
#PBS -q economy
### Select 10 nodes with 36 CPUs each for a total of 360 MPI processes
### and require 128GB nodes (mem=109GB)
#PBS -l select=10:ncpus=36:mpiprocs=36:mem=109GB

# export the qsub command into the bash script
export SUBMIT=/opt/pbs/default/bin/qsub

#-----------------------------------------------------------------------------#
#     - Load PC parameters                                                    #
#     - Determine stop iteration for this period                              #
#-----------------------------------------------------------------------------#
varlist="confName confDir inDir runDir outDir scrDir monitor \
         mem_nb period iit fit nit \
         pChkptFreq chkptFreq dumpFreq exe dt"

source pc.vars

#-- make the run directory (all files will be linked there) --
if [ ! -d $runDir ]; then
 echo "run directory does not exist"$runDir > $monitor
 exit
else
 runDir2=$runDir/memb${mem_nb}
 if [ ! -d $runDir2 ]; then
  mkdir $runDir2
 else
  rm -rf $runDir2/*
 fi
fi

#-- set time parameters --
sit=$(($iit+$nit))
iit0=`$scrDir/add0upto10c $iit`
sit0=`$scrDir/add0upto10c $sit`

echo "=================================="             > $monitor
echo "Actual start time, of script:   "`date`         >> $monitor
echo "Configuration directory:        "$confDir       >> $monitor
echo "Simulation directory:           "$runDir2       >> $monitor
echo "Storage directory:              "$outDir       >> $monitor
echo "Period:                         "$period        >> $monitor
echo "Member number:                  "$mem_nb        >> $monitor
echo "--- Current iteration period ---  "             >> $monitor
echo "    iterSTART                  :"$iit           >> $monitor
echo "    iterSTEP                   :"$nit           >> $monitor
echo "    iterSTOP                   :"$sit           >> $monitor
echo "Overall FINAL iteration:       :"$fit           >> $monitor
echo "=================================="             >> $monitor

#-----------------------------------------------------------------------------#
#     - Set data files for first iteration period                             #
#	and make grid, OBCS, cheapAML and pickup links
#-----------------------------------------------------------------------------#
. $scrDir/setdata $confDir/memb$mem_nb $iit $nit $pChkptFreq \
                  $chkptFreq $dumpFreq

. $scrDir/mklink2 $runDir2 $confName $confDir $inDir $period $mem_nb $exe \
                  $iit $iit0 $outDir $monitor

#-----------------------------------------------#
#	 execute the model 			#
#-----------------------------------------------#
#-- go to running directory --
cd $runDir2

echo "=================================="   >> $confDir/memb${mem_nb}/$monitor
echo "Beginning model execution..."         >> $confDir/memb${mem_nb}/$monitor
mpiexec_mpt dplace -s 1 ./$exe
echo "executable name:        "$exe         >> $confDir/memb${mem_nb}/$monitor

status=$?
echo "Ended with status:  "$status   >> $confDir/memb${mem_nb}/$monitor

if test -f $runDir2/T.$sit0.meta; then
 echo "... "			       >> $confDir/memb${mem_nb}/$monitor
 echo "Model run fine. Go ahead "      >> $confDir/memb${mem_nb}/$monitor
 echo "=================================="   >> $confDir/memb${mem_nb}/$monitor
else
 echo "... "			       >> $confDir/memb${mem_nb}/$monitor
 echo "Model crashed. Stop  "	       >> $confDir/memb${mem_nb}/$monitor
 echo "=================================="   >> $confDir/memb${mem_nb}/$monitor
 exit
fi

# check for NaN
nan=$(grep NaN STDOUT.0000 | wc -l)
if [ $nan -ge 1 ]; then
 echo "... "			       >> $confDir/memb${mem_nb}/$monitor
 echo "Model nans ...   "	       >> $confDir/memb${mem_nb}/$monitor
 echo "=================================="   >> $confDir/memb${mem_nb}/$monitor
 exit
fi

#exit

#-----------------------------------------------------------------------------#
#         Check for pickups and move data			 	      #
#-----------------------------------------------------------------------------#
pick=$runDir2/pickup.$sit0.data
if [ -f $pick ]; then echo "Ocn pickup present:  "$pick
else echo "No Ocn pickup:  "$pick ; exit; fi

#-- move data for storage, including pickup files --
. ${scrDir}/movedata2 $runDir2 $outDir $period $sit0 $mem_nb $confName

mv $confDir/memb${mem_nb}/$monitor ${outDir}/memb${mem_nb}/run${period}/$monitor

#-----------------------------------------------------------------------------#
#                      Reset model parameters                                 #
#-----------------------------------------------------------------------------#
#-- back to config directory --
cd $confDir/memb${mem_nb}
rm -rf orac_mem${mem_nb}.*

source pc.vars
iit=$sit
period=$(($period+1))
rm -f pc.vars
for i in $varlist; do echo $i'='`eval echo '$'$i` >> pc.vars.temp; done
mv pc.vars.temp pc.vars

#-----------------------------------------------------------------------------#
#                         Resubmit  model                                     #
#-----------------------------------------------------------------------------#

#-- check iterations --
if [ $iit -ge $fit ]; then
 echo "==============================" >> $monitor
 echo "New iit exceeds fit;  All done" >> $monitor; exit; 
fi


#-- resubmit the model --
$SUBMIT  run.sh

