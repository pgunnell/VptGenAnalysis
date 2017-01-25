#!/bin/bash

BASEDIR=`pwd`
echo "Base directory is $BASEDIR @ `hostname`"

#determine CMSSW config
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
ARCH=${SCRIPTPATH##/*/}
WORKDIR=${SCRIPTPATH}/../

#configure environment
cd $WORKDIR
export SCRAM_ARCH=$ARCH
eval `scram r -sh`
cd -

#run with the arguments passed
$*

#copy output to storage area
for ext in root yoda; do
    a=(`ls *.${ext}`)
    for i in ${a[@]}; do 
	xrdcp ${i} root://eoscms//eos/cms/store/cmst3/user/psilva/Wmass/ntuples/Chunks/${i};
	rm ${i};
    done
done

