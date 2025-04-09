#!/bin/bash

#############
# Run the script by ./compileUFO.sh <ZprimeMass> <ZprimeWidth>
# UFO file is pre-compiled before being used in Herwig.
# If the script shows an error like "could not load the ufo python module",
# Just run it once again.
# You don't have to be in the singularity environment to run this script.
#############

#############
### setup ###
#############
Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
UFOName="B-L-4_UFO"
ZprimeMass=${1}
ZprimeWidth=${2}

###############
### compile ###
###############
source "$Singularity_Loc/bin/activate"

compileDir="MZp-${ZprimeMass}_WZp-${ZprimeWidth//./p}"
rm -rf $compileDir
mkdir -p $compileDir
cd $compileDir
wget https://feynrules.irmp.ucl.ac.be/raw-attachment/wiki/B-L-SM/B-L-4_UFO.zip
unzip $UFOName.zip
rm B-L-4_UFO.zip

echo "Compiling UFO for model ${UFOName} with MZp ${ZprimeMass} and WZp ${ZprimeWidth}..."

# change parameter settting
sed -i "159s/1500/${ZprimeMass}/" ${UFOName}/parameters.py
sed -i "311s/80./${ZprimeWidth}/" ${UFOName}/parameters.py
export PYTHONPATH=$PWD/$UFOName:$PYTHONPATH
ufo2herwig ${UFOName} --enable-bsm-shower --convert
# turn off unrelatd splitting function
sed -i "s/echo \*.cc/echo FRModel*.cc/g" Makefile
sed -i "54,72s/^/#/" FRModel.model
sed -i "146,254s/^/#/" FRModel.model
make
