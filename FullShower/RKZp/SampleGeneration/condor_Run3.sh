#!/usr/bin/env bash

set -u

process="${1:?missing process}"
sample="${2:?missing sample}"
campaign="${3:?missing campaign}"
zpmass="${4:?missing zpmass}"
coupling="${5:?missing coupling}"

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el8_amd64_gcc12

WD="/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration"
basedir="/cms_scratch/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000"
herwigdir="/cms_scratch/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000/MZp-${zpmass}/${sample}/${process}"
outputdir="${campaign}/MZp-${zpmass}/gbb-${coupling}/${sample}"
tmpdir="${WD}/tmp/${outputdir}"

RUNS=("GEN" "SIM" "DRPremix1" "DRPremix2" "MiniAODv3" "NanoAOD")

die() {
    echo "ERROR: $*" >&2
    exit 1
}

get_cmssw_list() {
    case "$1" in
        Run3Summer22|Run3Summer22EE)
            echo "CMSSW_12_4_11_patch3" "CMSSW_12_4_11_patch3" "CMSSW_12_4_11_patch3" "CMSSW_12_4_11_patch3" "CMSSW_12_4_11_patch3" "CMSSW_12_6_0"
            ;;
        Run3Summer23|Run3Summer23BPix)
            echo "CMSSW_13_0_14" "CMSSW_13_0_14" "CMSSW_13_0_14" "CMSSW_13_0_14" "CMSSW_13_0_14" "CMSSW_13_0_14"
            ;;
        *)
            die "Wrong Campaign: $1. Choose among Run3Summer22 Run3Summer22EE Run3Summer23 Run3Summer23BPix"
            ;;
    esac
}

read -r -a CMSSW <<< "$(get_cmssw_list "$campaign")"

mkdir -p "${basedir}/${outputdir}"
mkdir -p "${tmpdir}"

is_log_success() {
    local logfile="$1"
    [[ -f "$logfile" ]] &&
    (
        grep -q "MessageLogger Summary" "$logfile" ||
        grep -q "Closed" "$logfile"
    ) &&
    ! grep -q "Begin Fatal Exception" "$logfile"
}

prepare_cfg() {
    local step="$1"
    local cfg_template="${WD}/cfgFilesRun3/${campaign}${step}_cfg.py"
    local cfg_out="${tmpdir}/${step}_${process}.py"
    local output_base="${basedir}/${outputdir}/${step}_${process}"

    [[ -f "$cfg_template" ]] || die "Missing cfg template: $cfg_template"

    sed "s|__OUTPUT__|${output_base}|g" "$cfg_template" > "$cfg_out"

    if [[ "$step" == "GEN" ]]; then
        [[ -f "${herwigdir}/LHC.hepmc" ]] || die "${herwigdir}/LHC.hepmc does not exist"
        [[ -f "${herwigdir}/LHC.log" ]] || die "${herwigdir}/LHC.log does not exist"
        grep -q "Total:" "${herwigdir}/LHC.log" || die "Herwig run did not complete successfully"

        sed -i "s|__INPUT__|${herwigdir}/LHC|g" "$cfg_out"
        sed -i "s|__RANDOM__|${process}|g" "$cfg_out"
    else
        local prev_step="$2"
        local input_base="${basedir}/${outputdir}/${prev_step}_${process}"
        [[ -f "${input_base}.root" ]] || die "${input_base}.root does not exist"
        sed -i "s|__INPUT__|${input_base}|g" "$cfg_out"
    fi
}

run_cms() {
    local step="$1"
    local idx="$2"
    local cfg="${tmpdir}/${step}_${process}.py"
    local logfile="${tmpdir}/${step}_${process}.log"
    local cmssw_src="${WD}/CMSSW/${CMSSW[$idx]}/src"

    [[ -d "$cmssw_src" ]] || die "Missing CMSSW area: $cmssw_src"

    cd "$cmssw_src" || die "Failed to cd to $cmssw_src"
    eval "$(scram runtime -sh)"

    cd "$WD" || die "Failed to cd to $WD"

    if [[ "$step" == "DIGIPremix1" ]]; then
        local trial=0
        while true; do
            cmsRun "$cfg" &> "$logfile"
            local status=$?

            if [[ $status -eq 0 ]] && ! grep -q "Disabled source" "$logfile"; then
                break
            fi

            if grep -q "Disabled source" "$logfile"; then
                ((trial++))
                echo "Failed to fetch PU files... retry ${trial}"
                (( trial < 3 )) || die "DIGIPremix failed after several retries"
            else
                die "cmsRun failed for ${step}. See ${logfile}"
            fi
        done
    else
        cmsRun "$cfg" &> "$logfile"
        local status=$?
        [[ $status -eq 0 ]] || die "cmsRun failed for ${step}. See ${logfile}"
    fi
}

runStep=-1

for ((i=0; i<${#RUNS[@]}; i++)); do
    step="${RUNS[$i]}"
    outputFile="${basedir}/${outputdir}/${step}_${process}.root"
    logFile="${tmpdir}/${step}_${process}.log"

    if [[ -f "$outputFile" ]] && is_log_success "$logFile"; then
        echo "${outputFile}: exists and looks good"
        runStep=$i

        if (( i > 0 )); then
          for ((j=0; j<i; j++)); do
            prev="${RUNS[$((j))]}"
            prevFile="${basedir}/${outputdir}/${prev}_${process}.root"
            #if [[ -f "$prevFile" ]]; then
              #echo "Removing previous step file: $prevFile"
              #rm -f "$prevFile"
            #fi
          done
        fi
    fi
done

for ((i=runStep+1; i<${#RUNS[@]}; i++)); do
    step="${RUNS[$i]}"
    echo "Running ${outputdir}/${step}_${process}..."

    if [[ "$step" == "GEN" ]]; then
        prepare_cfg "$step"
    else
        prev="${RUNS[$((i-1))]}"
        prepare_cfg "$step" "$prev"
    fi

    run_cms "$step" "$i"

    outputFile="${basedir}/${outputdir}/${step}_${process}.root"
    logFile="${tmpdir}/${step}_${process}.log"

    if [[ -f "$outputFile" ]] && is_log_success "$logFile"; then
        echo "${outputFile}: success"
        if (( i > 0 )); then
            prev="${RUNS[$((i-1))]}"
            if [[ "$prev" != "MiniAODv3" ]]; then
              rm -f "${basedir}/${outputdir}/${prev}_${process}.root"
            fi
        fi
    else
        rm -f "$outputFile"
        die "Step ${step} failed validation. Removed ${outputFile}"
    fi
done
