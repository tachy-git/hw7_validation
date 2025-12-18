#!/bin/bash

SAMPLES=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521" "Pt-40_ppjj_6358527" "Pt-40_ppjj_6358528")
SAMPLES=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473")
SAMPLES=("Pt-100_ppjj_6359495" "Pt-100_ppjj_6360141" "Pt-100_ppjj_6363474")
SAMPLES=("Pt-150_ppjj_6359496" "Pt-150_ppjj_6360142" "Pt-150_ppjj_6363475" "Pt-150_ppjj_6363476")
SAMPLES=("Pt-40_ppjj_6367593")
SAMPLES=("Pt-80_ppjj_6367594")
SAMPLES=("Pt-100_ppjj_6367595")
SAMPLES=("Pt-150_ppjj_6367596")
SAMPLES=("Pt-60_ppjj_6355276" "Pt-60_ppjj_6355395" "Pt-60_ppjj_6355537")
#SAMPLES=("Pt-80_ppjj_6359494" "Pt-80_ppjj_6360140" "Pt-80_ppjj_6363472" "Pt-80_ppjj_6363473" "Pt-80_ppjj_6367594")
SAMPLES=("Pt-100_ppjj_6360141" "Pt-100_ppjj_6363474" "Pt-100_ppjj_6367595" "Pt-100_ppjj_6359495")
#SAMPLES=("Pt-80_ppjj_6367594")
#SAMPLES=("Pt-120_ppjj_6355277" "Pt-120_ppjj_6355396" "Pt-120_ppjj_6355538")
SAMPLES=("Pt-120_ppjj_6355396" "Pt-120_ppjj_6355538")
SHOWERS=("RS_Full")
SAMPLES=("Pt-40_ppjj_6358513" "Pt-40_ppjj_6358521")
SAMPLES=("Pt-40_ppjj_6358528")

ZPMASSES=(6 7)

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) \$(Process) $sample $zpmass $coupling
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
stream_output = True
stream_error = True
should_transfer_files = YES
getenv = True
EOT

mkdir -p joblog

for ((i=0; i<${#SAMPLES[@]}; i++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
    zpmass=${ZPMASSES[m]}
    sample=${SAMPLES[i]}
    #shower=${SHOWERS[i]}
    shower="RS_Full"
    echo "Submitting $queue jobs for HW with MG job number $sample with Zprime mass $zpmass, coupling $coupling"
    queue=5000
    condor_submit submit_condor_hw.txt \
    -append "arguments = $shower \$(Process) $sample $zpmass" \
    -append "JobBatchName = ${shower}_MZp-${zpmass}_$sample" \
    -append "queue $queue"
    sleep 1
done
done
