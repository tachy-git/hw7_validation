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

nevents=20000

jobtag1="${1:?missing arg1}"
jobtag2="${2:?missing arg2}"
generation="${3:?missing generation (RS|FO|RS_One|FO_woPS)}"
zpmass="${4:?missing zpmass}"
com="${5:?missing com (13TeV|13p6TeV)}"

die() { echo "ERROR: $*" >&2; exit 1; }

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

#############################
### Rivet helper function ###
#############################
run_rivet() {
  local generation="$1"
  local preCompiled="$2"
  local outputdir="$3"

  echo "outputdir >> $outputdir"
  cd $outputdir

  yoda="output_${preCompiled}.yoda"

  if [[ ! -f "LHC.yoda" ]]; then
    echo "LHC.yoda does not exist... This job might failed. abort."
    return 1
  fi

  mkdir -p $outputdir
  cd $outputdir
  source "$Singularity_Loc/bin/activate"
  #cp -r /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4/RivetAnalysis/preCompiled_${generation}_${preCompiled}/Rivet.so .
  rm $yoda
  cp -r /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4/RivetJB/preCompiled_${generation}_${preCompiled}/Rivet.so .
  export RIVET_ANALYSIS_PATH="$(pwd -P)"
  if [[ "$generation" == *FO* ]]; then
    rivet --analysis="RAnalysis" -o $yoda LHC.hepmc
  elif [[ "$generation" == *RS* ]]; then
    rivet --analysis="RAnalysis" -o $yoda LHC.hepmc
  fi
  rm -f RAnalysis* Rivet*
}

##################
### Rivet run  ###
##################
base="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/hw_nEvt-${nevents}/MZp-${zpmass}/${jobtag1}"
if [[ "$generation" == *FO* ]]; then
  outputdir="${base}/${jobtag2}"
  run_rivet $generation 5_5 $outputdir

elif [[ "$generation" == *RS* ]]; then
  process="$jobtag2"
  start=$(( process * 10 ))
  end=$(( start + 9 ))

  for ((i=start; i<=end; i++)); do
    outputdir="${base}/${i}"
    run_rivet $generation 5_5 $outputdir
  done

else
  die "Unknown generation='$generation' (expected RS or FO)"
fi

echo ""
echo "End time : $(date +"%T")"
echo ""
