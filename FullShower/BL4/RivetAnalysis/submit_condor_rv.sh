#!/bin/bash

generation="RS" #RS or FO
com="13TeV" #13TeV or 13p6TeV

JOBTAGS=("Pt-150_ppjj_6370024" "Pt-150_ppjj_6370029")
#JOBTAGS=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140")
#JOBTAGS=("Pt-100_ppjj_6359495" "Pt-100_ppjj_6360141")
#JOBTAGS=("Pt-120_ppjj_6355277" "Pt-120_ppjj_6355538")
JOBTAGS=("Pt-20_ppjj_6393624" "Pt-20_ppjj_6393625" "Pt-20_ppjj_6393626")
JOBTAGS=("Pt-20_MZp-5_6402653")
JOBTAGS=("Pt-20_MZp-20_6402654")
JOBTAGS=("Pt-20_MZp-50_6402656")
JOBTAGS=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521" "Pt-40_ppjj_6358527" "Pt-40_ppjj_6358528")
JOBTAGS=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473")
JOBTAGS=("Pt-150_ppjj_6359496" "Pt-150_ppjj_6360142" "Pt-150_ppjj_6363475" "Pt-150_ppjj_6363476")

ZPMASSES=(50)

cat <<EOT > submit_condor_rv.txt
universe        = vanilla
executable      = rv_condor.sh
arguments       = \$(Cluster) 
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
+SingularityImage = "/cms/ldap_home/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind = "/cms/ldap_home/taehee:/cms/ldap_home/taehee,/cms_scratch/taehee:/cms_scratch/taehee"
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

mkdir -p joblog

for ((i=0; i<${#JOBTAGS[@]}; i++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
    zpmass=${ZPMASSES[m]}
    jobtag=${JOBTAGS[i]}
    JobBatchName="${generation}_MZp-${zpmass}_$jobtag"
    echo "Submitting $queue jobs: $JobBatchName"
    sleep 1
    queue=500

    condor_submit submit_condor_rv.txt \
    -append "arguments = $jobtag \$(Process) $generation $zpmass $com" \
    -append "JobBatchName =$JobBatchName" \
    -append "queue $queue"
done
done
