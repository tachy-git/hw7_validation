#!/bin/bash

samples=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521" "Pt-40_ppjj_6358527" "Pt-40_ppjj_6358528" "Pt-40_ppjj_6367593")
samplenames=("RS_1" "RS_2" "RS_3" "RS_4" "RS_5")
samples=("Pt-100_ppjj_6359495" "Pt-100_ppjj_6360141" "Pt-100_ppjj_6363474" "Pt-100_ppjj_6367595")
#samples=("Pt-150_ppjj_6359496" "Pt-150_ppjj_6360142" "Pt-150_ppjj_6363475" "Pt-150_ppjj_6363476" "Pt-150_ppjj_6367596")
#samples=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473" "Pt-80_ppjj_6367594")
samples=("Pt-60_ppjj_6355276" "Pt-60_ppjj_6355395" "Pt-60_ppjj_6355537")
samples=("Pt-120_ppjj_6355277" "Pt-120_ppjj_6355396" "Pt-120_ppjj_6355538")

zpmasses=(40)
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
#rm -rf yoda
mkdir yoda
cd yoda

source "$Singularity_Loc/bin/activate"

for ((i=0; i<${#samples[@]}; i++)); do
for ((m=0; m<${#zpmasses[@]}; m++)); do
  sample=${samples[i]}
  samplename=${samplenames[i]}
  zpmass=${zpmasses[m]}
  basepath="/cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-${nevents}/MZp-${zpmass}/${sample}"
  yoda="MZp-${zpmass}_${samplename}"

  echo "#############################"
  echo "# Processing ${samplename}"
  echo "#############################"

  for lastdigit in {0..9}; do
    yodafiles=$(find "${basepath}" -maxdepth 1 -type d -regex ".*/[0-9]*${lastdigit}$" \
      -exec find {} -type f -name "LHC.yoda" \; )

    if [ -n "$yodafiles" ]; then
      echo "  → Merging group ${lastdigit} ($(echo "$yodafiles" | wc -l) files)"
      yodamerge -o "${yoda}_${lastdigit}.yoda" $yodafiles &
    fi
  done

  wait

  yodamerge -o "${yoda}.yoda" "${yoda}"_[0-9].yoda
   rm "${yoda}"_[0-9].yoda
done
done
