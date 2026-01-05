#!/bin/bash

queue=5000
ptj=20
com="13TeV"

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

condor_submit submit_condor_mg.txt \
-append "arguments = \$(Cluster) \$(Process) $ptj $com" \
-append "JobBatchName = Pt-${ptj}_ppjj_\$(Cluster)" \
-append "queue $queue"
