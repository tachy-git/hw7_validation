#!/usr/bin/bash

echo "Setting up genValidation..."

SCRAM_ARCH="slc7_amd64_gcc900"
CMSSW="CMSSW_12_2_0_pre3"

echo "Setting up ${SCRAM_ARCH}, ${CMSSW} from config/run/cmsenv.dat..."

export $SCRAM_ARCH
export $CMSSW

source /cvmfs/cms.cern.ch/cmsset_default.sh
cd /cvmfs/cms.cern.ch/${SCRAM_ARCH}/cms/cmssw/${CMSSW}/src/
eval `scramv1 runtime -sh`
cd ~-
