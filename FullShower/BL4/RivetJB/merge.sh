#!/bin/bash

Nbatch=30

SETUP=$'
FO 5 Pt-20_MZp-5_6427500
FO 20 Pt-20_MZp-20_6427501
FO 50 Pt-20_MZp-50_6427502
RS 5 Pt-20_ppjj_6393624
RS 5 Pt-20_ppjj_6393625
RS 5 Pt-20_ppjj_6393626
RS 20 Pt-20_ppjj_6393624
RS 20 Pt-20_ppjj_6393625
RS 20 Pt-20_ppjj_6393626
RS 50 Pt-20_ppjj_6393624
RS 50 Pt-20_ppjj_6393625
RS 50 Pt-20_ppjj_6393626
FO_woPS 5 Pt-20_MZp-5_6427503
FO_woPS 20 Pt-20_MZp-20_6427504
FO_woPS 50 Pt-20_MZp-50_6427505
RS_One 5 Pt-20_ppjj_6427216
RS_One 5 Pt-20_ppjj_6427217
RS_One 20 Pt-20_ppjj_6427216
RS_One 20 Pt-20_ppjj_6427217
RS_One 50 Pt-20_ppjj_6427216
RS_One 50 Pt-20_ppjj_6427217
'
SETUP=$'
RS 5 Pt-20_ppjj_6393624
RS 5 Pt-20_ppjj_6393625
RS 5 Pt-20_ppjj_6393626
RS 20 Pt-20_ppjj_6393624
RS 20 Pt-20_ppjj_6393625
RS 20 Pt-20_ppjj_6393626
RS 50 Pt-20_ppjj_6393624
RS 50 Pt-20_ppjj_6393625
RS 50 Pt-20_ppjj_6393626
'

#SETUP=$'
#RS 5 Pt-20_MZp-5_6421903
#RS 20 Pt-20_MZp-20_6402654
#RS 50 Pt-20_MZp-50_6402656
#'

#############
### setup ###
#############
Hw_Loc=/cms/ldap_home/taehee/HerwigWD/
Singularity_Loc=$Hw_Loc

com="13TeV"
nevents=20000
compilation="5_5"

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
WD=`pwd`

#rm -rf yoda
mkdir yoda
cd yoda

source "$Singularity_Loc/bin/activate"

while read -r generation zpmass jobtag; do
  [[ -z "$generation" ]] && continue
  [[ "$generation" =~ ^# ]] && continue

  basepath="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/hw_nEvt-${nevents}/MZp-${zpmass}/${jobtag}"
  yoda="${generation}_MZp-${zpmass}_${jobtag}_${compilation}"

  for lastdigit in {0..9}; do
    echo "$generation $zpmass $jobtag $lastdigit $basepath $yoda"
  done
done <<< "$SETUP" \
| xargs -n 6 -P $Nbatch bash -c '
  generation=$1
  zpmass=$2
  jobtag=$3
  lastdigit=$4
  basepath=$5
  yoda=$6

  yodafiles=$(find "$basepath" -maxdepth 1 -type d -regex ".*/[0-9]*${lastdigit}$" \
    -exec find {} -type f -name "output_'${compilation}'.yoda" \;)

  if [ -n "$yodafiles" ]; then
    echo "→ Merging ${yoda}_${lastdigit} ($(echo "$yodafiles" | wc -l) files)"
    yodamerge -o "${yoda}_${lastdigit}.yoda" $yodafiles
  fi
' _

while read -r generation zpmass jobtag; do
  [[ -z "$generation" ]] && continue
  [[ "$generation" =~ ^# ]] && continue
  yoda="${generation}_MZp-${zpmass}_${jobtag}_${compilation}"
  echo "$yoda"
done <<< "$SETUP" \
| xargs -n 1 -P $Nbatch bash -c '
  yoda=$1
  echo "→ Final merge ${yoda}.yoda"
  yodamerge -o "${yoda}.yoda" "${yoda}"_[0-9].yoda 2>/dev/null
  rm -f "${yoda}"_[0-9].yoda
' _

###################################
# merge per (generation, zpmass)
###################################
while read -r generation zpmass jobtag; do
  [[ -z "$generation" ]] && continue
  [[ "$generation" =~ ^# ]] && continue

  pattern="${generation}_MZp-${zpmass}_*_${compilation}.yoda"

  if ls $pattern 1>/dev/null 2>&1; then
    yodamerge -o "${generation}_MZp-${zpmass}_${compilation}.yoda" $pattern
    rm -f $pattern
  fi
done <<< "$SETUP"

cd $WD

