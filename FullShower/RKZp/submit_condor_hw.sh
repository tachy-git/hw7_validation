#!/bin/bash

generation="RS" #RS or FO
com="13TeV" #13TeV or 13p6TeV

JOBTAGS=("Pt-65To67_ppbb_34671" "Pt-67To70_ppbb_34672" "Pt-70To75_ppbb_34673" "Pt-75To80_ppbb_34674" "Pt-80To85_ppbb_34675" "Pt-85To90_ppbb_34676" "Pt-90To100_ppbb_34677" "Pt-100To120_ppbb_34678" "Pt-120To150_ppbb_34679" "Pt-150To9999_ppbb_34680")
ZPMASSES=(12)

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) 
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

mkdir -p joblog

for ((i=0; i<${#JOBTAGS[@]}; i++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
    zpmass=${ZPMASSES[m]}
    jobtag=${JOBTAGS[i]}
    JobBatchName="${generation}_MZp-${zpmass}_$jobtag" \
    queue=$(ls /cms_scratch/taehee/HerwigSample/RKZp_13TeV/RS/mg_nEvt-100000/$jobtag | wc -l)
    echo "Submitting $queue jobs: $JobBatchName"
    sleep 1

    condor_submit submit_condor_hw.txt \
    -append "arguments = $jobtag \$(Process) $generation $zpmass $com" \
    -append "JobBatchName =$JobBatchName" \
    -append "queue $queue"
done
done
