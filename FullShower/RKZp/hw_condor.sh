#!/usr/bin/env bash

echo ""
echo "Starting time : $(date +"%T")"
echo ""
echo ""

#############
### setup ###
#############
Hw_Loc="/cms/ldap_home/taehee/HerwigWD"
Singularity_Loc="$Hw_Loc"

nevents=100000

jobtag1="${1:?missing arg1}"
jobtag2="${2:?missing arg2}"
generation="${3:?missing generation (RS|FO)}"
zpmass="${4:?missing zpmass}"
com="${5:?missing com (13TeV|13p6TeV)}"

die() { echo "ERROR: $*" >&2; exit 1; }

###############
### physics ###
###############
com_=""
case "$com" in
  13TeV)   com_=13000 ;;
  13p6TeV) com_=13600 ;;
  *) die "Unknown com='$com' (expected 13TeV or 13p6TeV)" ;;
esac

coupling=""
case "$zpmass" in
  12) coupling="0p1" ;;
  *) die "Unsupported zpmass='$zpmass'" ;;
esac

###############
### output  ###
###############
base="/cms_scratch/taehee/HerwigSample/RKZp_${com}/${generation}"
mgdir="${base}/mg_nEvt-${nevents}/${jobtag1}/${jobtag2}"
outputdir="${base}/hw_nEvt-${nevents}/MZp-${zpmass}/${jobtag1}/${jobtag2}"

if [[ -f "$outputdir/LHC.yoda" ]]; then
  echo "$outputdir/LHC.yoda exists... abort."
  exit 1
fi

rm -rf "$outputdir"
mkdir -p "$outputdir"
cd "$outputdir"
echo "Working Directory >> $outputdir"

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

###############
### HW run  ###
###############
cp "$Hw_Loc/hw7_validation/FullShower/RKZp/RAnalysis.cc" .
cp -r "$Hw_Loc/hw7_validation/FullShower/RKZp/UFO/MZp-${zpmass}_gbb-${coupling}/"* .

RB="$Singularity_Loc/bin/rivet-build"
source "$Singularity_Loc/bin/activate"
export RIVET_ANALYSIS_PATH="$(pwd -P)"
chmod +x "$RB"
"$RB" Rivet.so RAnalysis.cc

rnum="$(shuf -i 1-99999999 -n 1)"

sed -e "s/__NEVENTS__/${nevents}/g" \
    -e "s/__SEED__/${rnum}/g" \
    -e "s/__COM__/${com_}/g" \
    "$Hw_Loc/hw7_validation/FullShower/RKZp/input/$generation.in" > LHC.in

sed -i "s|__DIR__|${mgdir}|g" LHC.in

if [ "$zpmass" -lt 9 ];then
  sed -i '/b,bbar/s/^/#/' LHC.in
fi

chmod 777 LHC.in
Herwig read LHC.in
Herwig run LHC.run

find . -mindepth 1 \
  ! -name "*.hepmc" \
  ! -name "LHC.yoda" \
  ! -name "LHC.log" \
  ! -name "LHC*in" \
  ! -name "FRModel.model" \
  -exec rm -rf {} +

echo ""
echo "End time : $(date +"%T")"
echo ""
