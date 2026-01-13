#!/bin/bash

jobtags=("Pt-20_MZp-5_6402653")
#jobtags=("Pt-20_MZp-20_6402654")
jobtags=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521" "Pt-40_ppjj_6358527" "Pt-40_ppjj_6358528")
jobtags=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473")
jobtags=("Pt-150_ppjj_6359496" "Pt-150_ppjj_6360142" "Pt-150_ppjj_6363475" "Pt-150_ppjj_6363476")

zpmasses=(50)

generation="RS"
com="13TeV"

#############
### setup ###
#############
Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc

nevents=20000

#########################
### environment setup ###
#########################
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

for ptcut in "32_13" "52_5"; do # lepton pT cut for rivet anlaysis
for ((m=0; m<${#zpmasses[@]}; m++)); do
for ((i=0; i<${#jobtags[@]}; i++)); do
  jobtag=${jobtags[i]}
  zpmass=${zpmasses[m]}
  basepath="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/hw_nEvt-${nevents}/MZp-${zpmass}/${jobtag}"
  yoda="${generation}_MZp-${zpmass}_${jobtag}_${ptcut}"

  echo "#############################"
  echo "# Processing ${yoda}"
  echo "#############################"
  for lastdigit in {0..9}; do
    yodafiles=$(find "${basepath}" -maxdepth 1 -type d -regex ".*/[0-9]*${lastdigit}$" \
      -exec find {} -type f -name "output_${ptcut}.yoda" \; )

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

yodamerge -o "${generation}_MZp-${zpmass}_${ptcut}.yoda" "${generation}_MZp-${zpmass}_*_${ptcut}.yoda"
rm "${generation}_MZp-${zpmass}_*_${ptcut}.yoda"
done
