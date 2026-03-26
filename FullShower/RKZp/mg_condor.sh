#!/usr/bin/env bash
#set -euo pipefail

#############
### setup ###
#############
Hw_Loc="/cms/ldap_home/taehee/HerwigWD"
Singularity_Loc="$Hw_Loc"
MG_version="MG5_aMC_v3_5_1"
#MG_version="MG5_aMC_v3_3_2"

nevents=100000
MG="$Hw_Loc/opt/$MG_version/bin/mg5_aMC"

jobtag1="${1:?missing arg1}"
jobtag2="${2:?missing arg2}"
generation="${3:?missing generation (RS|FO)}"
zpmass="${4:?missing zpmass}"
ptb="${5:?missing ptb}"
ptbmax="${6:?missing ptbmamaxx}"
com="${7:?missing com (13TeV|13p6TeV)}"

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
    11)  zpwidth="0.2936" ;;
    20)  zpwidth="0.5372" ;;
    50)  zpwidth="1.346" ;;
    70)  zpwidth="1.884" ;;
    *)  die "Unsupported zpmass='$zpmass' for FO" ;;
  esac
fi

###############
### output  ###
###############
base="/cms_scratch/taehee/HerwigSample/RKZp_${com}/${generation}/mg_nEvt-${nevents}"
case "$generation" in
  RS) outputdir="${base}/Pt-${ptb}To${ptbmax}_ppbb_${jobtag1}/${jobtag2}" ;;
  FO) outputdir="${base}/Pt-${ptb}To${ptbmax}_MZp-${zpmass}_${jobtag1}/${jobtag2}" ;;
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
MG_File1="MG_output.dat"
: > "$MG_File1"
{
  echo "set auto_update 0"
  echo "import model RKZp_UFO"

  if [[ "$generation" == "RS" ]]; then
    echo "generate p p > b b~ QED=0 BSMU1=0"
  else
    echo "generate p p > zp b b~, zp > mu+ mu- --diagram_filter"
    #echo "generate p p > zp b b~, zp > mu+ mu-"
  fi
  echo "output madevent mg"
} >> "$MG_File1"

"$MG" "$MG_File1"

# ============================
# make a symbolic link for pdf 303600
# for the error, IsADirectoryError: [Errno 21] Is a directory: '/cms/ldap_home/taehee/HerwigWD/opt/MG5_aMC_v3_5_1/HEPTools/lhapdf6_py3/share/LHAPDF/NNPDF31_nnlo_as_0118'
PDFSRC="/cms/ldap_home/taehee/HerwigWD/opt/$MG_version/HEPTools/lhapdf6_py3/share/LHAPDF/NNPDF31_nnlo_as_0118"
PDFDST="$outputdir/mg/lib/PDFsets/NNPDF31_nnlo_as_0118"
mkdir -p "$outputdir/mg/lib/PDFsets"
rm -rf "$PDFDST"
ln -s "$PDFSRC" "$PDFDST"
# ============================
MG_File2="MG_launch.dat"
: > "$MG_File2"
{
  echo "launch mg"
  echo "set nevents $nevents"
  echo "set ebeam $ebeam"
  echo "set etab 4."
  echo "set ptb $ptb"
  echo "set ptbmax $ptbmax"

  if [[ "$generation" == "FO" ]]; then
    echo "set Mzp $zpmass"
    echo "set Wzp $zpwidth"
    echo "set cut_decays True"
    echo "set xptl 40."
    echo "set ptl 3."
    echo "set etal 3."
    echo "set drbl 0."
    echo "set drll 0."
  fi

  rnum="$(shuf -i 1-99999999 -n 1)"
  echo "set iseed $rnum"
  echo "set use_syst False"
  echo "set pdlabel lhapdf"
  echo "set lhaid 303600"
} >> "$MG_File2"

"$MG" "$MG_File2"

cp "mg/Events/run_01/unweighted_events.lhe.gz" "$outputdir/"
rm -rf mg py.py
