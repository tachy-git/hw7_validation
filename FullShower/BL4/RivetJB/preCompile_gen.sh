#!/usr/bin/env bash

########################################################################
# You can run the rivet by using the exsiting hepmc file
# But when you try to run the condor job with singularity image,
# it will fail when trying to build the rivet code
# (It seems that there is no right to write inside a singularity image)
# So, let's pre-build it and then copy it for each condor job run.
# This script does
# 1. Copy RAnalysis.cc code while subsituting some variables
#    This should be done OUTSIDE a singularity image to have a write permission.
# 2. Build the rivet code
#    This should be done INSIDE a singularity image.
# 3. After building the rivet code, you can submit condor jobs by
#    ./submit_condor_rv.sh
# I couldn't find the better way to run rivet...
########################################################################

#############
### setup ###
#############
WD=$(pwd -P)

#############################
### Rivet helper function ###
#############################
run_rivet() {
  local generation="$1"
  local zpmass="$2"

  cd $WD
  outputdir="preCompiled_${generation}_GEN_${zpmass}"
  
  case "$zpmass" in
    5) quarkptcut=40 ;;
    20) quarkptcut=80 ;;
    50) quarkptcut=150 ;;
  esac

  # prepare the compilation
  if [[ -d $outputdir ]]; then
    rm -rf $outputdir
  fi
  mkdir $outputdir
  cd $outputdir
  cp -f "../RAnalysis_gen.cc" RAnalysis.cc
  sed -i "s/__SAMPLETAG__/${generation}/g" RAnalysis.cc
  sed -i -e "s/__QUARKPTCUT__/${quarkptcut}/g" RAnalysis.cc

  echo cd $outputdir
  echo rivet-build Rivet.so RAnalysis.cc
  echo cd ..
}

##################
### Rivet run  ###
##################
run_rivet FO 5
run_rivet FO 20
run_rivet FO 50
run_rivet RS 5
run_rivet RS 20
run_rivet RS 50
