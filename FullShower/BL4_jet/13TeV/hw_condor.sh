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
ZprimeWidth=${5}

outputdir=/cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${process}
WD=$outputdir

echo "outputdir: $outputdir"
echo "workingdir: $WD"
if [[ -f "${outputdir}/LHC.yoda" ]]; then
    echo "${outputdir}/LHC.yoda exists..."
    exit 1
else
    rm -rf ${outputdir}
fi

if [ "${ZprimeMass}" -eq 5 ] || [ "${ZprimeMass}" -eq 6 ] || [ "${ZprimeMass}" -eq 7 ]; then
  coupling="0.2" #x3
elif [ "${ZprimeMass}" -eq 8 ]; then
  coupling="0.23333333333333334" #x3.5
elif [ "${ZprimeMass}" -eq 10 ]; then
  coupling="0.26666666666666666" #x4
elif [ "${ZprimeMass}" -eq 12 ]; then
  coupling="0.26666666666666666" #x4
elif [ "${ZprimeMass}" -eq 15 ]; then
  coupling="0.3" #x4.5
elif [ "${ZprimeMass}" -eq 20 ]; then
  coupling="0.3333333333333333" #x5
elif [ "${ZprimeMass}" -eq 30 ]; then
  coupling="0.4" #x6
elif [ "${ZprimeMass}" -eq 40 ]; then
  coupling="0.4666666666666667" #x7
elif [ "${ZprimeMass}" -eq 50 ]; then
  coupling="0.6" #x9
else
  echo "ZprimeMass: ${ZprimeMass} --> error"
  return
fi

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

###########
### run ###
###########
mkdir -p ${WD}
cd ${WD}
cp /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4_jet/13TeV/RAnalysis.cc .
cp -r /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4_jet/13TeV/UFO/"MZp-${ZprimeMass}"/* .

RB="$Singularity_Loc/bin/rivet-build"
source "$Singularity_Loc/bin/activate"
export RIVET_ANALYSIS_PATH=$(pwd -P)
chmod +x $RB
$RB Rivet.so RAnalysis.cc

# run hw7
echo "Start runnning ${1}.${process} (mg job # = ${sample})"
rnum=$(shuf -i 1-99999999 -n 1)
sed -e "s/__NEVENTS__/${EVTpRUN}/g" ${Hw_Loc}/hw7_validation/FullShower/BL4_jet/13TeV/input/${ShowerSetting}.in > LHC.in
sed -i "s/__SEED__/${rnum}/g" LHC.in
sed -i "s/__COUPLING__/${coupling}/g" LHC.in
sed -i "s/__DIR__/\/cms_scratch\/taehee\/HerwigSample\/BL4\/mg_nEvt-${EVTpRUN}\/${sample}\/${process}/g" LHC.in
if [ "$ZprimeMass" -lt 9 ];then
    sed -i '/b,bbar/s/^/#/' LHC.in
fi
if [ "$ZprimeMass" -lt 4 ];then
    sed -i '35s/^/#/' LHC.in
fi

Herwig read LHC.in 
Herwig run LHC.run 

find . -mindepth 1 ! -name "*.hepmc" ! -name "LHC.yoda" ! -name "LHC.log" ! -name "LHC*in" ! -name "FRModel.model" -exec rm -rf {} +

echo ""
now=$(date +"%T")
echo "End time : $now"
echo ""
