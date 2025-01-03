#!/bin/bash

#############
### setup ###
#############

UFOName=RKZp_UFO

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc
ZprimeMass=${1}
Coupling=${2}

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

###############
### compile ###
###############

RB="$Singularity_Loc/bin/rivet-build"
source "$Singularity_Loc/bin/activate"

if [[ ! -d "feynrules-current" ]]; then
	git clone https://github.com/joonblee/feynrules-current.git
fi
compileDir="${UFOName}_MZp-${ZprimeMass}_gbb-${Coupling//./p}"
rm -rf $compileDir
mkdir -p $compileDir
cd $compileDir

echo "Compiling UFO for model ${UFOName} with MZp ${ZprimeMass} and gbb ${Coupling}..."

cp -r ../feynrules-current/Models/RKZp/RKZp_UFO .
sed -i "127s/10./${ZprimeMass}/" ${UFOName}/parameters.py
sed -i "23s/1./${Coupling}/" ${UFOName}/parameters.py #gbb
sed -i "187s/0.04/0.0001/" ${UFOName}/parameters.py #gbs
ufo2herwig ${UFOName} --enable-bsm-shower --convert
sed -i "s/echo \*.cc/echo FRModel*.cc/g" Makefile
sed -i "35,87s/^/#/" FRModel.model
sed -i "101,123s/^/#/" FRModel.model
make
