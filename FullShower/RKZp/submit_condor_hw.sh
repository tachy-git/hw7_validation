#!/bin/bash

generation="RS" #RS or FO
com="13TeV" #13TeV or 13p6TeV

JOBTAGS=("Pt-130To150_ppbb_195043")
ZPMASSES=(35)
QUEUES=(501)

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
MAX_ALLJOBS=19000
MAX_MYJOBS=4900

for ((i=0; i<${#JOBTAGS[@]}; i++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
    zpmass=${ZPMASSES[m]}
    jobtag=${JOBTAGS[i]}
    JobBatchName="${generation}_MZp-${zpmass}_$jobtag" \
    #queue=$(ls /cms_scratch/taehee/HerwigSample/RKZp_13TeV/RS/mg_nEvt-100000/$jobtag | wc -l)
    queue=${QUEUES[i]}
    if (( queue < 1 )); then
      continue
    fi

    echo "Submitting $queue jobs: $JobBatchName"
    while true; do
      myjobs=$(condor_q taehee | awk '/Total for query:/ {print $4}')
      alljobs=$(condor_q | awk '/Total for query:/ {print $4}')
      if (( myjobs + queue <= MAX_MYJOBS && alljobs + queue <= MAX_ALLJOBS )); then
        break
      fi
      echo -n Zzz...
      sleep 360
    done

    condor_submit submit_condor_hw.txt \
    -append "arguments = $jobtag \$(Process) $generation $zpmass $com" \
    -append "JobBatchName =$JobBatchName" \
    -append "queue $queue"
done
done
