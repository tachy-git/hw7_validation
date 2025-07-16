#!/bin/bash

#############
### setup ###
#############
EVTpRUN=20000

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
ShowerSetting=${1}
process=${2}
sample=${3}
ZprimeMass=${4}

outputdir=/cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${process}

# Herwig7 basic setups
#ln -s $(which python3) $Singularity_Loc/.local/bin/python
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

echo "outputdir: $outputdir"

###########
### run ###
###########
cd $outputdir
rm RAnalysis* Rivet*
cp /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4_jet/13TeV/RivetAnalysis/RAnalysis.cc .
source "$Singularity_Loc/bin/activate"
rivet-build Rivet.so RAnalysis.cc
export RIVET_ANALYSIS_PATH=$(pwd -P)
rm output.yoda
rivet --analysis="RAnalysis" -o output.yoda LHC.hepmc
