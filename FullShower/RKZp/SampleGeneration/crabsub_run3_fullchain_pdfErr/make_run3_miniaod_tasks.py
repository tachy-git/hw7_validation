#!/usr/bin/env python3
import argparse
import re
import shutil
import sys
from pathlib import Path


WD = Path("/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration")
INPUT_ROOT_LOCAL = Path("/xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000_pdfErr")
INPUT_ROOT_XRD = "root://cms-xrdr.sdfarm.kr:1094//xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000_pdfErr"
OUTPUT_ROOT = "/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/MiniAOD"
VERSION_TAG = "v2"

CAMPAIGNS = ["Run3Summer22", "Run3Summer22EE", "Run3Summer23", "Run3Summer23BPix"]
CAMPAIGN_GROUPS = {
    "2022": {
        "campaigns": {"Run3Summer22"},
        "cmssw": "CMSSW_12_4_11_patch3",
        "scram_arch": "el8_amd64_gcc10",
    },
    "2022EE": {
        "campaigns": {"Run3Summer22EE"},
        "cmssw": "CMSSW_12_4_11_patch3",
        "scram_arch": "el8_amd64_gcc10",
    },
    "2023": {
        "campaigns": {"Run3Summer23"},
        "cmssw": "CMSSW_13_0_14",
        "scram_arch": "el8_amd64_gcc11",
    },
    "2023BPix": {
        "campaigns": {"Run3Summer23BPix"},
        "cmssw": "CMSSW_13_0_14",
        "scram_arch": "el8_amd64_gcc11",
    },
}
CAMPAIGN_ALIASES = {
    "2022": "Run3Summer22",
    "Run3Summer22": "Run3Summer22",
    "2022EE": "Run3Summer22EE",
    "Run3Summer22EE": "Run3Summer22EE",
    "2023": "Run3Summer23",
    "Run3Summer23": "Run3Summer23",
    "2023BPix": "Run3Summer23BPix",
    "Run3Summer23BPix": "Run3Summer23BPix",
}

WORKFLOWS = {
    "Run3Summer22": [
        ("GEN", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("SIM", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("DRPremix1", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("DRPremix2", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("MiniAODv4", "CMSSW_13_0_13", "el8_amd64_gcc11"),
    ],
    "Run3Summer22EE": [
        ("GEN", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("SIM", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("DRPremix1", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("DRPremix2", "CMSSW_12_4_11_patch3", "el8_amd64_gcc10"),
        ("MiniAODv4", "CMSSW_13_0_13", "el8_amd64_gcc11"),
    ],
    "Run3Summer23": [
        ("GEN", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("SIM", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("DRPremix1", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("DRPremix2", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("MiniAODv4", "CMSSW_13_0_14", "el8_amd64_gcc11"),
    ],
    "Run3Summer23BPix": [
        ("GEN", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("SIM", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("DRPremix1", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("DRPremix2", "CMSSW_13_0_14", "el8_amd64_gcc11"),
        ("MiniAODv4", "CMSSW_13_0_14", "el8_amd64_gcc11"),
    ],
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


def campaign_group(campaign):
    return next(name for name, info in CAMPAIGN_GROUPS.items() if campaign in info["campaigns"])


def parse_campaigns(values):
    if not values:
        return CAMPAIGNS[:]

    selected = []
    for raw_value in values:
        for value in raw_value.split(","):
            value = value.strip()
            if not value:
                continue
            try:
                campaign = CAMPAIGN_ALIASES[value]
            except KeyError:
                valid = ", ".join(CAMPAIGN_ALIASES)
                raise SystemExit(f"ERROR: unknown campaign '{value}'. Use one of: {valid}")
            if campaign not in selected:
                selected.append(campaign)
    return selected


def make_crab_pset(campaign, task_dir):
    text = (WD / "files_cfg" / f"{campaign}GEN_cfg.py").read_text()
    text = text.replace("__INPUT__", "LHC")
    text = text.replace("__OUTPUT__", "output")
    text = text.replace("__RANDOM__", "1")
    (task_dir / f"{campaign}GEN_crab_cfg.py").write_text(text)


def make_script(campaign, sample, zpmass_tag, input_base_xrd, task_dir):
    workflow = WORKFLOWS[campaign]
    final_step = workflow[-1][0]
    step_lines = [
        f'    "{step}:{campaign}{step}_template_cfg.py:{campaign}{step}_cfg.py",'
        for step, _, _ in workflow
    ]
    cmssw_lines = [
        f'    "{step}:{version}:{arch}"'
        for step, version, arch in workflow
    ]

    script = f"""#!/usr/bin/env bash
set -euo pipefail

sample="{sample}"
zpmass="{zpmass_tag}"
input_base="{input_base_xrd}"
max_events="${{MINIAOD_MAX_EVENTS:--1}}"
workdir="$(pwd)"
cmssw_base="${{workdir}}/miniaod_cmssw"

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
final_output="output.root"

echo "CRAB job ${{job_number}} maps to Herwig process ${{process_id}} for ${{zpmass}} ${{sample}}"
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

for idx, item in enumerate(steps):
    step, template, cfg = item.split(":")
    if step == "GEN":
        input_base = "LHC"
        output_base = "GEN"
    elif idx == len(steps) - 1:
        prev = steps[idx - 1].split(":")[0]
        input_base = prev
        output_base = final_output[:-5]
    else:
        prev = steps[idx - 1].split(":")[0]
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
        DRPremix1) output="DRPremix1.root" ;;
        DRPremix2) output="DRPremix2.root" ;;
        MiniAOD|MiniAODv3|MiniAODv4) output="${{final_output}}" ;;
        *) echo "ERROR: unknown step ${{step}}" >&2; exit 1 ;;
    esac
    run_step "${{step}}" "${{version}}" "${{arch}}" "{campaign}${{step}}_cfg.py" "${{output}}"
done

cp FrameworkJobReport_{final_step}.xml FrameworkJobReport.xml
ls -lh "${{final_output}}"
"""
    path = task_dir / "run_miniaod_crab.sh"
    path.write_text(script)
    path.chmod(0o755)


def make_submit(campaign, sample, processes, zpmass_tag, output_base, task_dir):
    clean_sample = clean_name(sample)
    request = f"RKZp_{campaign}_Run3MiniAOD_pdfErr_{zpmass_tag}_{clean_sample}_{VERSION_TAG}"
    input_files = ["process_manifest.txt"]
    input_files.extend(f"{campaign}{step}_template_cfg.py" for step, _, _ in WORKFLOWS[campaign])
    input_list = ",\n    ".join(repr(x) for x in input_files)
    submit = f"""from CRABClient.UserUtilities import config

config = config()

config.General.requestName = '{request}'
config.General.workArea = 'crabsub_projects'
config.General.transferLogs = True
config.General.transferOutputs = True

config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = '{campaign}GEN_crab_cfg.py'
config.JobType.scriptExe = 'run_miniaod_crab.sh'
config.JobType.inputFiles = [
    {input_list},
]
config.JobType.maxMemoryMB = 3000
config.JobType.numCores = 1

config.Data.outputPrimaryDataset = 'RKZp_{zpmass_tag}_{clean_sample}'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 1
config.Data.totalUnits = {len(processes)}
config.Data.publication = False
config.Data.outputDatasetTag = '{campaign}_Run3MiniAOD_pdfErr_{VERSION_TAG}'
config.Data.outLFNDirBase = '{output_base}/{campaign}/{sample}'

config.Site.storageSite = 'T2_KR_KISTI'
"""
    (task_dir / "submit_crab.py").write_text(submit)


def make_tasks_for_mass(zpmass, campaigns, filtered):
    zpmass_dir = f"MZp-{zpmass}"
    zpmass_tag = f"MZp{zpmass}"
    input_base_local = INPUT_ROOT_LOCAL / zpmass_dir
    input_base_xrd = f"{INPUT_ROOT_XRD}/{zpmass_dir}"
    output_base = f"{OUTPUT_ROOT}/{zpmass_dir}"
    outdir = WD / f"crabsub_run3_miniaod_pdfErr_{VERSION_TAG}" / zpmass_tag
    outdir.mkdir(parents=True, exist_ok=True)

    if not input_base_local.is_dir():
        print(f"WARNING: missing input directory {input_base_local}; skipping", file=sys.stderr)
        return

    tasks = []
    for sample_dir in sorted(p for p in input_base_local.iterdir() if p.is_dir()):
        sample = sample_dir.name
        processes = completed_processes(sample_dir)
        if not processes:
            continue
        for campaign in campaigns:
            task_dir = outdir / campaign / sample
            task_dir.mkdir(parents=True, exist_ok=True)
            (task_dir / "process_manifest.txt").write_text("".join(f"{p}\n" for p in processes))
            for step, _, _ in WORKFLOWS[campaign]:
                shutil.copy2(
                    WD / "files_cfg" / f"{campaign}{step}_cfg.py",
                    task_dir / f"{campaign}{step}_template_cfg.py",
                )
            make_crab_pset(campaign, task_dir)
            make_script(campaign, sample, zpmass_tag, input_base_xrd, task_dir)
            make_submit(campaign, sample, processes, zpmass_tag, output_base, task_dir)
            tasks.append((campaign, sample, len(processes), task_dir))

    helper_groups = {campaign_group(campaign) for campaign in campaigns} if filtered else None
    write_helpers(outdir, tasks, zpmass_tag, helper_groups)


def read_summary(outdir):
    summary = outdir / "task_summary.txt"
    if not summary.is_file():
        return []

    tasks = []
    for line in summary.read_text().splitlines():
        parts = line.split()
        if len(parts) != 4:
            continue
        campaign, sample, count, rel = parts
        if campaign not in CAMPAIGNS:
            continue
        try:
            count = int(count)
        except ValueError:
            continue
        tasks.append((campaign, sample, count, outdir / rel))
    return tasks


def merge_tasks(existing_tasks, new_tasks):
    merged = {(campaign, sample): (campaign, sample, count, task_dir)
              for campaign, sample, count, task_dir in existing_tasks}
    for campaign, sample, count, task_dir in new_tasks:
        merged[(campaign, sample)] = (campaign, sample, count, task_dir)

    campaign_order = {campaign: idx for idx, campaign in enumerate(CAMPAIGNS)}
    return sorted(
        merged.values(),
        key=lambda item: (campaign_order.get(item[0], len(CAMPAIGNS)), item[1]),
    )


def write_helpers(outdir, tasks, zpmass_tag, helper_groups=None):
    all_tasks = merge_tasks(read_summary(outdir), tasks)
    groups_to_write = set(helper_groups) if helper_groups is not None else set(CAMPAIGN_GROUPS)
    header = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        'base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
        "",
    ]
    submit_all_lines = header[:] + [
        'echo "Use campaign-group submit helpers from the matching CMSSW environment:" >&2',
        'echo "  submit_2022.sh: Run3Summer22 from CMSSW_12_4_11_patch3 / el8_amd64_gcc10" >&2',
        'echo "  submit_2022EE.sh: Run3Summer22EE from CMSSW_12_4_11_patch3 / el8_amd64_gcc10" >&2',
        'echo "  submit_2023.sh: Run3Summer23 from CMSSW_13_0_14 / el8_amd64_gcc11" >&2',
        'echo "  submit_2023BPix.sh: Run3Summer23BPix from CMSSW_13_0_14 / el8_amd64_gcc11" >&2',
        "exit 2",
        "",
    ]
    status_all_lines = header[:]
    submit_by_group = {}
    status_by_group = {}
    for group, info in CAMPAIGN_GROUPS.items():
        submit_by_group[group] = header[:] + [
            f'echo "Submit these tasks from {info["cmssw"]} with SCRAM_ARCH={info["scram_arch"]}"',
            "",
        ]
        status_by_group[group] = header[:]
    summary_lines = []
    for campaign, sample, count, task_dir in all_tasks:
        rel = task_dir.relative_to(outdir)
        clean_sample = clean_name(sample)
        project = f"crabsub_projects/crab_RKZp_{campaign}_Run3MiniAOD_pdfErr_{zpmass_tag}_{clean_sample}_{VERSION_TAG}"
        group = campaign_group(campaign)
        submit_by_group[group].extend([
            f'echo "Submitting MiniAOD {campaign} {sample} ({count} jobs)"',
            f'cd "$base/{rel}"',
            "crab submit -c submit_crab.py",
            "",
        ])
        status_by_group[group].extend([
            f'echo "Status MiniAOD {campaign} {sample}"',
            f'crab status -d "$base/{rel}/{project}"',
            "",
        ])
        status_all_lines.extend([
            f'echo "Status MiniAOD {campaign} {sample}"',
            f'crab status -d "$base/{rel}/{project}"',
            "",
        ])
        summary_lines.append(f"{campaign} {sample} {count} {rel}")

    submit_all = outdir / "submit_all.sh"
    submit_all.write_text("\n".join(submit_all_lines) + "\n")
    submit_all.chmod(0o755)

    status_all = outdir / "status_all.sh"
    status_all.write_text("\n".join(status_all_lines) + "\n")
    status_all.chmod(0o755)

    for group in CAMPAIGN_GROUPS:
        if group not in groups_to_write:
            continue
        submit_group = outdir / f"submit_{group}.sh"
        submit_group.write_text("\n".join(submit_by_group[group]) + "\n")
        submit_group.chmod(0o755)
        status_group = outdir / f"status_{group}.sh"
        status_group.write_text("\n".join(status_by_group[group]) + "\n")
        status_group.chmod(0o755)
        resubmit_group = outdir / f"resubmit_{group}.sh"
        resubmit_group.write_text(
            "\n".join([
                "#!/usr/bin/env bash",
                "set -euo pipefail",
                "",
                'base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
                'mass_tag="$(basename "${base}")"',
                'mass="${mass_tag#MZp}"',
                f'exec "${{base}}/../../crabsub_run3_fullchain_pdfErr/resubmit_failed.sh" --mode miniaod --campaign-group {group} --version {VERSION_TAG} "${{mass}}" "$@"',
            ]) + "\n"
        )
        resubmit_group.chmod(0o755)

    (outdir / "task_summary.txt").write_text("\n".join(summary_lines) + "\n")
    print(f"Wrote {len(tasks)} MiniAOD tasks under {outdir}")
    print(f"Wrote {submit_all}")
    print(f"Wrote {status_all}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Run3 MiniAOD CRAB task directories for pdfErr samples.",
    )
    parser.add_argument(
        "--campaign",
        action="append",
        default=[],
        help=(
            "Campaign to generate. Accepts 2022, 2022EE, 2023, 2023BPix or the "
            "full Run3Summer* name. May be repeated or comma-separated. Default: all."
        ),
    )
    parser.add_argument("zpmasses", nargs="*", default=["12"])
    args = parser.parse_args()

    campaigns = parse_campaigns(args.campaign)
    filtered = bool(args.campaign)
    for zpmass in args.zpmasses:
        make_tasks_for_mass(zpmass, campaigns, filtered)


if __name__ == "__main__":
    main()
