#!/bin/bash

SCRAM_ARCH="slc7_amd64_gcc900"
CMSSW="CMSSW_12_2_0_pre3"

export $SCRAM_ARCH
export $CMSSW

source /cvmfs/cms.cern.ch/cmsset_default.sh
cd /cvmfs/cms.cern.ch/${SCRAM_ARCH}/cms/cmssw/${CMSSW}/src/
eval `scramv1 runtime -sh`
cd ~-

WD=$(pwd)

for zp in 20; do
    cd $WD
    yodas=()
    # RS and FO
    labels=("RS_MZp-${zp}" "FO_MZp-${zp}")
    titles=("HW(Z'+SM PS)" "MG(Z'+2J)")
    colors=("blue" "red")
    if [[ $zp -eq 5 ]]; then
        scales=("0.00973783" "1")
    elif [[ $zp -eq 20 ]]; then
        scales=("0.00324592" "1")
    elif [[ $zp -eq 50 ]]; then
        scales=("0.00100112" "1")
    fi
    dir=MZp-${zp}
    if [[ -d $dir ]]; then rm -rf $dir; fi
    mkdir $dir
    cd $dir
    for i in "${!labels[@]}";do
        label="${labels[$i]}"
        yoda="/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/BL4/RivetJB/${label}.yoda"
        style="${styles[$i]}"
        title="${titles[$i]}"
        scale="${scales[$i]}"
        color="${colors[$i]}"
        if [[ ! -f "$yoda" ]];then
            continue
        fi
        echo "plotting $yoda..."
        yodas+=("$yoda:LineStyle=$style:Title=$title:LineWidth=0.05:Scale=$scale:LineColor=$color")
    done
    echo ${yodas[@]}
    rivet-mkhtml --no-weight --no-ratio "${yodas[@]}"
done
