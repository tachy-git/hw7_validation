#!/bin/bash

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
WD=/cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${process}

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
echo "workingdir: $WD"
#if [[ -f "${outputdir}/LHC.yoda" ]]; then
#    echo "${outputdir}/LHC.yoda exists..."
#    exit 1
#else
#    rm -rf ${outputdir}
#fi
if [[ -d $outputdir ]]; then
	rm -rf $outputdir
fi

###########
### run ###
###########
mkdir -p ${WD}
cd ${WD}
cp /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4_jet/13TeV/RAnalysis.cc .

RB="$Singularity_Loc/bin/rivet-build"
source "$Singularity_Loc/bin/activate"

cp -r $Hw_Loc/hw7_validation/FullShower/BL4_jet/13TeV/UFO/"MZp-${ZprimeMass}"/* .

# compile rivet analysis
echo "Compile the rivet analysis, RAnalysis.cc"
chmod +x $RB
$RB Rivet.so RAnalysis.cc
export RIVET_ANALYSIS_PATH=$(pwd -P)
echo ""

# run hw7
echo "Start runnning ${1}.${process} (mg job # = ${sample})"
rnum=$(shuf -i 1-99999999 -n 1)
sed -e "s/__NEVENTS__/${EVTpRUN}/g" ${Hw_Loc}/hw7_validation/FullShower/BL4_jet/13TeV/input/${ShowerSetting}.in > LHC.in
sed -i "s/__SEED__/${rnum}/g" LHC.in
sed -i "s/__DIR__/\/cms_scratch\/taehee\/HerwigSample\/BL4\/mg_nEvt-${EVTpRUN}\/MZp-${ZprimeMass}\/${sample}\/${process}/g" LHC.in
if [ "$ZprimeMass" -lt 9 ];then
    sed -i '43s/^/#/' LHC.in
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
echo ""
