#!/bin/bash

process=${1}
sample=${2}
campaign=${3}
zpmass=${4}
coupling=${5}

if [ "$campaign" == "RunIISummer20UL16" ]; then
	CMSSW=("CMSSW_10_6_19_patch3" "CMSSW_10_6_17_patch1" "CMSSW_10_6_17_patch1" "CMSSW_8_0_36_UL_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_6_25")
elif [ "$campaign" == "RunIISummer20UL16APV" ]; then
	CMSSW=("CMSSW_10_6_19_patch3" "CMSSW_10_6_17_patch1" "CMSSW_10_6_17_patch1" "CMSSW_8_0_36_UL_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_6_25")
elif [ "$campaign" == "RunIISummer20UL17" ]; then
	CMSSW=("CMSSW_10_6_19_patch3" "CMSSW_10_6_17_patch1" "CMSSW_10_6_17_patch1" "CMSSW_9_4_14_UL_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_6_20")
elif [ "$campaign" == "RunIISummer20UL18" ]; then
	CMSSW=("CMSSW_10_6_19_patch3" "CMSSW_10_6_17_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_2_16_UL" "CMSSW_10_6_17_patch1" "CMSSW_10_6_20")
else
	echo "Wrong Campaign: $campaign"
	echo "You should select among RunIISummer20UL16 RunIISummer20UL16APV RunIISummer20UL17 RunIISummer20UL18"
	exit 1
fi
RUNS=("GEN" "SIM" "DIGIPremix" "HLT" "RECO" "MiniAODv2")

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700

WD="/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/13TeV/SampleGeneration"
basedir_="\/cms_scratch\/taehee\/HerwigSample\/samples_nEvt-100000"
basedir="/cms_scratch/taehee/HerwigSample/samples_nEvt-100000"
outputdir_="${campaign}\/MZp-${zpmass}\/gbb-${coupling}\/${sample}"
outputdir="${campaign}/MZp-${zpmass}/gbb-${coupling}/${sample}"
mkdir -p ${basedir}/${outputdir}
mkdir -p ${WD}/tmp/${outputdir}
mkdir -p /cms_scratch/taehee/HerwigSample/samples_nEvt-100000/${outputdir}

runStep=-1
for ((i = 0; i < ${#RUNS[@]}; i++)); do
	output=${RUNS[$i]}
	outputFile="${basedir}/${outputdir}/${output}_${process}.root"
	if [[ $output != "GEN" ]]; then
		input=${RUNS[$((i-1))]}
		inputFile="${basedir}/${outputdir}/${input}_${process}.root"
	fi

	if [[ -f "${outputFile}" ]]; then
		logFile="${WD}/tmp/${outputdir}/${output}_${process}.log"
		if grep -q "MessageLogger Summary" "${logFile}" && ! grep -q "Begin Fatal Exception" "${logFile}"; then
			echo "${outputFile}: Exists... pass the process"
			runStep=$i
			if [[ $output != "GEN" ]]; then
				rm -f ${inputFile}
			fi
		else
			rm -f "${outputFile}"
			echo "Remove ${outputFile} since the error has detected."
		fi
	fi

done

for ((i = runStep + 1; i < ${#RUNS[@]}; i++)); do
    output=${RUNS[$i]}
	outputFile="${basedir}/${outputdir}/${output}_${process}.root"
    echo "Running ${outputdir}/${output}_${process}..."
    if [[ $output != "GEN" ]]; then
        input=${RUNS[$((i-1))]}
		inputFile="${basedir}/${outputdir}/${input}_${process}.root"
    fi

	cd ${WD}
    sed -e "s/__OUTPUT__/${basedir_}\/${outputdir_}\/${output}_${process}/g" "files_cfg/${campaign}${output}_cfg.py" > "tmp/${outputdir}/${output}_${process}.py"
    if [[ $output == "GEN" ]]; then
        if [ ! -f "/cms_scratch/taehee/HerwigSample/hw_nEvt-100000/MZp-${zpmass}/gbb-${coupling}/${sample}/${process}/LHC.hepmc" ];then
            echo "${outputdir}/${output}_${process}: LHC.hepmc does not exist... exit"
            exit 1
        fi
        sed -i "s/__INPUT__/\/cms_scratch\/taehee\/HerwigSample\/hw_nEvt-100000\/MZp-${zpmass}\/gbb-${coupling}\/${sample}\/${process}\/LHC/g" "tmp/${outputdir}/${output}_${process}.py"
        sed -i "s/__RANDOM__/${process}/g" "tmp/${outputdir}/${output}_${process}.py"
    else
        if [ ! -f "${inputFile}" ]; then
            echo "${inputFile}: no input files... exit"
            exit
        fi
        sed -i "s/__INPUT__/${basedir_}\/${outputdir_}\/${input}_${process}/g" "tmp/${outputdir}/${output}_${process}.py"
    fi

    cd ${WD}/CMSSW/${CMSSW[$i]}/src
    eval `scram runtime -sh`
    scram b

	cd ${WD}
	logFile="${WD}/tmp/${outputdir}/${output}_${process}.log"
    cmsRun ${WD}/tmp/${outputdir}/${output}_${process}.py &> ${logFile}
	echo "Finished running ${outputdir}/${output}_${process}"

	if grep -q "MessageLogger Summary" "${logFile}" && ! grep -q "Begin Fatal Exception" "${logFile}"; then
		echo "${outputFile}: Exists... pass the process"
		if [[ $output != "GEN" ]]; then
			rm -f ${inputFile}
		fi
	else
		rm -f "${outputFile}"
		echo "Remove ${outputFile} since the error has detected."
	fi

done
