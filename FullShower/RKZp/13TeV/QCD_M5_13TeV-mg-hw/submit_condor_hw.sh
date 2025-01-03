#!/bin/bash

SAMPLES=("Pt-130To140_4720322" "Pt-140To150_4720323" "Pt-150To170_4720324" "Pt-170To200_4720325" "Pt-200To250_4720326" "Pt-250To9999_4720327")

zpmass=50
coupling="0.1"

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) \$(Process) $sample $zpmass $coupling
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
+SingularityImage = "/cms/ldap_home/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind  = "/cms/ldap_home/taehee:/cms/ldap_home/taehee,/cms_scratch/taehee:/cms_scratch/taehee"
accounting_group = group_alice
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
    queue=$(ls /cms_scratch/taehee/HerwigSample/mg_nEvt-1000/MZp-$zpmass/$sample | wc -l)
    echo "Submitting $queue jobs for HW with MG job number $sample with Zprime mass $zpmass, coupling $coupling"
	condor_submit submit_condor_hw.txt \
	-append "arguments = \$(Cluster) \$(Process) $sample $zpmass $coupling" \
	-append "JobBatchName = MZp-"$zpmass"_"$sample \
	-append "queue $queue"
	sleep 30
done
