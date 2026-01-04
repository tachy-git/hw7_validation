#!/bin/bash

export LC_ALL=C

echo ""
now=$(date +"%T")
echo "Starting time : $now"
echo ""
echo ""

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
com=${5}

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

start=$(( process * 10 ))
end=$(( start + 9 ))

for ((i=start; i<=end; i++)); do
outputdir=/cms_scratch/taehee/HerwigSample/BL4_$com/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${i}

if [[ ! -f "${outputdir}/LHC.yoda" ]]; then
  echo ${outputdir}/LHC.yoda does not exist...
  echo Job for herwig run might be terminated unexpectedly, and this might make a problem
  continue
fi
if [[ ! -f "${outputdir}/LHC.hepmc" ]]; then
  echo ${outputdir}/LHC.hepmc does not exist...
  echo Nothing to filter
  continue
fi
if [[ -f "${outputdir}/LHC_filter.hepmc" ]]; then
  echo ${outputdir}/LHC_filter.hepmc already exists...
  echo This might be the incomplete one
  rm "${outputdir}/LHC_filter.hepmc"
fi

cd $outputdir
echo $outputdir

cp /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4_jet/13TeV/filter.py .
python3 filter.py
rm filter.py
if [[ -f "${outputdir}/LHC_filter.hepmc" ]]; then
    echo Filtering has ended successfully!
    echo remove ${outputdir}/LHC.hepmc
    rm LHC.hepmc
fi

done
