#!/bin/bash

SAMPLES=("Pt-65To67_ppbb_165872" "Pt-67To70_ppbb_165873" "Pt-70To75_ppbb_165874" "Pt-75To80_ppbb_165875" "Pt-80To85_ppbb_165887" "Pt-85To90_ppbb_165888" "Pt-90To100_ppbb_165880" "Pt-100To120_ppbb_165589" "Pt-120To150_ppbb_165882" "Pt-150To9999_ppbb_165883")

SAMPLES=("Pt-65To67_ppbb_56215" "Pt-67To70_ppbb_56216" "Pt-70To75_ppbb_56217" "Pt-75To80_ppbb_56218" "Pt-80To85_ppbb_56219" "Pt-85To90_ppbb_56220" "Pt-90To100_ppbb_56221" "Pt-100To120_ppbb_56222" "Pt-120To150_ppbb_56223" "Pt-150To9999_ppbb_56224" "Pt-80To85_ppbb_58207" "Pt-85To90_ppbb_58208" "Pt-90To95_ppbb_58209" "Pt-95To100_ppbb_58210" "Pt-100To110_ppbb_58211" "Pt-110To120_ppbb_58212" "Pt-120To130_ppbb_58213" "Pt-130To150_ppbb_58214" "Pt-150To200_ppbb_58215" "Pt-200To9999_ppbb_58216" "Pt-130To135_ppbb_86380" "Pt-135To140_ppbb_86381" "Pt-140To145_ppbb_58307" "Pt-145To150_ppbb_58308" "Pt-150To160_ppbb_58717" "Pt-160To170_ppbb_58718" "Pt-170To180_ppbb_61924" "Pt-180To200_ppbb_61925" "Pt-200To240_ppbb_85104" "Pt-240To300_ppbb_85155" "Pt-300To9999_ppbb_85689" "Pt-200To210_ppbb_79089" "Pt-210To220_ppbb_79176" "Pt-220To230_ppbb_79177" "Pt-230To250_ppbb_82510" "Pt-250To270_ppbb_79178" "Pt-270To300_ppbb_79179" "Pt-300To400_ppbb_83218" "Pt-400To9999_ppbb_79180")


ZPMASSES=(25 30 35 40 45 50 55 60 65 70)
coupling="0p1"
CAMPAIGNS=("Run3Summer22" "Run3Summer22EE") # "Run3Summer23" "Run3Summer23BPix")

#SAMPLES=("Pt-65To67_ppbb_56215")
#CAMPAIGNS=("Run3Summer22" "Run3Summer22EE" "Run3Summer23")
#ZPMASSES=(12)

PROXY=$(voms-proxy-info -path)
cat <<EOT > submit_condor_Run3.jds
universe        = vanilla
executable      = condor_Run3.sh
arguments       = \$(Process) \$(sample) \$(campaign)
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.\$(Cluster).\$(Process).log
accounting_group = group_cms
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el8:latest"
+SingularityBindCVMFS = True
+SingularityBind = "/cvmfs,/cms,/share,/cms_scratch,/tmp,/etc/grid-security"
x509userproxy = /tmp/x509up_u556951238
stream_output   = True
stream_error    = True
request_memory = 4GB
EOT

mkdir -p joblog
MAX_ALLJOBS=19000
MAX_MYJOBS=4000

for ((c=0; c<${#CAMPAIGNS[@]}; c++)); do
for ((m=0; m<${#ZPMASSES[@]}; m++)); do
for ((i=0; i<${#SAMPLES[@]}; i++)); do
    campaign=${CAMPAIGNS[c]}
    zpmass=${ZPMASSES[m]}
    sample=${SAMPLES[i]}
    dir="/cms_scratch/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000/MZp-$zpmass/$sample/"
    if [[ ! -d "$dir" ]]; then
      continue
    fi
    queue=$(ls -d "$dir"/* 2>/dev/null | wc -l)
    #queue=${QUEUES[i]}
    if (( queue < 1 )); then
      continue
    fi
    tmp="/cms_scratch/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000/$campaign/MZp-$zpmass/gbb-$coupling/$sample/"
    if find "$tmp" -maxdepth 1 -type f -name 'NanoAOD_*.root' -print -quit | grep -q .; then
      continue
    fi


    while true; do
      myjobs=$(condor_q taehee | awk '/Total for query:/ {print $4}')
      alljobs=$(condor_q | awk '/Total for query:/ {print $4}')
      if (( myjobs + queue <= MAX_MYJOBS && alljobs + queue <= MAX_ALLJOBS )); then
        break
      fi
      echo -n Zzz...
      sleep 360
    done

    echo "Submitting jobs for sample production: $campaign"_"MZp-$zpmass"_"$sample"
    condor_submit submit_condor_Run3.jds \
        -append "arguments = \$(Process) $sample $campaign $zpmass $coupling" \
        -append "JobBatchName = "$campaign"_MZp-"$zpmass"_"$sample \
        -append "queue $queue"
done
done
done








