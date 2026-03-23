#!/bin/bash

compile_analysis=false

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

__SETUP=$'
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


com="13TeV" #13TeV or 13p6TeV

if $compile_analysis; then
  source preCompile.sh
  source ~/.bashrc

  singularity exec \
    --env LC_ALL=C \
    --bind "$(pwd):$(pwd)" \
    --bind /cms/ldap_home/taehee/HerwigWD/:/cms/ldap_home/taehee/HerwigWD/ \
    --bind /cms_scratch/taehee/:/cms_scratch/taehee/ \
    ~/osgvo-ubuntu-20.04_latest.sif \
    bash build_analysis_in_singularity.sh
fi

cat <<EOT > submit_condor_rv.txt
universe        = vanilla
executable      = rv_condor.sh
arguments       = \$(Cluster) 
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
+SingularityImage = "/cms/ldap_home/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind = "/cms/ldap_home/taehee:/cms/ldap_home/taehee,/cms_scratch/taehee:/cms_scratch/taehee"
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

rm -rf joblog
mkdir -p joblog

while read -r generation zpmass jobtag; do
  [[ -z "$generation" ]] && continue
  [[ "$generation" =~ ^# ]] && continue

  if [[ $generation == *RS* ]]; then
    queue=50
  else
    queue=100
  fi

  JobBatchName="${generation}_MZp-${zpmass}_${jobtag}"

  base="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/hw_nEvt-20000/MZp-${zpmass}/${jobtag}"
  find $base -name output*yoda -delete

  echo "Submitting $queue jobs: $JobBatchName"

  #queue=10

  condor_submit submit_condor_rv.txt \
    -append "arguments = $jobtag \$(Process) $generation $zpmass $com" \
    -append "JobBatchName = Rivet_$JobBatchName" \
    -append "priority = 100000" \
    -append "queue $queue"
done <<< "$SETUP"

