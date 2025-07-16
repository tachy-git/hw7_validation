#!/bin/bash

#############
### setup ###
#############

runRS_ppjj=false #exclude g g > g g
runRS_uudd=false
runRS_ppbb=false
runFO_ppzp=false
runFO_ppjzp=false
runFO_ppjjzp=false
runFO_uuddzp=false
runFO_ppbbzp=false

if [ "${4}" = "RS" ]; then
	runRS_uudd=true
elif [ "${4}" = "FO" ]; then
	runFO_uuddzp=true

elif [ "${4}" = "ppjj" ]; then
	runRS_ppjj=true
elif [ "${4}" = "0J" ]; then
	runFO_ppzp=true
elif [ "${4}" = "1J" ]; then
	runFO_ppjzp=true
elif [ "${4}" = "2J" ]; then
	runFO_ppjjzp=true
elif [ "${4}" = "ppbb" ]; then
    runRS_ppbb=true
elif [ "${4}" = "2b" ]; then
    runFO_ppbbzp=true
fi

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
MG_version="MG5_aMC_v3_5_1"
#MG_version="MG5_aMC_v3_3_2"

nevents=20000
ebeam=6500
zpmass=${5}
zpwidth="0.06356"

MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"
outputdir=/cms_scratch/taehee/HerwigSample/BL4/mg_nEvt-$nevents/MZp-${5}/Pt-${3}_${4}_${1}/${2}
WD="tmp/mg_nEvt-$nevents/MZp-${5}/Pt-${3}_${4}_${1}/${2}"
mkdir -p ${WD}
cd ${WD}

rm -rf $outputdir
mkdir -p $outputdir
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
echo "set auto_update 0"                     >> $MG_File
echo "set auto_convert_model T"              >> $MG_File
echo "import model B-L-4_UFO"                >> $MG_File
if $runRS_ppjj; then
	echo "define q = u s d c u~ s~ d~ c~"    >> $MG_File
	echo "generate q q > j j @1"             >> $MG_File
	echo "add process q g > j j @2"          >> $MG_File
	echo "add process g q > j j @3"          >> $MG_File
	echo "add process g g > q q @4"          >> $MG_File
elif $runRS_uudd; then
	echo "generate u u~ > d d~"				 >> $MG_File
elif $runFO_ppzp; then
	echo "generate p p > zp"                 >> $MG_File
elif $runFO_ppjzp; then
	echo "generate p p > j zp" 				>> $MG_File
elif $runFO_ppjjzp; then
	echo "generate p p > j j zp, zp > mu+ mu-" 			>> $MG_File
elif $runFO_uuddzp; then
	echo "generate u u~ > d d~ zp --diagram_filter" 			>> $MG_File
	#echo "generate u u~ > d d~ zp --diagram_filter" >> $MG_File
elif $runRS_ppbb; then
    echo "generate p p > b b~"            >> $MG_File
elif $runFO_ppbbzp; then
    echo "generate p p > b b~ zp"            >> $MG_File
fi
echo "output madevent mg"                    >> $MG_File
echo "launch"								 >> $MG_File
echo "set nevents $nevents"                  >> $MG_File
echo "set ebeam $ebeam"						 >> $MG_File
if [ "$runRS_ppbb" = true ] || [ "$runFO_ppbbzp" = true ]; then
    echo "set etab 5."                           >> $MG_File
    echo "set ptb 20."                           >> $MG_File
    echo "set drbb 0.4"                          >> $MG_File
else
	echo "set etaj 5."                           >> $MG_File
	echo "set ptj 20."                           >> $MG_File
	echo "set drjj 0.4"                          >> $MG_File
fi
echo "set Mzp $zpmass"                            >> $MG_File
echo "set Wzp $zpwidth"                          >> $MG_File
echo "set ptl 0."                            >> $MG_File
echo "set etal -1"                            >> $MG_File
echo "set drjl 0."                            >> $MG_File
echo "set drll 0."                            >> $MG_File
echo "set use_syst False"                    >> $MG_File
$MG $MG_File
	
cp mg/Events/run_01/unweighted_events.lhe.gz $outputdir
cp $MG_File $outputdir
