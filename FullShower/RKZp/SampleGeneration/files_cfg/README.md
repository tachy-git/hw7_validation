# HepMC to GEN
Herwig generator produces an event file in hepmc format, which cannot be used as an input for `cmsDriver.py` command. Therefore, we need to generate our own configuration file for the GEN step. You can run the configuration file with the following commands:
```
cmsrel CMSSW_10_6_19_patch3
cd CMSSW_10_6_19_patch3/src
cmsenv
cmsRun hepmc2gen.py
```
`hepmc2gen.py` is based on [hepmc2gen.py](https://github.com/cms-sw/cmssw/blob/master/IOMC/Input/test/hepmc2gen.py). The condition for the GEN configuration file and the remaining steps are created with reference to the flow of `QCD_HT300to500_TuneCH3_13TeV-madgraphMLM-herwig7` dataset for Run2 UL.

[RunIISummer20UL](https://cms-pdmv-prod.web.cern.ch/mcm/chained_requests?prepid=JME-chain_RunIISummer20UL16wmLHEGEN_flowRunIISummer20UL16SIM_flowRunIISummer20UL16DIGIPremix_flowRunIISummer20UL16HLT_flowRunIISummer20UL16RECO_flowRunIISummer20UL16MiniAODv2_flowRunIISummer20UL16NanoAODHWGv9-00005&page=0&shown=15)

[RunIISummer20UL16APV](https://cms-pdmv-prod.web.cern.ch/mcm/chained_requests?prepid=JME-chain_RunIISummer20UL16wmLHEGENAPV_flowRunIISummer20UL16SIMAPV_flowRunIISummer20UL16DIGIPremixAPV_flowRunIISummer20UL16HLTAPV_flowRunIISummer20UL16RECOAPV_flowRunIISummer20UL16MiniAODAPVv2_flowRunIISummer20UL16NanoAODAPVHWGv9-00002&page=0)

[RunIISummer20UL17](https://cms-pdmv-prod.web.cern.ch/mcm/chained_requests?prepid=JME-chain_RunIISummer20UL17wmLHEGEN_flowRunIISummer20UL17SIM_flowRunIISummer20UL17DIGIPremix_flowRunIISummer20UL17HLT_flowRunIISummer20UL17RECO_flowRunIISummer20UL17MiniAODv2_flowRunIISummer20UL17NanoAODHWGv9-00001&page=0&shown=15)

[RunIISummer20UL18](https://cms-pdmv-prod.web.cern.ch/mcm/chained_requests?prepid=JME-chain_RunIISummer20UL18wmLHEGEN_flowRunIISummer20UL18SIM_flowRunIISummer20UL18DIGIPremix_flowRunIISummer20UL18HLT_flowRunIISummer20UL18RECO_flowRunIISummer20UL18MiniAODv2_flowRunIISummer20UL18NanoAODHWGv9-00007&page=0&shown=15)

## 1. Input hepmc file as a generator source
We directly puts the hepmc file as an input instead of using the `EDProducer` module. Here, `firstLuminosityBlockForEachRun` gives the events the luminosity block number. For simplicity, We set them to be all 1. (Do we need to modify this part so that each event has a unique set of {run:lumi:event}?)
```
process.source = cms.Source("MCFileSource",
            fileNames = cms.untracked.vstring('file:LHC-1.hepmc'),
            firstLuminosityBlockForEachRun = cms.untracked.VLuminosityBlockID([]),
            )
```
```
process.genParticles.src= cms.InputTag("source","generator")
```


## 2. Vertex Smearing
By default, the nominal vertex of a generated event is (0,0,0). However, the interaction region (IR) is not point-like in real life. You can implement the vertex smearing part as shown below referring to [Twiki](https://twiki.cern.ch/twiki/bin/view/CMSPublic/SWGuideVertexSmearing#Algorithms_and_Modules). The parameter set can be found on [cms-sw github](https://github.com/cms-sw/cmssw/tree/eb2285a1aa1c79922fc9ec02d1e750fc8872a04e/IOMC/EventVertexGenerators/python).
```
from IOMC.EventVertexGenerators.VtxSmearedParameters_cfi import *
VtxSmearedCommon.src=cms.InputTag("source","generator")
process.generatorSmeared = cms.EDProducer("BetafuncEvtVtxGenerator",
    Realistic25ns13TeV2016CollisionVtxSmearingParameters,
    VtxSmearedCommon
    )
process.RandomNumberGeneratorService = cms.Service("RandomNumberGeneratorService",
        generatorSmeared  = cms.PSet( initialSeed = cms.untracked.uint32(42),
            engineName = cms.untracked.string('TRandom3'),
            ),
        )
```

RunIISummer20UL16: `VtxSmearedRealistic25ns13TeV2016Collision_cfi.py`

RunIISummer20UL16APV: `VtxSmearedRealistic25ns13TeV2016Collision_cfi`

RunIISummer20UL17: `VtxSmearedRealistic25ns13TeVEarly2017Collision_cfi`

RunIISummer20UL18: `VtxSmearedRealistic25ns13TeVEarly2018Collision_cfi`


Vertex smearing is necessary for SIM step. If you do not implement this part, you will encounter an error like below.
```
An exception of category 'ProductNotFound' occurred while
   [0] Processing  Event run: 1 lumi: 1 event: 1 stream: 0
   [1] Running path 'RAWSIMoutput_step'
   [2] Prefetching for module PoolOutputModule/'RAWSIMoutput'
   [3] Calling method for module OscarMTProducer/'g4SimHits'
Exception Message:
Principal::getByToken: Found zero products matching all criteria
Looking for type: edm::HepMCProduct
Looking for module label: generatorSmeared
Looking for productInstanceName: 
```


## 3. Global Tag (GT)
The information about the geometry and the magnetic field are stored in database. The GT is needed to fetch these information that is matching with the era.
```
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '106X_mcRun2_asymptotic_v13', '')
```
You can find the GT for official MC producitons on [Twiki](https://twiki.cern.ch/twiki/bin/view/CMSPublic/AlCaGTCompaigns). Without the proper GT, you will encounter an error like below.
```
Unable to find plugin 'EcalSimPulseShapeRcd@NewProxy' in category 'CondProxyFactory'
```

RunIISummer20UL16: `106X_mcRun2_asymptotic_v13`

RunIISummer20UL16APV: `106X_mcRun2_asymptotic_preVFP_v8`

RunIISummer20UL17: `106X_mc2017_realistic_v6`

RunIISummer20UL18: `106X_upgrade2018_realistic_v4`



## 4. Gen Filter
We cannot use EDFilter modules like `MCSmartSingleParticleFilter` as we did with Pythia8. Instead, we will use modules named

`GenParticleSelector`: EDFilter module selecting gen particles that satisfy the 'cut'

`CandViewCountFilter`: EDFilter module filtering events if the input collection has at least the specified number of entries

`CandViewShallowCloneCombiner`: EDProduer module combining particle candidates to form composite objects


Here, we are trying to select events with at least one Z prime boson and opposite-sign muon pair originating from the Z prime. For selecting the muon pair, there are two options. The first option is combining muon pair and then applying the mass cut to it. The second option is selecting two final state muons. We used the second option. **Note that the pt cut of muons differs across eras.**
```
# Z prime
process.selectZprime = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId == 1023"),
)
process.filterZprime = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectZprime"),
    minNumber = cms.uint32(1),
)
# muon
# option 1: muon pair --> combined muon pair and apply the mass cut
process.selectMu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("abs(pdgId)==13 && pt>10. && abs(eta)<2.4")
)
process.selectMupair = cms.EDProducer("CandViewShallowCloneCombiner",
    decay = cms.string("selectMu@+ selectMu@-"),
    checkCharge = cms.bool(True),
    cut = cms.string("0 < mass < 10"),
)
process.filterMupair = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectMupair"),
    minNumber = cms.uint32(1),
)
# option 2: select two final state muons
process.selectFinalMu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId==13 && pt>10. && abs(eta)<2.4 && status==1")
)
process.selectFinalAntimu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId==-13 && pt>10. && abs(eta)<2.4 && status==1")
)
process.filterFinalMu = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectFinalMu"),
    minNumber = cms.uint32(1),
)
process.filterFinalAntimu = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectFinalAntimu"),
    minNumber = cms.uint32(1),
)
```
These modules should be defind in the path:
```
# option 1
#process.filterSequence = cms.Sequence(process.selectZprime*process.filterZprime*process.selectMu*process.selectMupair*process.filterMupair)
# option 2
process.filterSequence = cms.Sequence(process.selectZprime*process.filterZprime*process.selectFinalMu*process.selectFinalAntimu*process.filterFinalMu*process.filterFinalAntimu)
process.path = cms.Path(process.genParticles*process.filterSequence*process.generatorSmeared)
process.outpath = cms.EndPath(process.output)
```
The path should be used to select events inside the output module. Note that you can drop unnecessary branches to save the memory.
```
process.output = cms.OutputModule("PoolOutputModule",
                fileName = cms.untracked.string('gen.root'),
                SelectEvents = cms.untracked.PSet(
                    SelectEvents = cms.vstring('path')
                    ),
                outputCommands = cms.untracked.vstring('keep *','drop *_selectZprime_*_*','drop *_selectFinalMu_*_*','drop *_selectFinalAntimu_*_*','drop *_selectMupair_*_*')
            )

```

## 5. GenEventInfoProduct
`GenEventInfoProduct` contains information about weights, scales, PDF, and so on... If the GEN file is produced by generator module, `GenEventInfoProduct` will be saved as
```
GenEventInfoProduct                   "generator"                 ""        "GEN"
```
(You can check it by `edmDumpEventContent`)
But here, we used a hepmc file as a source, so `GenEventInfoProduct` will be saved as
```
GenEventInfoProduct                   "source"             "generator"   "GEN"
```

Since the module and the label are different, this is dropped after the SIM step unless you specify to save this information. Please add `+['keep GenEventInfoProduct_*_*_*']` to `outputCommands` to configuration file in all steps in order to keep this information til the MiniAODv2 is generated. You can refer to [this code snippet](https://github.com/tachy-git/hw7_validation/blob/193c9fd84f2cab2cd3b0228743511e8b7d14d2eb/FullShower/HAHM/13TeV/SampleGeneration/files_cfg/RunIISummer20UL16SIM_cfg.py#L57).

For SKFlatAnalyzer users,

If you want to make Ntuples by using SKFlatMaker, please change [the line](https://github.com/CMSSNU/SKFlatMaker/blob/cc83aafc60ecb6fea1e068b49cc48befdacc5e7b/SKFlatMaker/src/SKFlatMaker.cc#L70) in `src/SKFlatMaker.cc`.
from
```
GenEventInfoToken                   ( consumes< GenEventInfoProduct >                       (iConfig.getUntrackedParameter<edm::InputTag>("GenEventInfo")) ),
```
to 
```
GenEventInfoToken                   ( consumes< GenEventInfoProduct >                       (edm::InputTag("source","generator")) )
```

## 6. TO DO
1. There's no information about GENJET and GENMET. 
