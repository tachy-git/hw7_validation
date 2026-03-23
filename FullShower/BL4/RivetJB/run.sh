#!/bin/bash

script="rivet.sh"
MAXJOBS=17

for ((n=0; n<=500; n++)); do

  while (( $(jobs -pr | wc -l) >= MAXJOBS )); do
    sleep 5
  done
  echo "Starting job n=$n  (MAXJOBS=$MAXJOBS)"
  ./$script Pt-20_ppjj_6433404  $n RS_One 50 13TeV > joblog/job.1.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6433405   $n RS_One 50 13TeV > joblog/job.2.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6433406  $n RS_One 50 13TeV > joblog/job.3.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6443427  $n RS_One 50 13TeV > joblog/job.4.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6443428  $n RS_One 50 13TeV > joblog/job.5.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6443429  $n RS_One 50 13TeV > joblog/job.6.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447538  $n RS_One 50 13TeV > joblog/job.7.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447539  $n RS_One 50 13TeV > joblog/job.8.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447540  $n RS_One 50 13TeV > joblog/job.9.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447601  $n RS_One 50 13TeV > joblog/job.10.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447602  $n RS_One 50 13TeV > joblog/job.11.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447603  $n RS_One 50 13TeV > joblog/job.12.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447659  $n RS_One 50 13TeV > joblog/job.13.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447660  $n RS_One 50 13TeV > joblog/job.14.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6447661  $n RS_One 50 13TeV > joblog/job.15.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448758  $n RS_One 50 13TeV > joblog/job.16.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448759  $n RS_One 50 13TeV > joblog/job.17.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448760  $n RS_One 50 13TeV > joblog/job.18.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448762  $n RS_One 50 13TeV > joblog/job.19.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448763  $n RS_One 50 13TeV > joblog/job.20.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6448764  $n RS_One 50 13TeV > joblog/job.21.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449017  $n RS_One 50 13TeV > joblog/job.22.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449018  $n RS_One 50 13TeV > joblog/job.23.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449019  $n RS_One 50 13TeV > joblog/job.24.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449021  $n RS_One 50 13TeV > joblog/job.25.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449022  $n RS_One 50 13TeV > joblog/job.26.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449023  $n RS_One 50 13TeV > joblog/job.27.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449024  $n RS_One 50 13TeV > joblog/job.28.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449025  $n RS_One 50 13TeV > joblog/job.29.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449026  $n RS_One 50 13TeV > joblog/job.30.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449120  $n RS_One 50 13TeV > joblog/job.31.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449121  $n RS_One 50 13TeV > joblog/job.32.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449122  $n RS_One 50 13TeV > joblog/job.33.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449123  $n RS_One 50 13TeV > joblog/job.32.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449124  $n RS_One 50 13TeV > joblog/job.33.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449125  $n RS_One 50 13TeV > joblog/job.34.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449126  $n RS_One 50 13TeV > joblog/job.35.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449127  $n RS_One 50 13TeV > joblog/job.36.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449128  $n RS_One 50 13TeV > joblog/job.37.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449328  $n RS_One 50 13TeV > joblog/job.38.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449329  $n RS_One 50 13TeV > joblog/job.39.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449330  $n RS_One 50 13TeV > joblog/job.40.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449331  $n RS_One 50 13TeV > joblog/job.41.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449332  $n RS_One 50 13TeV > joblog/job.42.$n.out 2>&1 &
  ./$script Pt-20_ppjj_6449333  $n RS_One 50 13TeV > joblog/job.43.$n.out 2>&1 &

done

wait
echo "All jobs done."
