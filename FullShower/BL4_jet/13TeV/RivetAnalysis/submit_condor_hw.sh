#!/bin/bash

SAMPLES=("Pt-20_ppjj_5431915" "Pt-20_2J_5457070")

zpmass=10
shower="FO_wPS"
#available shower setting: RS_One, RS_Full, FO_woPS, FO_wPS

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) \$(Process) $sample $zpmass $coupling
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
+SingularityImage = "/cms/ldap_home/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind  = "/cms/ldap_home/taehee:/cms/ldap_home/taehee,/cms_scratch/taehee:/cms_scratch/taehee"
accounting_group = group_cms
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
	#shower=${SHOWERS[i]}
    queue=$(ls /cms_scratch/taehee/HerwigSample/BL4/hw_nEvt-20000/MZp-${zpmass}/$sample | wc -l)
    echo "Submitting $queue jobs for HW with MG job number $sample with Zprime mass $zpmass, coupling $coupling"
	condor_submit submit_condor_hw.txt \
	-append "arguments = $shower \$(Process) $sample $zpmass" \
	-append "JobBatchName = Rivet_MZp-${zpmass}_$sample" \
	-append "queue $queue"
	sleep 1
done
