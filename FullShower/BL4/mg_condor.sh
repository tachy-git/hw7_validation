#!/usr/bin/env bash
#set -euo pipefail

#############
### setup ###
#############
Hw_Loc="/cms/ldap_home/taehee/HerwigWD"
Singularity_Loc="$Hw_Loc"
MG_version="MG5_aMC_v3_5_1"
#MG_version="MG5_aMC_v3_3_2"

nevents=20000
MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"

jobtag1="${1:?missing arg1}"
jobtag2="${2:?missing arg2}"
generation="${3:?missing generation (RS|FO)}"
zpmass="${4:?missing zpmass}"
ptj="${5:?missing ptj}"
com="${6:?missing com (13TeV|13p6TeV)}"

die() { echo "ERROR: $*" >&2; exit 1; }

###############
### physics ###
###############
ebeam=""
case "$com" in
  13TeV)   ebeam=6500 ;;
  13p6TeV) ebeam=6800 ;;
  *) die "Unknown com='$com' (expected 13TeV or 13p6TeV)" ;;
esac

zpwidth=""
if [[ "$generation" == "FO" ]]; then
  case "$zpmass" in
    5)  zpwidth="0.03026" ;;
    20) zpwidth="0.1307"  ;;
    50) zpwidth="0.3271"  ;;
    *)  die "Unsupported zpmass='$zpmass' for FO" ;;
  esac
fi

###############
### output  ###
###############
base="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/mg_nEvt-${nevents}"
case "$generation" in
  RS) outputdir="${base}/Pt-${ptj}_ppjj_${jobtag1}/${jobtag2}" ;;
  FO) outputdir="${base}/Pt-${ptj}_MZp-${zpmass}_${jobtag1}/${jobtag2}" ;;
  *)  die "Unknown generation='$generation' (expected RS or FO)" ;;
esac

mkdir -p "$outputdir"
cd "$outputdir"
echo "Working Directory >> $outputdir"

#########################
### environment setup ###
#########################
export PATH="$Singularity_Loc/.pyenv/bin:$PATH"
export PYENV_ROOT="$Singularity_Loc/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export LD_LIBRARY_PATH="$Singularity_Loc/opt/$MG_version/HEPTools/lhapdf6_py3/lib:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="/cms/ldap_home/taehee/.local/lib/python3.8/site-packages:${PYTHONPATH:-}"
python -m pip install --upgrade pip
python -m pip install --user six

###############
### MG run  ###
###############
MG_File="MG_setup.dat"
: > "$MG_File"  # truncate

{
  echo "set auto_update 0"
  echo "import model B-L-4_UFO"

  if [[ "$generation" == "RS" ]]; then
    echo "define q = u s d c u~ s~ d~ c~"
    echo "generate p p > q q @1"
    echo "add process p p > q g @2"
  else
    echo "generate p p > zp j j, zp > mu+ mu-"
  fi

  echo "output madevent mg"
  echo "launch"
  echo "set nevents $nevents"
  echo "set ebeam $ebeam"
  echo "set etaj 3."
  echo "set ptj $ptj"
  echo "set drjj 0.4"

  if [[ "$generation" == "FO" ]]; then
    echo "set Mzp $zpmass"
    echo "set Wzp $zpwidth"
    echo "set cut_decays True"
    echo "set xptl 30."
    echo "set ptl 3."
    echo "set etal 3."
    echo "set drjl 0."
    echo "set drll 0."
  fi

  rnum="$(shuf -i 1-99999999 -n 1)"
  echo "set iseed $rnum"
  echo "set use_syst False"
} >> "$MG_File"

"$MG" "$MG_File"

cp "mg/Events/run_01/unweighted_events.lhe.gz" "$outputdir/"
cp "$MG_File" "$outputdir/"

rm -rf "mg"
