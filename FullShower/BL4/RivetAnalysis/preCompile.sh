#!/usr/bin/env bash

########################################################################
# You can run the rivet by using the exsiting hepmc file
# But when you try to run the condor job with singularity image,
# it will fail when trying to build the rivet code
# (It seems that there is no right to write inside a singularity image)
# So, let's pre-build it and then copy it for each condor job run.
# This script does
# 1. Copy RAnalysis.cc code while subsituting some variables
#    This should be done OUTSIDE a singularity image to have a write permission.
# 2. Build the rivet code
#    This should be done INSIDE a singularity image.
# 3. After building the rivet code, you can submit condor jobs by
#    ./submit_condor_rv.sh
# I couldn't find the better way to run rivet...
########################################################################

#############
### setup ###
#############
WD=$(pwd -P)

#############################
### Rivet helper function ###
#############################
run_rivet() {
  local generation="$1"
  local lpt="$2"
  local spt="$3"

  cd $WD
  outputdir="preCompiled_${generation}_${lpt}_${spt}"

  # prepare the compilation
  if [[ -d $outputdir ]]; then
    rm -rf $outputdir
  fi
  mkdir $outputdir
  cd $outputdir
  cp -f "../RAnalysis_template.cc" RAnalysis.cc
  sed -i "s/__SAMPLETAG__/${generation}/g" RAnalysis.cc
  sed -i -e "s/__LPT__/${lpt}/g" -e "s/__SPT__/${spt}/g" RAnalysis.cc

  HISTOCFG="$WD/histoCfg.txt"

  HISTOPTR_BLOCK="$(awk '
    NF==0 {next}
    $1 ~ /^#/ {next}
    {printf("  Histo1DPtr _%s;\n", $1)}
  ' "$HISTOCFG")"

  BOOKHISTO_BLOCK="$(awk '
    NF==0 {next}
    $1 ~ /^#/ {next}
    {printf("    book(_%s, \"%s\", %s, %s, %s);\n", $1, $1, $2, $3, $4)}
  ' "$HISTOCFG")"

  SCALEHISTO_BLOCK="$(awk '
    NF==0 {next}
    $1 ~ /^#/ {next}
    {printf("    scale(_%s, weight);\n", $1)}
  ' "$HISTOCFG")"

  HISTOPTR_BLOCK="$(awk 'NF && $1 !~ /^#/ {printf("       Histo1DPtr _%s;\n", $1)}' "$HISTOCFG")"
  BOOKHISTO_BLOCK="$(awk 'NF && $1 !~ /^#/ {printf("        book(_%s, \"%s\", %d, %s, %s);\n", $1, $1, int($2), $3, $4)}' "$HISTOCFG")"
  SCALEHISTO_BLOCK="$(awk 'NF && $1 !~ /^#/ {printf("       scale(_%s, weight);\n", $1)}' "$HISTOCFG")"
  HISTOPTR_BLOCK="$HISTOPTR_BLOCK" \
  BOOKHISTO_BLOCK="$BOOKHISTO_BLOCK" \
  SCALEHISTO_BLOCK="$SCALEHISTO_BLOCK" \
  perl -0777 -i -pe '
    s/__HISTOPTR__/$ENV{HISTOPTR_BLOCK}/g;
    s/__BOOKHISTO__/$ENV{BOOKHISTO_BLOCK}/g;
    s/__SCALEHISTO__/$ENV{SCALEHISTO_BLOCK}/g;
  ' RAnalysis.cc


  echo cd $outputdir
  echo rivet-build Rivet.so RAnalysis.cc
  echo cd ..
}

##################
### Rivet run  ###
##################
run_rivet FO 52 5
