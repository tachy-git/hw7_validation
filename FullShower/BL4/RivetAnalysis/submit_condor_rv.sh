#!/bin/bash

generation="FO" #RS or FO
ZPMASSES=(5)
com="13TeV" #13TeV or 13p6TeV

JOBTAGS=("Pt-20_MZp-5_6421903")
#JOBTAGS=("Pt-20_MZp-20_6402654")
#JOBTAGS=("Pt-20_MZp-50_6402656")
#JOBTAGS=("Pt-100_MZp-50_6423214")
#JOBTAGS=("Pt-20_ppjj_6413869")
#JOBTAGS=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521" "Pt-40_ppjj_6358527" "Pt-40_ppjj_6358528")
#JOBTAGS=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473")
#JOBTAGS=("Pt-150_ppjj_6360142" "Pt-150_ppjj_6363475" "Pt-150_ppjj_6363476" "Pt-150_ppjj_6359496")

#JOBTAGS=("Pt-20_MZp-20_6423371" "Pt-20_MZp-20_6423372" "Pt-20_MZp-20_6423400") # FSR ISR FSN

######### no xptl cut on FO
#JOBTAGS=("Pt-20_MZp-5_6422399")
#JOBTAGS=("Pt-20_MZp-20_6422400")
#JOBTAGS=("Pt-20_MZp-50_6422401")

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

mkdir -p joblog

if [[ $generation == "RS" ]]; then
  queue=500
else
  queue=100
  #queue=30
fi

for ((i=0; i<${#JOBTAGS[@]}; i++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
    zpmass=${ZPMASSES[m]}
    jobtag=${JOBTAGS[i]}
    JobBatchName="${generation}_MZp-${zpmass}_$jobtag"

    base="/cms_scratch/taehee/HerwigSample/BL4_${com}/${generation}/hw_nEvt-20000/MZp-${zpmass}/${jobtag}"
    find $base -name output*yoda -delete

    echo "Submitting $queue jobs: $JobBatchName"
    sleep 1

    condor_submit submit_condor_rv.txt \
    -append "arguments = $jobtag \$(Process) $generation $zpmass $com" \
    -append "JobBatchName =Rivet_$JobBatchName" \
    -append "queue $queue"
done
done
