#!/bin/bash

#SAMPLES=("Pt-130To135_1132246" "Pt-135To140_1132294" "Pt-140To150_1132295" "Pt-150To160_1132248" "Pt-160To170_1132249" "Pt-170To200_1132250" "Pt-200To9999_1132251")
#SAMPLES=("Pt-200To210_1132252" "Pt-210To220_1132253" "Pt-220To230_1132254" "Pt-230To250_1132255" "Pt-250To280_1132256" "Pt-280To350_1132257" "Pt-350To9999_1132258")
#SAMPLES=("Pt-230To240_1132296" "Pt-240To250_1132297" "Pt-250To270_1132298" "Pt-270To300_1132299" "Pt-300To350_1132300" "Pt-350To9999_1132258")
SAMPLES=("Pt-130To135_345510" "Pt-135To140_345511" "Pt-140To150_345512" "Pt-150To160_345513" "Pt-160To170_345514" "Pt-170To180_345515" "Pt-180To200_345516" "Pt-200To250_345517" "Pt-250To9999_345518")
SAMPLES=("Pt-230To240_345524" "Pt-240To250_345525" "Pt-250To260_345526" "Pt-260To280_1132311" "Pt-280To300_1132312" "Pt-300To350_1132313" "Pt-350To400_1132314" "Pt-400To9999_1132315")

zpmass=55
coupling="0.1"

cat <<EOT > submit_condor_hw.txt
universe        = vanilla
executable      = hw_condor.sh
arguments       = \$(Cluster) \$(Process) $sample $zpmass $coupling
output          = joblog/job.\$(Cluster).\$(Process).out
error           = joblog/job.\$(Cluster).\$(Process).err
log             = joblog/job.log
+SingularityImage = "/u/user/taehee/osgvo-ubuntu-20.04_latest.sif"
+SingularityBind  = "/u/user/taehee/HerwigWD:/u/user/taehee/HerwigWD"
stream_output = True
stream_error = True
EOT

for ((i=0; i<${#SAMPLES[@]}; i++)); do
    sample=${SAMPLES[i]}
    queue=$(ls /pnfs/knu.ac.kr/data/cms/store/user/taehee/HerwigSample/mg/MZp-$zpmass/$sample | wc -l)
	echo "Submitting job for HW with MG job number $sample with Zprime mass $zpmass, coupling $coupling"
	condor_submit submit_condor_hw.txt \
	-append "arguments = \$(Cluster) \$(Process) $sample $zpmass $coupling" \
	-append "JobBatchName = MZp-"$zpmass"_"$sample \
	-append "queue $queue"
done
