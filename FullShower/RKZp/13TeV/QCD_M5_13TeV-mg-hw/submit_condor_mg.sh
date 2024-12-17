#!/bin/bash

#ptbin=(130 135 140 150 160 170 180 200 250 9999)
#queues=(1684 261 3960 3466 928 671 1523 3157 2449)
ptbin=(230 240 250 270 300 350 9999)
queues=(4327 1750 6142 2963 6210 8322)

zpmass=55

cat <<EOT > submit_condor_mg.txt
universe        = vanilla
executable      = mg_condor.sh
arguments       = \$(Cluster) \$(Process) \$(ptj) \$(ptjmax) \$(zpmass)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.log
+SingularityImage = "/u/user/taehee/HerwigLoc/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind = "/u/user/taehee:/u/user/taehee"
should_transfer_files = YES
EOT

for ((i=0; i<${#ptbin[@]}-1; i++)); do
    ptj=${ptbin[i]}
    ptjmax=${ptbin[i+1]}
    queue=${queues[i]}
    #queue=500
    echo "Submitting job for MG ptbinned [$ptj, $ptjmax] with Zprime mass $zpmass"
    condor_submit submit_condor_mg.txt \
    -append "arguments = \$(Cluster) \$(Process) $ptj $ptjmax $zpmass" \
    -append "queue $queue"
done
