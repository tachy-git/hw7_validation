#!/usr/bin/env python3

####################################################################
# This python script identifies pileup files accessible to the user.
# cf. The user cannot access the files stored in TAPE
# The results are saved in a generated txt file.
# Update the process.mixData.input.fileNames field
# in the DIGIPremix configuration file with these results.
# Please be patient, as the procss may take some time.
####################################################################

import subprocess

era="18"

dataset={
    "17": "/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3/PREMIX",
    "18": "/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX",
}
#https://cmsweb.cern.ch/das/request?instance=prod/global&input=site+dataset%3D%2FNeutrino_E-10_gun%2FRunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3%2FPREMIX
#https://cmsweb.cern.ch/das/request?instance=prod/global&input=site+dataset%3D%2FNeutrino_E-10_gun%2FRunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2%2FPREMIX

def commandOutput(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return result.stdout.strip().split("\n")

def main():

    print(f"checking the list of pileup files in datset {dataset[era]}...")
    commandFile = f'dasgoclient --query="file dataset={dataset[era]}"'
    files = commandOutput(commandFile)
    filesAccessible = []

    print("checking the sites of each file...")
    for idx, f in enumerate(files):
        if idx<10 or (idx+1)%100==0 or idx==len(files)-1:
            print(f"Processing file {idx+1}/{len(files)}...")

        commandSite = f'dasgoclient --query="site file={f}"'
        sites = commandOutput(commandSite)
        if not all('Disk' in site for site in sites):
            filesAccessible.append(f)

    with open(f"PUfilelist_accessible_{era}.txt", "w") as f:
        f.write("process.mixData.input.fileNames = cms.untracked.vstring([")
        f.write(",".join(f"'{f}'" for f in filesAccessible))
        f.write("])")

    print(f"\nNumber of total pileup files: {len(files)}")
    print(f"\nNumber of pileup files accessible: {len(filesAccessible)}")

if __name__ == "__main__":
    main()
