#!/bin/bash

SAMPLES=("Pt-65To67_ppbb_34671")
SAMPLES=("Pt-67To70_ppbb_34672" "Pt-70To75_ppbb_34673" "Pt-75To80_ppbb_34674" "Pt-80To85_ppbb_34675" "Pt-85To90_ppbb_34676" "Pt-90To100_ppbb_34677" "Pt-100To120_ppbb_34678" "Pt-120To150_ppbb_34679" "Pt-150To9999_ppbb_34680")

zpmass=12
coupling="0p1"
CAMPAIGNS=("RunIISummer20UL16" "RunIISummer20UL16APV" "RunIISummer20UL17" "RunIISummer20UL18")

cat <<EOT > submit_condor.jds
universe        = vanilla
executable      = condor.sh
arguments       = \$(Process) \$(sample) \$(campaign)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7:latest"
+SingularityBindCVMFS = True
+SingularityBind  = "/cvmfs,/cms,/share,/cms_scratch"
x509userproxy = /tmp/x509up_u556951238
stream_output   = True
stream_error    = True
request_memory = 4GB
EOT

mkdir -p joblog
for ((c=0; c<${#CAMPAIGNS[@]}; c++)); do
for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
    campaign=${CAMPAIGNS[c]}
    queue=$(ls -d /cms_scratch/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000/MZp-$zpmass/$sample/* | wc -l)
    echo "Submitting jobs for sample production: $campaign"_"MZp-$zpmass"_"$sample"
    condor_submit submit_condor.jds \
        -append "arguments = \$(Process) $sample $campaign $zpmass $coupling" \
        -append "JobBatchName = "$campaign"_MZp-"$zpmass"_"$sample \
        -append "queue $queue"
done
done
