#!/bin/bash

#SAMPLES=("Pt-60To65_1366782" "Pt-65To70_1366783" "Pt-70To75_1366784" "Pt-75To80_1366785" "Pt-80To85_1366786" "Pt-85To90_1366787" "Pt-90To100_1366788" "Pt-100To140_1366789" "Pt-140To200_1366790" "Pt-200To9999_1366792")
SAMPLES=("Pt-200To210_4765938" "Pt-210To220_4765939" "Pt-220To230_4765940" "Pt-230To250_4765941" "Pt-250To270_4765942" "Pt-270To300_4765943" "Pt-300To400_4765944" "Pt-400To9999_4765945")
SAMPLES=("Pt-200To210_4767501" "Pt-210To220_4767502" "Pt-220To230_4767503" "Pt-230To250_4767504" "Pt-250To270_4767505" "Pt-270To300_4767506" "Pt-300To400_4767507" "Pt-400To9999_4767508")
SAMPLES=("Pt-140To145_4767530" "Pt-145To150_4767531" "Pt-150To160_4767532" "Pt-160To170_4767533" "Pt-170To180_4767534" "Pt-180To200_4767535" "Pt-200To240_4767536" "Pt-240To300_4767537" "Pt-300To9999_4767538")

zpmass=${1}
coupling=${2}

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
rm -rf yoda_${zpmass}
mkdir yoda_${zpmass}
cd yoda_${zpmass}

source "$Hw_Loc/bin/activate"

# run rivet
echo "#########################"
echo "# Merge and Stack Yodas #"
echo "#########################"
index=0
for sample in "${SAMPLES[@]}"; do
    yodafiles=$(find /cms_scratch/taehee/HerwigSample/hw_nEvt-100000/MZp-${zpmass}/gbb-${coupling}/${sample}/ -type f -name "LHC.yoda")
    yodamerge -o "LHC-$index.yoda" $yodafiles
    index=$((index + 1))
done
yodastack -o LHC.yoda LHC-*.yoda

cd $WD

echo ""
now=$(date +"%T")
echo "End time : $now"
echo ""
echo ""
