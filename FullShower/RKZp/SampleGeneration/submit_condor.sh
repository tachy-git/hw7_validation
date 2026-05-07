#!/bin/bash

SAMPLES=("Pt-65To67_ppbb_165851" "Pt-67To70_ppbb_165854" "Pt-70To75_ppbb_165857" "Pt-75To80_ppbb_165860" "Pt-80To85_ppbb_165852" "Pt-85To90_ppbb_165855" "Pt-90To100_ppbb_165866" "Pt-100To120_ppbb_165869" "Pt-120To150_ppbb_165870" "Pt-150To9999_ppbb_165871")

ZPMASSES=(12)
coupling="0p1"
CAMPAIGNS=("RunIISummer20UL16") # "RunIISummer20UL16APV") # "RunIISummer20UL17") # "RunIISummer20UL18")

cat <<EOT > submit_condor.jds
universe        = vanilla
executable      = condor.sh
arguments       = \$(Process) \$(sample) \$(campaign)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7:latest"
+SingularityBindCVMFS = True
+SingularityBind  = "/cvmfs,/cms,/share,/cms_scratch,/tmp,/etc/grid-security"
x509userproxy = /tmp/x509up_u556951238
stream_output   = True
stream_error    = True
request_memory = 4GB
EOT

mkdir -p joblog
MAX_ALLJOBS=19000
MAX_MYJOBS=4000

for ((c=0; c<${#CAMPAIGNS[@]}; c++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
for ((i=0; i<${#SAMPLES[@]}; i++)); do
    campaign=${CAMPAIGNS[c]}
    zpmass=${ZPMASSES[m]}
    sample=${SAMPLES[i]}
    dir="/cms_scratch/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000/MZp-$zpmass/$sample/"
    if [[ ! -d "$dir" ]]; then
      continue
    fi
    queue=$(ls -d "$dir"/* 2>/dev/null | wc -l)
    if (( queue < 1 )); then
      continue
    fi

    while true; do
      myjobs=$(condor_q taehee | awk '/Total for query:/ {print $4}')
      alljobs=$(condor_q | awk '/Total for query:/ {print $4}')
      if (( myjobs + queue <= MAX_MYJOBS && alljobs + queue <= MAX_ALLJOBS )); then
        break
      fi
      echo -n Zzz...
      sleep 360
    done

    echo "Submitting jobs for sample production: $campaign"_"MZp-$zpmass"_"$sample"
    condor_submit submit_condor.jds \
        -append "arguments = \$(Process) $sample $campaign $zpmass $coupling" \
        -append "JobBatchName = "$campaign"_MZp-"$zpmass"_"$sample \
        -append "queue $queue"
done
done
done
