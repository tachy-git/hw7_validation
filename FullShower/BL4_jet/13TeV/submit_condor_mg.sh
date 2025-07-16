#!/bin/bash

ptbin=(20 9999)
shower="2J" # RS FO ppjj 0J 1J 2J ppbb 2b
queue=50

zpmass=10

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
getenv = True
EOT

for ((i=0; i<${#ptbin[@]}-1; i++)); do
    ptj=${ptbin[i]}
    ptjmax=${ptbin[i+1]}
    #queue=${queues[i]}
    echo "Submitting job for MG ptbinned [$ptj, $ptjmax] with Zprime mass $zpmass"
    condor_submit submit_condor_mg.txt \
    -append "arguments = \$(Cluster) \$(Process) $ptj $shower $zpmass" \
    -append "JobBatchName = Pt-${ptj}_${shower}_\$(Cluster)" \
    -append "queue $queue"
done
