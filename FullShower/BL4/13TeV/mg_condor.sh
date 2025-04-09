#!/bin/bash

#############
### setup ###
#############
runRS_ppjj=false
runRS_uudd=false
runFO_ppjzp=false
runFO_ppjjzp=false
runFO_uuddzp=true

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
MG_version="MG5_aMC_v3_5_1"

nevents=10000
ebeam=6500

MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"
outputdir=/cms_scratch/taehee/HerwigSample/BL4/mg_nEvt-$nevents/MZp-${5}_WZp-${6}/Pt-${3}To${4}_${1}/${2}
WD="tmp/mg_nEvt-$nevents/MZp-${5}_WZp-${6}/Pt-${3}To${4}_${1}/${2}"
mkdir -p ${WD}
cd ${WD}

if [[ ! -d "$outputdir" ]]; then
  echo "Make $outputdir directory."
  mkdir -p $outputdir
else
  echo "$outputdir exists."
fi

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
echo "set auto_update 0"                     >> $MG_File
echo "set auto_convert_model T"              >> $MG_File
echo "import model B-L-4_UFO"                >> $MG_File
if $runRS_ppjj; then
	echo "generate p p > j j"                >> $MG_File
elif $runRS_uudd; then
	echo "generate u u~ > d d~"				 >> $MG_File
elif $runFO_ppjzp; then
	echo "generate p p > j zp"               >> $MG_File
elif $runFO_ppjjzp; then
	echo "generate p p > j j zp"             >> $MG_File
elif $runFO_uuddzp; then
	echo "generate u u~ > d d~ zp"			 >> $MG_File
fi
echo "output madevent mg"                    >> $MG_File
echo "launch"								 >> $MG_File
echo "set nevents $nevents"                  >> $MG_File
echo "set ebeam $ebeam"						 >> $MG_File
echo "set etaj 5."                           >> $MG_File
echo "set ptj 20."                           >> $MG_File
echo "set drjj 0.4"                          >> $MG_File
echo "set Mzp 10"                            >> $MG_File
echo "set Wzp 0.01"                          >> $MG_File
echo "set use_syst False"                    >> $MG_File
$MG $MG_File
	
cp mg/Events/run_01/unweighted_events.lhe.gz $outputdir
