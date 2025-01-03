#!/bin/bash

echo ""
now=$(date +"%T")
echo "Starting time : $now"
echo ""
echo ""

#############
### setup ###
#############

CompileUFO=false
UFOName=RKZp_UFO
EVTpRUN=100000

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
process=${2}
sample=${3}
ZprimeMass=${4}
Coupling=${5}

outputdir=/cms_scratch/taehee/HerwigSample/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${process}
WD=/cms_scratch/taehee/HerwigSample/hw_nEvt-${EVTpRUN}/MZp-${ZprimeMass}/${sample}/${process}

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
if [[ -f "${outputdir}/LHC.hepmc" ]]; then
    echo "${outputdir}/LHC.hepmc exists..."
    exit 1
else
    rm -rf ${outputdir}
fi

###########
### run ###
###########

mkdir -p ${WD}
cd ${WD}
cp /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/13TeV/QCD_M5_13TeV-mg-hw/RAnalysis.cc .

RB="$Singularity_Loc/bin/rivet-build"
source "$Singularity_Loc/bin/activate"

# compiling ufo file
# compiling ufo file
if [ "$CompileUFO" = true ] && [ ! -f FRModel.model ]; then
  if [[ ! -d ${UFOName} ]]; then
    cp -r $Hw_Loc/hw7_validation/FullShower/RKZp/13TeV/QCD_M5_13TeV-mg-hw/feynrules-current/Models/RKZp/RKZp_UFO .
    sed -i "127s/10./${ZprimeMass}/" ${UFOName}/parameters.py
    sed -i "23s/1./${Coupling}/" ${UFOName}/parameters.py #gbb
    sed -i "187s/0.04/0.0001/" ${UFOName}/parameters.py #gbs
  fi
  ufo2herwig ${UFOName} --enable-bsm-shower --convert
  sed -i "s/echo \*.cc/echo FRModel*.cc/g" Makefile
  sed -i "35,87s/^/#/" FRModel.model
  sed -i "101,123s/^/#/" FRModel.model
  make
fi

compileDir="${UFOName}_MZp-${ZprimeMass}_gbb-${Coupling//./p}"
cp -r $Hw_Loc/hw7_validation/FullShower/RKZp/13TeV/QCD_M5_13TeV-mg-hw/${compileDir}/* .

# compile rivet analysis
echo "Compile the rivet analysis, RAnalysis.cc"
chmod +x $RB
$RB Rivet.so RAnalysis.cc
export RIVET_ANALYSIS_PATH=$(pwd -P)
echo ""

# run hw7
echo "Start runnning LHC.${1}.${process} (mg job # = ${sample})"
rnum=$(shuf -i 1-99999999 -n 1)
sed -e "s/__NEVENTS__/${EVTpRUN}/g" ${Hw_Loc}/hw7_validation/FullShower/RKZp/13TeV/QCD_M5_13TeV-mg-hw/LHC.in > LHC.in
sed -i "s/__SEED__/${rnum}/g" LHC.in
sed -i "s/__DIR__/\/cms_scratch\/taehee\/HerwigSample\/mg_nEvt-${EVTpRUN}\/MZp-${ZprimeMass}\/${sample}\/${process}/g" LHC.in
if [ "$ZprimeMass" -lt 9 ];then
    sed -i '37s/^/#/' LHC.in
fi
if [ "$ZprimeMass" -lt 4 ];then
    sed -i '39s/^/#/' LHC.in
    sed -i '43,44s/^/#/' LHC.in
fi

Herwig read LHC.in 
Herwig run LHC.run 

find . -mindepth 1 ! -name "*.hepmc" ! -name "LHC.yoda" ! -name "LHC.log" ! -name "LHC*in" ! -name "FRModel.model" -exec rm -rf {} +

echo ""
now=$(date +"%T")
echo "End time : $now"
echo ""
echo ""
