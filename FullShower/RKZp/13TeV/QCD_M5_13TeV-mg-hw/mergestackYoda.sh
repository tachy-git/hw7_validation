#!/bin/bash

SAMPLES=("Pt-130To135_1132246" "Pt-135To140_1132294" "Pt-140To150_1132295" "Pt-150To160_1132248" "Pt-160To170_1132249" "Pt-170To200_1132250" "Pt-200To9999_1132251")
SAMPLES=("Pt-230To240_1132296" "Pt-240To250_1132297" "Pt-250To270_1132298" "Pt-270To300_1132299" "Pt-300To350_1132300" "Pt-350To9999_1132258")
SAMPLES=("Pt-130To135_345510" "Pt-135To140_345511" "Pt-140To150_345512" "Pt-150To160_345513" "Pt-160To170_345514" "Pt-170To180_345515" "Pt-180To200_345516" "Pt-200To250_345517" "Pt-250To9999_345518")
SAMPLES=("Pt-230To240_345524" "Pt-240To250_345525" "Pt-250To260_345526" "Pt-260To280_1132311" "Pt-280To300_1132312" "Pt-300To350_1132313" "Pt-350To400_1132314" "Pt-400To9999_1132315")

zpmass=${1}

#############
### setup ###
#############

echo ""
now=$(date +"%T")
echo "Starting time : $now"
echo ""
echo ""

Singularity_Loc=/u/user/taehee/HerwigWD
Hw_Loc=/u/user/taehee/HerwigWD
WD=$Hw_Loc/hw7_validation/FullShower/RKZp/13TeV/QCD_M5_13TeV-mg-hw/

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
cd $WD
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
    yodafiles=$(find /pnfs/knu.ac.kr/data/cms/store/user/taehee/HerwigSample/hw/MZp-${zpmass}/${sample}/ -type f -name "LHC.yoda")
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
