#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  resubmit_failed.sh [--mode fullchain|miniaod|nanoaod] [--campaign-group 2022|2022EE|2023|2023BPix] [--campaign <campaign>] [--version v1|v2] [--dry-run] <mass> [<mass> ...] [-- <crab resubmit options>]

Examples:
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod 12 20 25
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022 12
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022EE 12
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023 12
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023BPix 12
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign Run3Summer23 65
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022 --version v1 65
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode nanoaod --dry-run 12
  ./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode fullchain 12 -- --maxmemory 5000

Run after setting up CMSSW and crab-setup.sh.
Each task is resubmitted only when failed jobs are more than 5% of total jobs.
EOF
}

dry_run=0
mode="fullchain"
campaign_group="all"
campaign_filter="all"
version_tag="v2"
masses=()
extra_args=()
failure_threshold_percent=5

while (($#)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        --mode)
            mode="${2:-}"
            shift 2
            ;;
        --campaign-group|--group)
            campaign_group="${2:-}"
            shift 2
            ;;
        --campaign)
            campaign_filter="${2:-}"
            shift 2
            ;;
        --version)
            version_tag="${2:-}"
            shift 2
            ;;
        --)
            shift
            extra_args=("$@")
            break
            ;;
        *)
            masses+=("$1")
            shift
            ;;
    esac
done

if ((${#masses[@]} == 0)); then
    usage >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${mode}" in
    fullchain)
        base_dir="$(dirname "${script_dir}")/crabsub_run3_fullchain_pdfErr_${version_tag}"
        request_label="Run3FullChain_pdfErr"
        generator="make_run3_tasks.py"
        ;;
    miniaod)
        base_dir="$(dirname "${script_dir}")/crabsub_run3_miniaod_pdfErr_${version_tag}"
        request_label="Run3MiniAOD_pdfErr"
        generator="make_run3_miniaod_tasks.py"
        ;;
    nanoaod)
        base_dir="$(dirname "${script_dir}")/crabsub_run3_nanoaod_pdfErr_${version_tag}"
        request_label="Run3NanoAOD_pdfErr"
        generator="make_run3_nanoaod_tasks.py"
        ;;
    *)
        echo "ERROR: unknown mode '${mode}'" >&2
        usage >&2
        exit 2
        ;;
esac

case "${version_tag}" in
    v1|v2) ;;
    *)
        echo "ERROR: unknown version '${version_tag}'" >&2
        echo "Use --version v1 or --version v2" >&2
        exit 2
        ;;
esac

campaign_in_group() {
    local campaign="$1"
    case "${campaign_group}" in
        all)
            return 0
            ;;
        2022)
            [[ "${campaign}" == "Run3Summer22" ]]
            ;;
        2022EE)
            [[ "${campaign}" == "Run3Summer22EE" ]]
            ;;
        2023)
            [[ "${campaign}" == "Run3Summer23" ]]
            ;;
        2023BPix)
            [[ "${campaign}" == "Run3Summer23BPix" ]]
            ;;
        *)
            echo "ERROR: unknown campaign group '${campaign_group}'" >&2
            echo "Use --campaign-group 2022, 2022EE, 2023, or 2023BPix" >&2
            exit 2
            ;;
    esac
}

campaign_selected() {
    local campaign="$1"
    [[ "${campaign_filter}" == "all" || "${campaign}" == "${campaign_filter}" ]]
}

clean_name() {
    local value="$1"
    value="${value//-/_}"
    value="${value//./_}"
    echo "${value}"
}

for mass in "${masses[@]}"; do
    mass_tag="MZp${mass}"
    mass_dir="${base_dir}/${mass_tag}"
    summary="${mass_dir}/task_summary.txt"

    if [[ ! -f "${summary}" ]]; then
        echo "ERROR: missing ${summary}" >&2
        echo "Generate it first: python3 crabsub_run3_fullchain_pdfErr/${generator} ${mass}" >&2
        exit 1
    fi

    while read -r campaign sample count relpath; do
        [[ -n "${campaign:-}" ]] || continue
        campaign_in_group "${campaign}" || continue
        campaign_selected "${campaign}" || continue
        clean_sample="$(clean_name "${sample}")"
        project="${mass_dir}/${relpath}/crabsub_projects/crab_RKZp_${campaign}_${request_label}_${mass_tag}_${clean_sample}_${version_tag}"

        if [[ ! -d "${project}" ]]; then
            echo "WARNING: skipping missing project: ${project}" >&2
            continue
        fi

        echo "Checking failed-job fraction: ${campaign} ${mass_tag} ${sample}"
        if ! status_output="$(crab status -d "${project}" 2>&1)"; then
            echo "WARNING: crab status failed for ${project}; skipping resubmit" >&2
            printf '%s\n' "${status_output}" >&2
            continue
        fi

        echo "Finished job summary:"
        printf '%s\n' "${status_output}" | awk -v fallback_total="${count}" '
            /Jobs status:/ {
                status = $3
                if (match($0, /\([[:space:]]*[0-9]+\/[0-9]+\)/)) {
                    counts = substr($0, RSTART, RLENGTH)
                    gsub(/[()[:space:]]/, "", counts)
                    split(counts, parts, "/")
                    state_count = parts[1] + 0
                    total = parts[2] + 0
                    if (status == "finished") {
                        finished = state_count
                        have_finished = 1
                    } else {
                        non_finished += state_count
                    }
                }
            }
            END {
                if (total <= 0) {
                    total = fallback_total + 0
                }
                if (!have_finished) {
                    finished = total - non_finished
                    if (finished < 0) {
                        finished = 0
                    }
                }
                percent = (total > 0) ? 100.0 * finished / total : 0
                printf "  finished         %d/%d (%.2f%%)\n", finished, total, percent
            }
        '

        failed_line="$(printf '%s\n' "${status_output}" | awk '/Jobs status:[[:space:]]+failed/ {print; exit}')"
        if [[ -n "${failed_line}" ]]; then
            failed_counts="$(printf '%s\n' "${failed_line}" | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\)\/\([0-9][0-9]*\)).*/\1 \2/p')"
            if [[ -z "${failed_counts}" ]]; then
                echo "WARNING: could not parse failed-job count from status line; skipping: ${failed_line}" >&2
                continue
            fi
            read -r failed_jobs total_jobs <<< "${failed_counts}"
        else
            failed_jobs=0
            total_jobs="${count}"
        fi

        if ((total_jobs <= 0)); then
            echo "WARNING: total job count is ${total_jobs}; skipping ${project}" >&2
            continue
        fi

        failed_times_100=$((failed_jobs * 100))
        threshold_times_total=$((failure_threshold_percent * total_jobs))
        failed_percent_text="$(awk -v failed="${failed_jobs}" -v total="${total_jobs}" 'BEGIN {printf "%.2f", 100.0 * failed / total}')"

        if ((failed_times_100 <= threshold_times_total)); then
            echo "Skipping ${mode}: ${campaign} ${mass_tag} ${sample} has ${failed_jobs}/${total_jobs} failed jobs (${failed_percent_text}%), not more than ${failure_threshold_percent}%"
            continue
        fi

        cmd=(crab resubmit -d "${project}")
        if ((${#extra_args[@]})); then
            cmd+=("${extra_args[@]}")
        fi

        echo "Resubmitting failed ${mode} jobs: ${campaign} ${mass_tag} ${sample}; ${failed_jobs}/${total_jobs} failed (${failed_percent_text}%)"
        if ((dry_run)); then
            printf '  '
            printf '%q ' "${cmd[@]}"
            printf '\n'
        else
            "${cmd[@]}"
        fi
    done < "${summary}"
done
