#!/usr/bin/env python3
import re
import shutil
import sys
from pathlib import Path


WD = Path("/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration")
INPUT_ROOT_LOCAL = Path("/xrd/store/user/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000_pdfErr")
INPUT_ROOT_XRD = "root://cms-xrdr.sdfarm.kr:1095//xrd/store/user/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000_pdfErr"
OUTPUT_ROOT = "/store/user/taehee/HerwigSample/RKZp_13TeV/RS/samples_nEvt-100000_pdfErr/MiniAODv2"
VERSION_TAG = "v3"
INPUT_BASE_LOCAL = None
INPUT_BASE_XRD = None
OUTPUT_BASE = None
OUTDIR = None
ZPMASS_TAG = None
CAMPAIGNS = [
    "RunIISummer20UL16",
    "RunIISummer20UL16APV",
    "RunIISummer20UL17",
    "RunIISummer20UL18",
]
STEPS = ["GEN", "SIM", "DIGIPremix", "HLT", "RECO", "MiniAODv2"]

CMSSW = {
    "RunIISummer20UL16": {
        "GEN": ("CMSSW_10_6_19_patch3", "slc7_amd64_gcc700"),
        "SIM": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "DIGIPremix": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "HLT": ("CMSSW_8_0_36_UL_patch1", "slc7_amd64_gcc530"),
        "RECO": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "MiniAODv2": ("CMSSW_10_6_25", "slc7_amd64_gcc700"),
    },
    "RunIISummer20UL16APV": {
        "GEN": ("CMSSW_10_6_19_patch3", "slc7_amd64_gcc700"),
        "SIM": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "DIGIPremix": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "HLT": ("CMSSW_8_0_36_UL_patch1", "slc7_amd64_gcc530"),
        "RECO": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "MiniAODv2": ("CMSSW_10_6_25", "slc7_amd64_gcc700"),
    },
    "RunIISummer20UL17": {
        "GEN": ("CMSSW_10_6_19_patch3", "slc7_amd64_gcc700"),
        "SIM": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "DIGIPremix": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "HLT": ("CMSSW_9_4_14_UL_patch1", "slc7_amd64_gcc630"),
        "RECO": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "MiniAODv2": ("CMSSW_10_6_20", "slc7_amd64_gcc700"),
    },
    "RunIISummer20UL18": {
        "GEN": ("CMSSW_10_6_19_patch3", "slc7_amd64_gcc700"),
        "SIM": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "DIGIPremix": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "HLT": ("CMSSW_10_2_16_UL", "slc7_amd64_gcc700"),
        "RECO": ("CMSSW_10_6_17_patch1", "slc7_amd64_gcc700"),
        "MiniAODv2": ("CMSSW_10_6_20", "slc7_amd64_gcc700"),
    },
}


def completed_processes(sample_dir):
    processes = []
    for proc_dir in sample_dir.iterdir():
        if not proc_dir.is_dir() or not proc_dir.name.isdigit():
            continue
        hepmc = proc_dir / "LHC.hepmc"
        log = proc_dir / "LHC.log"
        if not hepmc.is_file() or not log.is_file():
            continue
        if "Total:" not in log.read_text(errors="ignore"):
            continue
        processes.append(int(proc_dir.name))
    return sorted(processes)


def clean_name(value):
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def configure_zpmass(zpmass):
    global INPUT_BASE_LOCAL, INPUT_BASE_XRD, OUTPUT_BASE, OUTDIR, ZPMASS_TAG

    zpmass_dir = f"MZp-{zpmass}"
    ZPMASS_TAG = f"MZp{zpmass}"
    INPUT_BASE_LOCAL = INPUT_ROOT_LOCAL / zpmass_dir
    INPUT_BASE_XRD = f"{INPUT_ROOT_XRD}/{zpmass_dir}"
    OUTPUT_BASE = f"{OUTPUT_ROOT}/{zpmass_dir}"
    OUTDIR = WD / f"crabsub_fullchain_pdfErr_{VERSION_TAG}" / ZPMASS_TAG


def make_crab_pset(campaign, task_dir):
    text = (WD / "files_cfg" / f"{campaign}GEN_cfg.py").read_text()
    text = text.replace("__INPUT__", "LHC")
    text = text.replace("__OUTPUT__", "output")
    text = text.replace("__RANDOM__", "1")
    (task_dir / f"{campaign}GEN_crab_cfg.py").write_text(text)


def make_script(campaign, sample, task_dir):
    cmssw_lines = []
    for step in STEPS:
        version, arch = CMSSW[campaign][step]
        cmssw_lines.append(f'    "{step}:{version}:{arch}"')

    step_lines = []
    for step in STEPS:
        step_lines.append(f'    "{step}:{campaign}{step}_template_cfg.py:{campaign}{step}_cfg.py",')

    script = f"""#!/usr/bin/env bash
set -euo pipefail

sample="{sample}"
input_base="{INPUT_BASE_XRD}"
max_events="${{FULLCHAIN_MAX_EVENTS:--1}}"
workdir="$(pwd)"
cmssw_base="${{workdir}}/fullchain_cmssw"

mapfile -t process_ids < process_manifest.txt
job_number="${{1:-1}}"
manifest_index=$((job_number - 1))

if (( manifest_index < 0 || manifest_index >= ${{#process_ids[@]}} )); then
    echo "ERROR: CRAB job ${{job_number}} has no manifest entry" >&2
    exit 1
fi

process_id="${{process_ids[$manifest_index]}}"
input_dir="${{input_base}}/${{sample}}/${{process_id}}"
input_pfn="${{input_dir}}/LHC.hepmc"
input_log_pfn="${{input_dir}}/LHC.log"
final_output="output.root"

echo "CRAB job ${{job_number}} maps to Herwig process ${{process_id}}"
echo "Herwig process ${{process_id}} was prevalidated from local LHC.log before submission"

echo "Copying HEPMC input from ${{input_pfn}}"
xrdcp -f "${{input_pfn}}" LHC.hepmc
ls -lh LHC.hepmc

python3 - "${{max_events}}" "${{process_id}}" "${{final_output}}" <<'PY'
import re
import sys
from pathlib import Path

max_events, process_id, final_output = sys.argv[1:4]
steps = [
{chr(10).join(step_lines)}
]

for item in steps:
    step, template, cfg = item.split(":")
    if step == "GEN":
        input_base = "LHC"
        output_base = "GEN"
    elif step == "MiniAODv2":
        input_base = "RECO"
        output_base = final_output[:-5]
    else:
        prev = steps[steps.index(item) - 1].split(":")[0]
        input_base = prev
        output_base = step

    text = Path(template).read_text()
    text = text.replace("__INPUT__", input_base)
    text = text.replace("__OUTPUT__", output_base)
    text = text.replace("__RANDOM__", process_id)
    text = re.sub(
        r"input\\s*=\\s*cms\\.untracked\\.int32\\(-1\\)",
        "input = cms.untracked.int32(%s)" % max_events,
        text,
        count=1,
    )
    Path(cfg).write_text(text)
    print("Prepared %s -> %s" % (step, cfg))
PY

setup_cmssw() {{
    local version="$1"
    local scram_arch_value="$2"

    source /cvmfs/cms.cern.ch/cmsset_default.sh
    export SCRAM_ARCH="${{scram_arch_value}}"
    mkdir -p "${{cmssw_base}}"

    if [[ ! -d "${{cmssw_base}}/${{version}}/src" ]]; then
        echo "Creating ${{version}} with ${{SCRAM_ARCH}}"
        cd "${{cmssw_base}}"
        scram project CMSSW "${{version}}"
    fi

    cd "${{cmssw_base}}/${{version}}/src"
    eval "$(scram runtime -sh)"
    cd "${{workdir}}"
}}

run_step() {{
    local step="$1"
    local version="$2"
    local arch="$3"
    local cfg="$4"
    local output="$5"

    echo "===== ${{step}} start: ${{version}} ${{arch}} ====="
    setup_cmssw "${{version}}" "${{arch}}"
    cmsRun -j "FrameworkJobReport_${{step}}.xml" "${{cfg}}" 2>&1 | tee "${{step}}.log"
    test -s "${{output}}"
    echo "===== ${{step}} done: ${{output}} ====="
}}

cmssw_steps=(
{chr(10).join(cmssw_lines)}
)

for item in "${{cmssw_steps[@]}}"; do
    IFS=: read -r step version arch <<< "${{item}}"
    case "${{step}}" in
        GEN) output="GEN.root" ;;
        SIM) output="SIM.root" ;;
        DIGIPremix) output="DIGIPremix.root" ;;
        HLT) output="HLT.root" ;;
        RECO) output="RECO.root" ;;
        MiniAODv2) output="${{final_output}}" ;;
        *) echo "ERROR: unknown step ${{step}}" >&2; exit 1 ;;
    esac
    run_step "${{step}}" "${{version}}" "${{arch}}" "{campaign}${{step}}_cfg.py" "${{output}}"
done

cp FrameworkJobReport_MiniAODv2.xml FrameworkJobReport.xml
ls -lh "${{final_output}}"
"""
    path = task_dir / "run_fullchain_crab.sh"
    path.write_text(script)
    path.chmod(0o755)


def make_submit(campaign, sample, processes, task_dir):
    clean_sample = clean_name(sample)
    request = f"RKZp_{campaign}_FullChain_{ZPMASS_TAG}_{clean_sample}_pdfErr_{VERSION_TAG}"
    input_files = ["process_manifest.txt"]
    input_files.extend(f"{campaign}{step}_template_cfg.py" for step in STEPS)
    input_list = ",\n    ".join(repr(x) for x in input_files)
    submit = f"""from CRABClient.UserUtilities import config

config = config()

config.General.requestName = '{request}'
config.General.workArea = 'crabsub_projects'
config.General.transferLogs = True
config.General.transferOutputs = True

config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = '{campaign}GEN_crab_cfg.py'
config.JobType.scriptExe = 'run_fullchain_crab.sh'
config.JobType.inputFiles = [
    {input_list},
]
config.JobType.maxMemoryMB = 2500
config.JobType.numCores = 1

config.Data.outputPrimaryDataset = 'RKZp_{ZPMASS_TAG}_{clean_sample}'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 1
config.Data.totalUnits = {len(processes)}
config.Data.publication = False
config.Data.outputDatasetTag = '{campaign}_FullChain_MiniAODv2_pdfErr_{VERSION_TAG}'
config.Data.outLFNDirBase = '{OUTPUT_BASE}/{campaign}/{sample}'

config.Site.storageSite = 'T3_KR_KISTI'
"""
    (task_dir / "submit_crab.py").write_text(submit)


def make_tasks_for_configured_mass():
    OUTDIR.mkdir(parents=True, exist_ok=True)
    tasks = []

    if not INPUT_BASE_LOCAL.is_dir():
        print(f"WARNING: missing input directory {INPUT_BASE_LOCAL}; skipping", file=sys.stderr)
        return

    for sample_dir in sorted(p for p in INPUT_BASE_LOCAL.iterdir() if p.is_dir()):
        sample = sample_dir.name
        processes = completed_processes(sample_dir)
        if not processes:
            continue
        for campaign in CAMPAIGNS:
            task_dir = OUTDIR / campaign / sample
            task_dir.mkdir(parents=True, exist_ok=True)
            (task_dir / "process_manifest.txt").write_text(
                "".join(f"{p}\n" for p in processes)
            )
            for step in STEPS:
                shutil.copy2(
                    WD / "files_cfg" / f"{campaign}{step}_cfg.py",
                    task_dir / f"{campaign}{step}_template_cfg.py",
                )
            make_crab_pset(campaign, task_dir)
            make_script(campaign, sample, task_dir)
            make_submit(campaign, sample, processes, task_dir)
            tasks.append((campaign, sample, len(processes), task_dir))

    submit_lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        'base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
        "",
    ]
    status_lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        'base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
        "",
    ]
    summary_lines = []
    for campaign, sample, count, task_dir in tasks:
        rel = task_dir.relative_to(OUTDIR)
        submit_lines.extend([
            f'echo "Submitting {campaign} {sample} ({count} jobs)"',
            f'cd "$base/{rel}"',
            "crab submit -c submit_crab.py",
            "",
        ])
        clean_sample = clean_name(sample)
        project = f"crabsub_projects/crab_RKZp_{campaign}_FullChain_{ZPMASS_TAG}_{clean_sample}_pdfErr_{VERSION_TAG}"
        status_lines.extend([
            f'echo "Status {campaign} {sample}"',
            f'crab status -d "$base/{rel}/{project}"',
            "",
        ])
        summary_lines.append(f"{campaign} {sample} {count} {rel}")

    submit_all = OUTDIR / "submit_all.sh"
    submit_all.write_text("\n".join(submit_lines) + "\n")
    submit_all.chmod(0o755)

    status_all = OUTDIR / "status_all.sh"
    status_all.write_text("\n".join(status_lines) + "\n")
    status_all.chmod(0o755)

    (OUTDIR / "task_summary.txt").write_text("\n".join(summary_lines) + "\n")
    print(f"Wrote {len(tasks)} tasks under {OUTDIR}")
    print(f"Wrote {OUTDIR / 'submit_all.sh'}")
    print(f"Wrote {OUTDIR / 'status_all.sh'}")


def main():
    zpmasses = sys.argv[1:] or ["12"]
    for zpmass in zpmasses:
        configure_zpmass(zpmass)
        make_tasks_for_configured_mass()


if __name__ == "__main__":
    main()
