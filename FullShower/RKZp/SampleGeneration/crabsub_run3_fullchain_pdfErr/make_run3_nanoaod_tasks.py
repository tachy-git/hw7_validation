#!/usr/bin/env python3
import re
import shutil
import sys
from pathlib import Path


WD = Path("/cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration")
MINIAOD_ROOT_LOCAL = Path("/xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/MiniAOD")
MINIAOD_ROOT_XRD = "root://cms-xrdr.sdfarm.kr:1095//xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/MiniAOD"
OUTPUT_ROOT = "/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/NanoAOD"
VERSION_TAG = "v2"

CAMPAIGNS = ["Run3Summer22", "Run3Summer22EE", "Run3Summer23", "Run3Summer23BPix"]
CAMPAIGN_GROUPS = {
    "2022": {
        "campaigns": {"Run3Summer22", "Run3Summer22EE"},
        "cmssw": "CMSSW_12_6_0",
        "scram_arch": "el8_amd64_gcc10",
    },
    "2023": {
        "campaigns": {"Run3Summer23", "Run3Summer23BPix"},
        "cmssw": "CMSSW_13_0_14",
        "scram_arch": "el8_amd64_gcc11",
    },
}

NANO_WORKFLOWS = {
    "Run3Summer22": ("NanoAOD", "CMSSW_12_6_0", "el8_amd64_gcc10"),
    "Run3Summer22EE": ("NanoAOD", "CMSSW_12_6_0", "el8_amd64_gcc10"),
    "Run3Summer23": ("NanoAOD", "CMSSW_13_0_14", "el8_amd64_gcc11"),
    "Run3Summer23BPix": ("NanoAOD", "CMSSW_13_0_14", "el8_amd64_gcc11"),
}


def clean_name(value):
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def find_miniaod_files(sample_dir):
    return sorted(p for p in sample_dir.rglob("*.root") if p.is_file())


def local_to_xrd(path):
    rel = path.relative_to(MINIAOD_ROOT_LOCAL)
    return f"{MINIAOD_ROOT_XRD}/{rel.as_posix()}"


def make_crab_pset(campaign, task_dir):
    text = (WD / "files_cfg" / f"{campaign}NanoAOD_cfg.py").read_text()
    text = text.replace("__INPUT__", "miniAOD")
    text = text.replace("__OUTPUT__", "output")
    text = text.replace("__RANDOM__", "1")
    (task_dir / f"{campaign}NanoAOD_crab_cfg.py").write_text(text)


def make_script(campaign, task_dir):
    step, version, arch = NANO_WORKFLOWS[campaign]
    script = f"""#!/usr/bin/env bash
set -euo pipefail

max_events="${{NANOAOD_MAX_EVENTS:--1}}"
workdir="$(pwd)"
cmssw_base="${{workdir}}/nanoaod_cmssw"
final_output="output.root"

mapfile -t miniaod_files < miniaod_manifest.txt
job_number="${{1:-1}}"
manifest_index=$((job_number - 1))

if (( manifest_index < 0 || manifest_index >= ${{#miniaod_files[@]}} )); then
    echo "ERROR: CRAB job ${{job_number}} has no MiniAOD manifest entry" >&2
    exit 1
fi

input_pfn="${{miniaod_files[$manifest_index]}}"
echo "CRAB job ${{job_number}} reads MiniAOD ${{input_pfn}}"
xrdcp -f "${{input_pfn}}" miniAOD.root
ls -lh miniAOD.root

python3 - "${{max_events}}" <<'PY'
import re
import sys
from pathlib import Path

max_events = sys.argv[1]
text = Path("{campaign}NanoAOD_template_cfg.py").read_text()
text = text.replace("__INPUT__", "miniAOD")
text = text.replace("__OUTPUT__", "output")
text = text.replace("__RANDOM__", "1")
text = re.sub(
    r"input\\s*=\\s*cms\\.untracked\\.int32\\(-1\\)",
    "input = cms.untracked.int32(%s)" % max_events,
    text,
    count=1,
)
Path("{campaign}NanoAOD_cfg.py").write_text(text)
print("Prepared {campaign}NanoAOD_cfg.py")
PY

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH="{arch}"
mkdir -p "${{cmssw_base}}"

if [[ ! -d "${{cmssw_base}}/{version}/src" ]]; then
    echo "Creating {version} with ${{SCRAM_ARCH}}"
    cd "${{cmssw_base}}"
    scram project CMSSW "{version}"
fi

cd "${{cmssw_base}}/{version}/src"
eval "$(scram runtime -sh)"
cd "${{workdir}}"

cmsRun -j FrameworkJobReport_NanoAOD.xml "{campaign}NanoAOD_cfg.py" 2>&1 | tee NanoAOD.log
test -s "${{final_output}}"
cp FrameworkJobReport_NanoAOD.xml FrameworkJobReport.xml
ls -lh "${{final_output}}"
"""
    path = task_dir / "run_nanoaod_crab.sh"
    path.write_text(script)
    path.chmod(0o755)


def make_submit(campaign, sample, input_files, zpmass_tag, output_base, task_dir):
    clean_sample = clean_name(sample)
    request = f"RKZp_{campaign}_Run3NanoAOD_pdfErr_{zpmass_tag}_{clean_sample}_{VERSION_TAG}"
    submit = f"""from CRABClient.UserUtilities import config

config = config()

config.General.requestName = '{request}'
config.General.workArea = 'crabsub_projects'
config.General.transferLogs = True
config.General.transferOutputs = True

config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = '{campaign}NanoAOD_crab_cfg.py'
config.JobType.scriptExe = 'run_nanoaod_crab.sh'
config.JobType.inputFiles = [
    'miniaod_manifest.txt',
    '{campaign}NanoAOD_template_cfg.py',
]
config.JobType.maxMemoryMB = 3000
config.JobType.numCores = 1

config.Data.outputPrimaryDataset = 'RKZp_{zpmass_tag}_{clean_sample}'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 1
config.Data.totalUnits = {len(input_files)}
config.Data.publication = False
config.Data.outputDatasetTag = '{campaign}_Run3NanoAOD_pdfErr_{VERSION_TAG}'
config.Data.outLFNDirBase = '{output_base}/{campaign}/{sample}'

config.Site.storageSite = 'T2_KR_KISTI'
"""
    (task_dir / "submit_crab.py").write_text(submit)


def make_tasks_for_mass(zpmass):
    zpmass_dir = f"MZp-{zpmass}"
    zpmass_tag = f"MZp{zpmass}"
    input_mass_dir = MINIAOD_ROOT_LOCAL / zpmass_dir
    output_base = f"{OUTPUT_ROOT}/{zpmass_dir}"
    outdir = WD / f"crabsub_run3_nanoaod_pdfErr_{VERSION_TAG}" / zpmass_tag
    outdir.mkdir(parents=True, exist_ok=True)

    if not input_mass_dir.is_dir():
        print(f"WARNING: missing MiniAOD directory {input_mass_dir}; skipping", file=sys.stderr)
        return

    tasks = []
    for campaign in CAMPAIGNS:
        campaign_dir = input_mass_dir / campaign
        if not campaign_dir.is_dir():
            continue
        for sample_dir in sorted(p for p in campaign_dir.iterdir() if p.is_dir()):
            sample = sample_dir.name
            miniaod_files = find_miniaod_files(sample_dir)
            if not miniaod_files:
                continue
            task_dir = outdir / campaign / sample
            task_dir.mkdir(parents=True, exist_ok=True)
            xrd_files = [local_to_xrd(p) for p in miniaod_files]
            (task_dir / "miniaod_manifest.txt").write_text("".join(f"{p}\n" for p in xrd_files))
            shutil.copy2(
                WD / "files_cfg" / f"{campaign}NanoAOD_cfg.py",
                task_dir / f"{campaign}NanoAOD_template_cfg.py",
            )
            make_crab_pset(campaign, task_dir)
            make_script(campaign, task_dir)
            make_submit(campaign, sample, xrd_files, zpmass_tag, output_base, task_dir)
            tasks.append((campaign, sample, len(xrd_files), task_dir))

    write_helpers(outdir, tasks, zpmass_tag)


def write_helpers(outdir, tasks, zpmass_tag):
    header = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        'base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
        "",
    ]
    submit_all_lines = header[:] + [
        'echo "Use campaign-group submit helpers from the matching CMSSW environment:" >&2',
        'echo "  submit_2022.sh: Run3Summer22, Run3Summer22EE from CMSSW_12_6_0 / el8_amd64_gcc10" >&2',
        'echo "  submit_2023.sh: Run3Summer23, Run3Summer23BPix from CMSSW_13_0_14 / el8_amd64_gcc11" >&2',
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
    for campaign, sample, count, task_dir in tasks:
        rel = task_dir.relative_to(outdir)
        clean_sample = clean_name(sample)
        project = f"crabsub_projects/crab_RKZp_{campaign}_Run3NanoAOD_pdfErr_{zpmass_tag}_{clean_sample}_{VERSION_TAG}"
        group = next(name for name, info in CAMPAIGN_GROUPS.items() if campaign in info["campaigns"])
        submit_by_group[group].extend([
            f'echo "Submitting NanoAOD {campaign} {sample} ({count} jobs)"',
            f'cd "$base/{rel}"',
            "crab submit -c submit_crab.py",
            "",
        ])
        status_by_group[group].extend([
            f'echo "Status NanoAOD {campaign} {sample}"',
            f'crab status -d "$base/{rel}/{project}"',
            "",
        ])
        status_all_lines.extend([
            f'echo "Status NanoAOD {campaign} {sample}"',
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
        submit_group = outdir / f"submit_{group}.sh"
        submit_group.write_text("\n".join(submit_by_group[group]) + "\n")
        submit_group.chmod(0o755)
        status_group = outdir / f"status_{group}.sh"
        status_group.write_text("\n".join(status_by_group[group]) + "\n")
        status_group.chmod(0o755)

    (outdir / "task_summary.txt").write_text("\n".join(summary_lines) + "\n")
    print(f"Wrote {len(tasks)} NanoAOD tasks under {outdir}")
    print(f"Wrote {submit_all}")
    print(f"Wrote {status_all}")


def main():
    zpmasses = sys.argv[1:] or ["12"]
    for zpmass in zpmasses:
        make_tasks_for_mass(zpmass)


if __name__ == "__main__":
    main()
