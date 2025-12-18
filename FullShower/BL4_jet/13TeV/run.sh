#!/bin/bash

START=$(date +%s)
LIMIT=$(( START + 4*3600 ))
BASEJOB=15
HIGHJOB=15

for ((n=145; n<=5000; n++)); do

    NOW=$(date +%s)

    if (( NOW < LIMIT )); then
        MAXJOBS=$HIGHJOB
    else
        break
        MAXJOBS=$BASEJOB
    fi

    while true; do
        njobs=$(pgrep -f "hw_condor.sh" | wc -l)
        if (( njobs < MAXJOBS )); then
            break
        fi
        sleep 10
    done

    echo "Starting job n=$n  (MAXJOBS=$MAXJOBS)"
    ./hw_condor.sh RS_Full $n Pt-120_ppjj_6355538 40 > joblog/job.4.$n.out 2>&1 &

done

wait
echo "All jobs done."
