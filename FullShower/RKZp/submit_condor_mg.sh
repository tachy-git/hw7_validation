#!/bin/bash

ptbin=(65 67 70 75 80 85 90 100 120 150 9999)
queues=(53 67 131 136 91 62 180 217 123 95)
ptbin=(80 85 90 95 100 110 120 130 150 200 9999)
queues=(145 149 216 223 425 380 255 637 843 347)
ptbin=(130 135 140 145 150 160 170 180 200 240 300 9999)
queues=(728 717 901 606 1583 1561 853 1748 1894 785 743)
ptbin=(200 210 220 230 250 270 300 400 9999)
queues=(3116 1928 1008 2696 1368 1311 3231 623)

generation="RS" #RS or FO
zpmass=20
com="13p6TeV" #13TeV or 13p6TeV

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
request_memory = 24GB
getenv = True
EOT

mkdir -p joblog
MAX_ALLJOBS=19000
MAX_MYJOBS=4000

for ((i=0; i<${#ptbin[@]}-1; i++)); do
ptb=${ptbin[i]}
ptbmax=${ptbin[i+1]}
queue=${queues[i]}

while true; do
	myjobs=$(condor_q taehee | awk '/Total for query:/ {print $4}')
	alljobs=$(condor_q | awk '/Total for query:/ {print $4}')
	if (( myjobs + queue <= MAX_MYJOBS && alljobs + queue <= MAX_ALLJOBS )); then
		break
	fi
echo -n Zzz...
sleep 360
done

if [ "$generation" = "RS" ]; then
JobBatchName="Pt-${ptb}To${ptbmax}_ppbb_\$(Cluster)"
elif [ "$generation" = "FO" ]; then
JobBatchName="Pt-${ptb}To${ptbmax}_MZp-${zpmass}_\$(Cluster)"
fi

condor_submit submit_condor_mg.txt \
-append "arguments = \$(Cluster) \$(Process) $generation $zpmass $ptb $ptbmax $com" \
-append "JobBatchName = $JobBatchName" \
-append "queue $queue"
sleep 60

done
