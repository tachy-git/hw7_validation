#!/bin/bash

#############
### setup ###
#############
runRS=true
runFO0j=false
runFO1j=false
runFO2j=false
runFO12j=false

Hw_Loc=/u/user/taehee/HerwigLoc
Singularity_Loc=$Hw_Loc
MG_version="MG5_aMC_v3_5_1"

nevents=10000
ebeam=6500

MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"
outputdir=/pnfs/knu.ac.kr/data/cms/store/user/taehee/HerwigSample/mg/MZp-${5}/Pt-${3}To${4}_${1}/${2}
WD="tmp/mg/MZp-${5}/Pt-${3}To${4}_${1}/${2}"
mkdir -p ${WD}
cd ${WD}

if [[ ! -d "$outputdir" ]]; then
  echo "Make $outputdir directory."
  mkdir -p $outputdir
else
  echo "$outputdir exists."
fi

# Herwig7 basic setups
#ln -s $(which python3) $Singularity_Loc/.local/bin/python
#export PATH=$Singularity_Loc/.local/bin:$PATH
#export LIBTOOL=$Singularity_Loc/.local/bin/libtool
#export LIBTOOLIZE=$Singularity_Loc/.local/bin/libtoolize
#export ACLOCAL_PATH=$Singularity_Loc/.local/share/aclocal:$ACLOCAL_PATH
export PATH="$Singularity_Loc/.pyenv/bin:$PATH"
export PYENV_ROOT=$Singularity_Loc/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
#export PYTHONUSERBASE=$Singularity_Loc/.pyenv
#export PATH=$PYTHONUSERBASE/bin:$PATH
#export LDFLAGS="-L$Singularity_Loc/.local/lib"
#export CPPFLAGS="-I$Singularity_Loc/.local/include"
#export PKG_CONFIG_PATH="$Singularity_Loc/.local/lib/pkgconfig"
export LD_LIBRARY_PATH=$Singularity_Loc/opt/$MG_version/HEPTools/lhapdf6_py3//lib:$LD_LIBRARY_PATH
python -m pip install six --user

# setup file for RS to be stored
if $runRS; then
  echo "Run RS.${1}.${2}"
  RS_File="MG_setup.dat"
  RS_DIR=mg
  mkdir $RS_DIR
  #if [[ -d "$outputdir/$RS_DIR" ]]; then
  #  echo "$RS_DIR exists, quit."
  #  exit 1
  #else
  #  echo "No $RS_DIR directory. Run MG5 to generate a new sample."
  #fi
  echo "set auto_update 0"                     >> $RS_File
  echo "import model RKZp_UFO"                 >> $RS_File
  echo "generate p p > b b~ QED=0 BSMU1=0"     >> $RS_File
  echo "output madevent $RS_DIR"               >> $RS_File
  echo "launch"                                >> $RS_File
  echo "set nevents $nevents"                  >> $RS_File
  echo "set ebeam1 $ebeam"                     >> $RS_File
  echo "set ebeam2 $ebeam"                     >> $RS_File
  echo "set ptb ${3}"                          >> $RS_File
  echo "set ptbmax ${4}"                       >> $RS_File
  echo "set etab 4."                           >> $RS_File
  echo "set mzdinput ${5}"                     >> $RS_File
  echo "set use_syst False"                    >> $RS_File
  echo "set pdlabel lhapdf"                    >> $RS_File
  echo "set lhaid 303600"                      >> $RS_File
  $MG $RS_File
fi

# setup file for FO to be stored
if $runFO0j;then
  FO0j_File="MG_setup_FO0j.dat"
  FO0j_DIR=FO0j
  if [ -d "$FO0j_DIR" ]; then
    echo "$FO0j_DIR exists, erase"
    rm -rf $FO0j_DIR
  fi
  echo "set auto_update 0"                     >> $FO0j_File
  echo "import model RKZp_UFO"                 >> $FO0j_File
  echo "generate p p > zp > mu+ mu-"           >> $FO0j_File
  echo "output madevent $FO0j_DIR"             >> $FO0j_File
  echo "launch"                                >> $FO0j_File
  echo "set nevents $nevents"                  >> $FO0j_File
  echo "set ebeam1 $ebeam"                     >> $FO0j_File
  echo "set ebeam2 $ebeam"                     >> $FO0j_File
  echo "set ptl 5."                            >> $FO0j_File
  echo "set etal 2.5"                          >> $FO0j_File
  echo "set drll 0."                           >> $FO0j_File
  echo "set mzdinput 2."                       >> $FO0j_File
  echo "set use_syst False"                    >> $FO0j_File
  $MG $FO0j_File &> MG_${FO0j_DIR}.log 
fi

if $runFO1j;then
  FO1j_File="MG_setup_FO1j.dat"
  FO1j_DIR=FO1j
  if [ -d "$FO1j_DIR" ]; then
    echo "$FO1j_DIR exists, erase"
    rm -rf $FO1j_DIR
  fi
  echo "set auto_update 0"                     >> $FO1j_File
  echo "import model RKZp_UFO"                 >> $FO1j_File
  echo "generate p p > zp j HIG=0 HIW=0 QED=1" >> $FO1j_File
  echo "output madevent $FO1j_DIR"             >> $FO1j_File
  echo "launch"                                >> $FO1j_File
  echo "set nevents $nevents"                  >> $FO1j_File
  echo "set ebeam1 $ebeam"                     >> $FO1j_File
  echo "set ebeam2 $ebeam"                     >> $FO1j_File
  echo "set ptj 20."                           >> $FO1j_File
  echo "set etaj 5."                           >> $FO1j_File
  echo "set mzdinput 2."                       >> $FO1j_File
  echo "set use_syst False"                    >> $FO1j_File
  $MG $FO1j_File &> MG_${FO1j_DIR}.log 
fi

if $runFO2j;then
  FO2j_File="MG_setup_FO2j.dat"
  FO2j_DIR=FO2j
  if [ -d "$FO2j_DIR" ]; then
    echo "$FO2j_DIR exists, erase"
    rm -rf $FO2j_DIR
  fi
  echo "set auto_update 0"                     >> $FO2j_File
  echo "import model RKZp_UFO"                 >> $FO2j_File
  echo "generate p p > zp j j HIG=0 HIW=0 QED=1" >> $FO2j_File
  echo "output madevent $FO2j_DIR"             >> $FO2j_File
  echo "launch"                                >> $FO2j_File
  echo "set nevents $nevents"                  >> $FO2j_File
  echo "set ebeam1 $ebeam"                     >> $FO2j_File
  echo "set ebeam2 $ebeam"                     >> $FO2j_File
  echo "set ptj 20."                           >> $FO2j_File
  echo "set etaj 5."                           >> $FO2j_File
  echo "set mzdinput 2."                       >> $FO2j_File
  echo "set use_syst False"                    >> $FO2j_File
  $MG $FO2j_File &> MG_${FO2j_DIR}.log 
fi

if $runFO12j;then
  FO12j_File="MG_setup_FO12j.dat"
  FO12j_DIR=FO12j
  if [ -d "$FO12j_DIR" ]; then
    echo "$FO12j_DIR exists, erase"
    rm -rf $FO12j_DIR
  fi
  echo "set auto_update 0"                          >> $FO12j_File
  echo "import model RKZp_UFO"                      >> $FO12j_File
  echo "generate p p > zp j HIG=0 HIW=0 QED=1"      >> $FO12j_File
  echo "add process p p > zp j j HIG=0 HIW=0 QED=1" >> $FO12j_File
  echo "output madevent $FO12j_DIR"                 >> $FO12j_File
  echo "launch"                                     >> $FO12j_File
  echo "set nevents $nevents"                       >> $FO12j_File
  echo "set ebeam1 $ebeam"                          >> $FO12j_File
  echo "set ebeam2 $ebeam"                          >> $FO12j_File
  echo "set ptj 20."                                >> $FO12j_File
  echo "set etaj 5."                                >> $FO12j_File
  echo "set mzdinput 2."                            >> $FO12j_File
  echo "set use_syst False"                         >> $FO12j_File
  $MG $FO12j_File &> MG_${FO12j_DIR}.log 
fi

cp mg/Events/run_01/unweighted_events.lhe.gz $outputdir

#rm py.py MG_setup_FO.dat MG_setup_RS.dat MG5_debug 
