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
Hw_Loc=/cms/ldap_home/taehee/HerwigWD
UFOName="RKZp_UFO"
ZprimeMass=${1}
Coupling=${2}

###############
### compile ###
###############
source "$Hw_Loc/bin/activate"

compileDir="MZp-${ZprimeMass}_gbb-${Coupling/\./p}"
rm -rf $compileDir
mkdir -p $compileDir
cd $compileDir
# git clone git@github.com:joonblee/feynrules-current.git
cp -r /cms/ldap_home/taehee/feynrules-current/Models/RKZp/RKZp_UFO/ .


echo "Compiling UFO for model ${UFOName} with MZp ${ZprimeMass} and Coupling ${Coupling}..."

# change parameter settting
sed -i "127s/10./${ZprimeMass}/" ${UFOName}/parameters.py
sed -i "23s/1./${Coupling}/" ${UFOName}/parameters.py #gbb
sed -i "187s/0.04/0.0001/" ${UFOName}/parameters.py #gbs

export PYTHONPATH="$(pwd):$PYTHONPATH"
export PYTHONPATH="$(pwd)/${UFOName}:$PYTHONPATH"

ufo2herwig ${UFOName} --enable-bsm-shower

# turn off unrelatd splitting function
sed -i "s/echo \*.cc/echo FRModel*.cc/g" Makefile
sed -i "35,87s/^/#/" FRModel.model
sed -i "101,123s/^/#/" FRModel.model

make
