# Full-Chain CRAB Submission for pdfErr Samples

This directory contains the generator for the v3 CRAB full-chain submission used for
RKZp Herwig pdfErr samples.

The workflow runs the full chain inside `scriptExe`:

```text
GEN -> SIM -> DIGIPremix -> HLT -> RECO -> MiniAODv2
```

The CRAB job reads one Herwig `LHC.hepmc` file and produces one MiniAOD file named
`output.root` inside the worker job. CRAB then handles the final staged-out filename.

## Inputs and Outputs

Input files are expected under:

```text
/xrd/store/user/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000_pdfErr/MZp-<mass>
```

Worker-node access uses:

```text
root://cms-xrdr.sdfarm.kr:1095//xrd/store/user/taehee/HerwigSample/RKZp_13TeV/RS/hw_nEvt-100000_pdfErr/MZp-<mass>
```

Use port `1095`; port `1094` does not expose the `hw_nEvt-100000_pdfErr` tree.

Outputs are staged under:

```text
/store/user/taehee/HerwigSample/RKZp_13TeV/RS/samples_nEvt-100000_pdfErr/MiniAODv2/MZp-<mass>/<campaign>/<sample>
```

## Completion Check

The generator builds `process_manifest.txt` from local files only when both files exist:

```text
LHC.hepmc
LHC.log
```

and `LHC.log` contains:

```text
Total:
```

The runtime CRAB job does not copy `LHC.log`; it only copies `LHC.hepmc`. This avoids
failing stage-in on log-file access while still submitting only completed Herwig
process directories.

## Generate Tasks

From `SampleGeneration`:

```bash
python3 crabsub_fullchain_pdfErr/make_fullchain_tasks.py 12 20 25 30 35
```

This creates one directory per mass:

```text
crabsub_fullchain_pdfErr_v3/MZp12
crabsub_fullchain_pdfErr_v3/MZp20
crabsub_fullchain_pdfErr_v3/MZp25
crabsub_fullchain_pdfErr_v3/MZp30
crabsub_fullchain_pdfErr_v3/MZp35
```

For another mass, pass the mass number:

```bash
python3 crabsub_fullchain_pdfErr/make_fullchain_tasks.py 40
```

## Submit

Set up CMSSW and CRAB:

```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/CMSSW/CMSSW_10_6_19_patch3/src
cmsenv
source /cvmfs/cms.cern.ch/common/crab-setup.sh
```

Submit all generated masses:

```bash
for m in 12 20 25 30 35; do
  cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_fullchain_pdfErr_v3/MZp${m}
  ./submit_all.sh
done
```

Submit one mass:

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_fullchain_pdfErr_v3/MZp20
./submit_all.sh
```

## Status

Check all tasks for one mass:

```bash
cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_fullchain_pdfErr_v3/MZp20
./status_all.sh
```

Check all generated masses:

```bash
for m in 12 20 25 30 35; do
  cd /cms/ldap_home/taehee/HerwigWD/hw7_validation/FullShower/RKZp/SampleGeneration/crabsub_fullchain_pdfErr_v3/MZp${m}
  ./status_all.sh
done
```

## Files Needed in Git

Commit the generator and this README:

```text
crabsub_fullchain_pdfErr/README.md
crabsub_fullchain_pdfErr/make_fullchain_tasks.py
```

The generator depends on these campaign step templates:

```text
files_cfg/RunIISummer20UL16{GEN,SIM,DIGIPremix,HLT,RECO,MiniAODv2}_cfg.py
files_cfg/RunIISummer20UL16APV{GEN,SIM,DIGIPremix,HLT,RECO,MiniAODv2}_cfg.py
files_cfg/RunIISummer20UL17{GEN,SIM,DIGIPremix,HLT,RECO,MiniAODv2}_cfg.py
files_cfg/RunIISummer20UL18{GEN,SIM,DIGIPremix,HLT,RECO,MiniAODv2}_cfg.py
```

Generated directories such as `crabsub_fullchain_pdfErr_v3/MZp*/` are reproducible
from the generator. They are useful operational artifacts, but they are not required
source files for the workflow.
