#!/bin/bash

if [ $# -ne 2 ]; then
	echo "need to pass #nodes from pbsdsh, and jobname"
	exit
fi

num_workers=$1
jobname=$2

echo "Hello from $PBS_NODENUM $PBS_VNODENUM, $#, num_workers=$num_workers"

if [ -z $matlabsrc ]; then
	matlabsrc="/gleuclid/angli/casia-webface/src"
fi

#default: rootpath=/gleuclid/angli/aaproj/
WORKDIR="/gleuclid/angli/casia-webface/"
#cd $WORKDIR/..
if [ -z "$PBS_VNODENUM" ]; then
	PBS_VNODENUM=0
fi

node_id=$PBS_VNODENUM

host=`hostname`
logfile=$WORKDIR/pbs/$jobname/$jobname.o$node_id

echo $host > $logfile

cd $matlabsrc
matlab=/opt/common/matlab-r2014a/bin/matlab

prefix=""
matlab_func="$jobname($(($node_id+1)), $num_workers)"

command="$matlab -nodisplay -nosplash -nodesktop -singleCompThread -r "'"'"$prefix;$matlab_func;quit"'"'" > $logfile 2>&1"

echo $command
eval $command 
