#!/bin/bash

START=$(date +%s)
LIMIT=$(( START + 4*3600 ))
BASEJOB=20
HIGHJOB=20

for ((n=0; n<=500; n++)); do

    NOW=$(date +%s)

    if (( NOW < LIMIT )); then
        MAXJOBS=$HIGHJOB
    else
        break
        MAXJOBS=$BASEJOB
    fi

    while true; do
        njobs=$(pgrep -f "ft_condor.sh" | wc -l)
        if (( njobs < MAXJOBS )); then
            break
        fi
        sleep 10
    done

    echo "Starting job n=$n  (MAXJOBS=$MAXJOBS)"
    ./ft_condor.sh RS_Full $n Pt-20_ppjj_6393624 8 13TeV > joblog/job.1.$n.out 2>&1 &

done

wait
echo "All jobs done."
