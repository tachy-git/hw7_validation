#!/bin/bash

samplenames=("uudd_RS_Full" "uudd_FO_wPS")
samples=("Pt-20_ppjj_5431915" "Pt-20_2J_5457070")

zpmass=10
nevents=20000

#############
### setup ###
#############

echo ""
now=$(date +"%T")
echo "Starting time : $now"
echo ""
echo ""

Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc

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
rm -rf yoda
mkdir yoda
cd yoda

source "$Hw_Loc/bin/activate"

# run rivet
echo "#########################"
echo "# Merge and Stack Yodas #"
echo "#########################"
for ((i=0; i<${#samples[@]}; i++)); do
	sample=${samples[i]}
	samplename=${samplenames[i]}
    yodafiles=$(find /cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-${nevents}/MZp-${zpmass}/${sample}/ -type f -name "output.yoda")
	yoda="MZp-${zpmass}_${samplename}"
    yodamerge -o "${yoda}.yoda" $yodafiles
done
