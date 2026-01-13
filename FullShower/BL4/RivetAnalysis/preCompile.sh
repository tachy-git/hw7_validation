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
#    Change "compile" to false
# 2. Build the rivet code
#    This should be done INSIDE a singularity image.
#    Change "compile" to true
# 3. After building the rivet code, you can submit condor jobs by
#    ./submit_condor_rv.sh
# I couldn't find the better way to run rivet...
########################################################################

compile=true

#############
### setup ###
#############
Hw_Loc="/cms/ldap_home/taehee/HerwigWD"
Singularity_Loc="$Hw_Loc"
WD=$(pwd -P)

#########################
### environment setup ###
#########################
if $compile; then
export PATH=$Singularity_Loc/.local/bin:$PATH
export LIBTOOL=$Singularity_Loc/.local/bin/libtool
export LIBTOOLIZE=$Singularity_Loc/.local/bin/libtoolize
export ACLOCAL_PATH=$Singularity_Loc/.local/share/aclocal:$ACLOCAL_PATH
export PATH="$Singularity_Loc/.pyenv/bin:$PATH"
export PYENV_ROOT=$Singularity_Loc/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export PYTHONUSERBASE=$Singularity_Loc/.pyenv
export PATH=$PYTHONUSERBASE/bin:$PATH
export LDFLAGS="-L$Singularity_Loc/.local/lib"
export CPPFLAGS="-I$Singularity_Loc/.local/include"
export PKG_CONFIG_PATH="$Singularity_Loc/.local/lib/pkgconfig"
fi

#############################
### Rivet helper function ###
#############################
run_rivet() {
  local generation="$1"
  local lpt="$2"
  local spt="$3"

  cd $WD
  outputdir="preCompiled_${generation}_${lpt}_${spt}"

  # prepare the compilation
  if ! $compile; then
    if [[ -d $outputdir ]]; then
      rm -rf $outputdir
    fi
    mkdir $outputdir
    cd $outputdir
    cp -f "../RAnalysis_template.cc" RAnalysis.cc
    sed -i "s/__SAMPLETAG__/${generation}/g" RAnalysis.cc
    sed -i -e "s/__LPT__/${lpt}/g" -e "s/__SPT__/${spt}/g" RAnalysis.cc

  # do the compilation (inside a singularity)
  else
    cd $outputdir
    source "$Singularity_Loc/bin/activate"
    rivet-build Rivet.so RAnalysis.cc

  fi
}

##################
### Rivet run  ###
##################
run_rivet FO 32 13
run_rivet FO 52 5
run_rivet RS 32 13
run_rivet RS 52 5
