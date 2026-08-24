# Run3 CRAB Submission for pdfErr Samples

This directory contains generators for Run3 CRAB submission using the Run3 cfg
templates in `files_cfg` and the Herwig pdfErr input tree.

There are two supported modes:

```text
Split production:
  HepMC -> GEN -> SIM -> DRPremix1 -> DRPremix2 -> MiniAOD
  MiniAOD -> NanoAOD

One-shot production:
  HepMC -> GEN -> SIM -> DRPremix1 -> DRPremix2 -> MiniAOD -> NanoAOD
```

For production where both MiniAOD and NanoAOD should be kept, use the split
production scripts. The one-shot script is kept for tests or NanoAOD-only output.

## Workflows

The Run3 chain follows `condor_Run3.sh`:

```text
GEN -> SIM -> DRPremix1 -> DRPremix2 -> MiniAODv4 -> NanoAOD
```

## Campaigns

The generator creates tasks for:

```text
Run3Summer22
Run3Summer22EE
Run3Summer23
Run3Summer23BPix
```

Campaign-specific MiniAOD step names are:

```text
Run3Summer22: MiniAODv4
Run3Summer22EE: MiniAODv4
Run3Summer23: MiniAODv4
Run3Summer23BPix: MiniAODv4
```

For `Run3Summer22` and `Run3Summer22EE`, the `MiniAODv4` step runs with
`CMSSW_13_0_13` and `el8_amd64_gcc11`; the earlier GEN/SIM/DRPremix steps stay
on `CMSSW_12_4_11_patch3` and `el8_amd64_gcc10`.

## Inputs and Outputs

Input files are expected under:

```text
/xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000_pdfErr/MZp-<mass>
```

Worker-node access uses:

```text
root://cms-xrdr.sdfarm.kr:1095//xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/hw_nEvt-100000_pdfErr/MZp-<mass>
```

Outputs are staged under:

```text
MiniAOD:
/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/MiniAOD/MZp-<mass>/<campaign>/<sample>

NanoAOD:
/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/NanoAOD/MZp-<mass>/<campaign>/<sample>
```

## Completion Check

The generator builds `process_manifest.txt` only for process directories where:

```text
LHC.hepmc
LHC.log
```

exist locally, and `LHC.log` contains:

```text
Total:
```

The CRAB worker copies only `LHC.hepmc`; the log check is done before submission.

## Split Production

Use this mode when both MiniAOD and NanoAOD should be saved. The MiniAOD tasks
must finish first; the NanoAOD task generator scans the staged MiniAOD output.

### Generate MiniAOD Tasks

From `SampleGeneration`:

```bash
python3 crabsub_run3_fullchain_pdfErr/make_run3_miniaod_tasks.py 12 20 25 30 35
```

This creates:

```text
crabsub_run3_miniaod_pdfErr_v2/MZp12
crabsub_run3_miniaod_pdfErr_v2/MZp20
...
```

For another mass:

```bash
python3 crabsub_run3_fullchain_pdfErr/make_run3_miniaod_tasks.py 40
```

To add only `Run3Summer22EE` tasks into an existing mass directory without
moving or removing the existing `Run3Summer22` jobs:

```bash
python3 crabsub_run3_fullchain_pdfErr/make_run3_miniaod_tasks.py --campaign 2022EE 12
```

Each MiniAOD CRAB job stages out one `output.root`, which is the MiniAOD file.

### Submit MiniAOD

Submit the 2022 or 2022EE campaign from a CMSSW 12 environment:

```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el8_amd64_gcc10
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/CMSSW/CMSSW_12_4_11_patch3/src
cmsenv
source /cvmfs/cms.cern.ch/common/crab-setup.sh
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_miniaod_pdfErr_v2/MZp12
./submit_2022.sh
# or, for the post-EE campaign:
./submit_2022EE.sh
```

Submit the 2023 or 2023BPix campaign from a CMSSW 13 environment:

```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el8_amd64_gcc11
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/CMSSW/CMSSW_13_0_14/src
cmsenv
source /cvmfs/cms.cern.ch/common/crab-setup.sh
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_miniaod_pdfErr_v2/MZp12
./submit_2023.sh
# or, for the BPix campaign:
./submit_2023BPix.sh
```

For several masses, run the matching group helper for each mass:

```bash
for m in 12 20 25 30 35; do
  cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_miniaod_pdfErr_v2/MZp${m}
  ./submit_2022.sh
done
```

### MiniAOD Status

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_miniaod_pdfErr_v2/MZp12
./status_all.sh
./status_2022.sh
./status_2022EE.sh
./status_2023.sh
./status_2023BPix.sh
```

### Generate NanoAOD Tasks

After MiniAOD files have staged out and are visible under `/xrd/store`, generate
NanoAOD tasks:

```bash
python3 crabsub_run3_fullchain_pdfErr/make_run3_nanoaod_tasks.py 12 20 25 30 35
```

This creates:

```text
crabsub_run3_nanoaod_pdfErr_v2/MZp12
crabsub_run3_nanoaod_pdfErr_v2/MZp20
...
```

The NanoAOD generator scans recursively below:

```text
/xrd/store/user/taehee/HerwigSample/RKZp_13p6TeV/RS/samples_nEvt-100000_pdfErr/MiniAOD/MZp-<mass>/<campaign>/<sample>
```

and writes one MiniAOD PFN per line to `miniaod_manifest.txt`. Each NanoAOD
CRAB job copies one MiniAOD file and stages out one `output.root`, which is the
NanoAOD file.

### Submit NanoAOD

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_nanoaod_pdfErr_v2/MZp12
./submit_2022.sh
# after switching to the CMSSW 13 setup:
./submit_2023.sh
```

### NanoAOD Status

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_nanoaod_pdfErr_v2/MZp12
./status_all.sh
./status_2022.sh
./status_2023.sh
```

## One-Shot NanoAOD Production

To run the full chain in one CRAB job and keep only NanoAOD:

```bash
python3 crabsub_run3_fullchain_pdfErr/make_run3_tasks.py 12
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_fullchain_pdfErr_v2/MZp12
./submit_2022.sh
# after switching to the CMSSW 13 setup:
./submit_2023.sh
```

The final CRAB-visible output file is `output.root`, produced by the NanoAOD
step. Intermediate MiniAOD files are not staged out in this mode.

## Resubmit Failed Jobs

After setting up CMSSW and CRAB:

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration
```

MiniAOD failed jobs should be resubmitted by campaign group from the matching
CMSSW environment. From a generated mass directory:

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_run3_miniaod_pdfErr_v2/MZp12
./resubmit_2022.sh
./resubmit_2022EE.sh

# after switching to the CMSSW 13 setup:
./resubmit_2023.sh
./resubmit_2023BPix.sh
```

The central helper also supports campaign-group filtering:

```bash
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022EE 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023BPix 12
```

NanoAOD failed jobs:

```bash
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode nanoaod 12
```

One-shot full-chain failed jobs:

```bash
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode fullchain 12
```

Dry-run examples:

```bash
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022 --dry-run 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022EE --dry-run 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023 --dry-run 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2023BPix --dry-run 12
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode nanoaod --dry-run 12
```

Extra CRAB options:

```bash
./crabsub_run3_fullchain_pdfErr/resubmit_failed.sh --mode miniaod --campaign-group 2022 12 -- --maxmemory 3000
```

The helper calls `crab status -d <project>` first. It runs
`crab resubmit -d <project>` only when failed jobs are more than 5% of the task;
tasks with 5% or fewer failed jobs are skipped.

## Files Needed in Git

Commit:

```text
.gitignore
crabsub_run3_fullchain_pdfErr/README.md
crabsub_run3_fullchain_pdfErr/.gitignore
crabsub_run3_fullchain_pdfErr/make_run3_miniaod_tasks.py
crabsub_run3_fullchain_pdfErr/make_run3_nanoaod_tasks.py
crabsub_run3_fullchain_pdfErr/make_run3_tasks.py
crabsub_run3_fullchain_pdfErr/resubmit_failed.sh
```

The generator depends on:

```text
files_cfg/Run3Summer22{GEN,SIM,DRPremix1,DRPremix2,MiniAODv4,NanoAOD}_cfg.py
files_cfg/Run3Summer22EE{GEN,SIM,DRPremix1,DRPremix2,MiniAODv4,NanoAOD}_cfg.py
files_cfg/Run3Summer23{GEN,SIM,DRPremix1,DRPremix2,MiniAODv4,NanoAOD}_cfg.py
files_cfg/Run3Summer23BPix{GEN,SIM,DRPremix1,DRPremix2,MiniAODv4,NanoAOD}_cfg.py
```

Generated directories such as `crabsub_run3_miniaod_pdfErr_v2/MZp*/`,
`crabsub_run3_nanoaod_pdfErr_v2/MZp*/`, and `crabsub_run3_fullchain_pdfErr_v2/MZp*/` are
reproducible from the generators and do not need to be committed.
