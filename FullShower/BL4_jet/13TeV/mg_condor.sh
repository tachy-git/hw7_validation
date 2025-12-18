#!/bin/bash

#############
### setup ###
#############

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
MG_version="MG5_aMC_v3_5_1"
#MG_version="MG5_aMC_v3_3_2"

nevents=20000
ebeam=6500

MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"
ptj=${3}
outputdir=/cms_scratch/taehee/HerwigSample/BL4/mg_nEvt-$nevents/Pt-${ptj}_ppjj_${1}/${2}
WD=$outputdir
mkdir -p ${WD}
cd ${WD}
echo "Working Directory >> $outputdir"

# Herwig7 basic setups
export PATH="$Singularity_Loc/.pyenv/bin:$PATH"
export PYENV_ROOT=$Singularity_Loc/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export LD_LIBRARY_PATH=$Singularity_Loc/opt/$MG_version/HEPTools/lhapdf6_py3//lib:$LD_LIBRARY_PATH
export PYTHONPATH=/cms/ldap_home/taehee/.local/lib/python3.8/site-packages:$PYTHONPATH
pip install --upgrade pip
python -m pip install six --user


MG_File="MG_setup.dat"
echo "set auto_update 0"                    >> $MG_File
echo "import model B-L-4_UFO" >> $MG_File
echo "define q = u s d c u~ s~ d~ c~" >> $MG_File
echo "generate p p > q q @1" >> $MG_File
echo "add process p p > q g @2" >> $MG_File
echo "output madevent mg" >> $MG_File
echo "launch" >> $MG_File
echo "set nevents $nevent" >> $MG_File
echo "set ebeam $ebeam" >> $MG_File
echo "set etaj 3." >> $MG_File
echo "set ptj $ptj" >> $MG_File
echo "set drjj 0.4" >> $MG_File
#echo "set Mzp" >> $MG_File
#echo "set Wzp" >> $MG_File
echo "set cut_decays True" >> $MG_File
echo "set xptl 30." >> $MG_File
echo "set ptl 10." >> $MG_File
echo "set etal 3." >> $MG_File
echo "set drjl 0." >> $MG_File
echo "set drll 0." >> $MG_File
rnum=$(shuf -i 1-99999999 -n 1)
echo "set iseed $rnum" >> $MG_File
echo "set use_syst False" >> $MG_File
$MG $MG_File

cp mg/Events/run_01/unweighted_events.lhe.gz $outputdir
cp $MG_File $outputdir

rm -rf mg
