#!/bin/bash

SAMPLES=("Pt-200To210_4767501" "Pt-210To220_4767502" "Pt-220To230_4767503" "Pt-230To250_4767504" "Pt-250To270_4767505" "Pt-270To300_4767506" "Pt-300To400_4767507" "Pt-400To9999_4767508" "Pt-200To210_4767608" "Pt-210To220_4767609" "Pt-220To230_4767610" "Pt-230To250_4767611" "Pt-250To270_4767612" "Pt-270To300_4767613" "Pt-300To400_4767614" "Pt-400To9999_4767615")

SAMPLES=("Pt-140To145_4767530" "Pt-145To150_4767531" "Pt-150To160_4767532" "Pt-160To170_4767533" "Pt-170To180_4767534" "Pt-180To200_4767535" "Pt-200To240_4767536" "Pt-240To300_4767537" "Pt-300To9999_4767538" "Pt-140To145_4767590" "Pt-145To150_4767591" "Pt-150To160_4767592" "Pt-160To170_4767593" "Pt-170To180_4767594" "Pt-180To200_4767595" "Pt-200To240_4767596" "Pt-240To300_4767597" "Pt-300To9999_4767598")

zpmass=50
coupling="0p1"
campaign="RunIISummer20UL16"
# "RunIISummer20UL16" "RunIISummer20UL16APV" "RunIISummer20UL17" "RunIISummer20UL18"

cat <<EOT > submit_condor.jds
universe        = vanilla
executable      = condor.sh
arguments       = \$(Process) \$(sample) \$(campaign)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_alice
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7:latest"
+SingularityBindCVMFS = True
+SingularityBind  = "/cvmfs,/cms,/share,/cms_scratch"
x509userproxy = /tmp/x509up_u556951238
stream_output   = True
stream_error    = True
request_memory = 4GB
EOT

for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
    queue=$(ls /cms_scratch/taehee/HerwigSample/hw_nEvt-100000/MZp-$zpmass/gbb-$coupling/$sample | wc -l)
    echo "Submitting jobs for sample production: $campaign"_"MZp-$zpmass"_"$sample"
    condor_submit submit_condor.jds \
        -append "arguments = \$(Process) $sample $campaign $zpmass $coupling" \
        -append "JobBatchName = "$campaign"_MZp-"$zpmass"_"$sample \
        -append "queue $queue"
done
