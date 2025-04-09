#!/bin/bash

SAMPLES=("Pt-20To9999_5229050" "Pt-20To9999_5229046") #RS_One
SAMPLES=("Pt-20To9999_5229076" "Pt-20To9999_5229077") #RS_Full
SAMPLES=("Pt-20To9999_5229107" "Pt-20To9999_5229109" "Pt-20To9999_5229111") #FO_woPS

zpmass=10
zwidth="0p01"
shower="FO_woPS"
#available shower setting: RS_One, RS_Full, FO_woPS, FO_wPS

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) \$(Process) $sample $zpmass $coupling
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
    queue=$(ls /cms_scratch/taehee/HerwigSample/BL4/mg_nEvt-10000/MZp-${zpmass}_WZp-${zwidth}/$sample | wc -l)
    echo "Submitting $queue jobs for HW with MG job number $sample with Zprime mass $zpmass, coupling $coupling"
	condor_submit submit_condor_hw.txt \
	-append "arguments = $shower \$(Process) $sample $zpmass $zwidth" \
	-append "JobBatchName = MZp-${zpmass}_WZp-${zwidth}_$sample" \
	-append "queue $queue"
	sleep 1
done
