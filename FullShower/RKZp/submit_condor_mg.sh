#!/bin/bash

queues=(48 61 119 124 83 56 164 197 112 86)
generation="RS" #RS or FO
zpmass=11
ptbin=(65 67 70 75 80 85 90 100 120 150 9999)
com="13TeV" #13TeV or 13p6TeV

cat <<EOT > submit_condor_mg.txt
universe        = vanilla
executable      = mg_condor.sh
arguments       = \$(Cluster) \$(Process) \$(ptj) \$(ptjmax) \$(zpmass)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
+SingularityImage = "/cms/ldap_home/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind = "/cms/ldap_home/taehee:/cms/ldap_home/taehee,/cms_scratch/taehee:/cms_scratch/taehee"
accounting_group = group_cms
should_transfer_files = YES
request_memory = 4GB
getenv = True
EOT

mkdir -p joblog

for ((i=0; i<${#ptbin[@]}-1; i++)); do
ptb=${ptbin[i]}
ptbmax=${ptbin[i+1]}
queue=${queues[i]}

if [ "$generation" = "RS" ]; then
JobBatchName="Pt-${ptb}To${ptbmax}_ppbb_\$(Cluster)"
elif [ "$generation" = "FO" ]; then
JobBatchName="Pt-${ptb}To${ptbmax}_MZp-${zpmass}_\$(Cluster)"
fi

condor_submit submit_condor_mg.txt \
-append "arguments = \$(Cluster) \$(Process) $generation $zpmass $ptb $ptbmax $com" \
-append "JobBatchName = $JobBatchName" \
-append "queue $queue"
done
