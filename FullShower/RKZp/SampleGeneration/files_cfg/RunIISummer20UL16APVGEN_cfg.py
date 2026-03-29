import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Run2_2016_HIPM_cff import Run2_2016_HIPM

process = cms.Process('GEN',Run2_2016_HIPM)

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('SimGeneral.MixingModule.mixNoPU_cfi')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('Configuration.StandardSequences.Generator_cff')
process.load('IOMC.EventVertexGenerators.VtxSmearedRealistic25ns13TeV2016Collision_cfi')
process.load('GeneratorInterface.Core.genFilterSummary_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(-1)
)

# Input source
process.source = cms.Source("MCFileSource",
            fileNames = cms.untracked.vstring('file:__INPUT__.hepmc'),
            firstLuminosityBlockForEachRun = cms.untracked.VLuminosityBlockID([]),
            )

# Output definition
process.output = cms.OutputModule("PoolOutputModule",
                fileName = cms.untracked.string('file:__OUTPUT__.root'),
                SelectEvents = cms.untracked.PSet(
                    SelectEvents = cms.vstring('path')
                    ),
                outputCommands = cms.untracked.vstring('keep *','drop *_selectZprime_*_*','drop *_selectFinalMu_*_*','drop *_selectFinalAntimu_*_*','drop *_selectMupair_*_*')
            )

# Other statements
process.genParticles.src= cms.InputTag("source","generator")
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '106X_mcRun2_asymptotic_preVFP_v8', '')
'''
# For debugging
process.MessageLogger = cms.Service("MessageLogger",
    destinations = cms.untracked.vstring('cout'),
    cout = cms.untracked.PSet(
        threshold = cms.untracked.string('INFO')
    )
)
'''

# Gen Filter
# Z prime
process.selectZprime = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId == 32"),
)
process.filterZprime = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectZprime"),
    minNumber = cms.uint32(1),
)
# muon
# option 1: muon pair --> combined muon pair and apply the mass cut
'''
process.selectMu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("abs(pdgId)==13 && pt>10. && abs(eta)<2.5")
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
'''
# option 2: select two final state muons
process.selectFinalMu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId==13 && pt>8. && abs(eta)<2.5 && status==1")
)
process.selectFinalAntimu = cms.EDFilter("GenParticleSelector",
    src = cms.InputTag("genParticles"),
    cut = cms.string("pdgId==-13 && pt>8. && abs(eta)<2.5 && status==1")
)
process.filterFinalMu = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectFinalMu"),
    minNumber = cms.uint32(1),
)
process.filterFinalAntimu = cms.EDFilter("CandViewCountFilter",
    src = cms.InputTag("selectFinalAntimu"),
    minNumber = cms.uint32(1),
)

# Vertex smearing
from IOMC.EventVertexGenerators.VtxSmearedParameters_cfi import *
VtxSmearedCommon.src=cms.InputTag("source","generator")
process.generatorSmeared = cms.EDProducer("BetafuncEvtVtxGenerator",
    Realistic25ns13TeV2016CollisionVtxSmearingParameters,
    VtxSmearedCommon
    )
process.RandomNumberGeneratorService = cms.Service("RandomNumberGeneratorService",
        generatorSmeared  = cms.PSet( initialSeed = cms.untracked.uint32(__RANDOM__),
            engineName = cms.untracked.string('TRandom3'),
            ),
        )

# Path and EndPath definitions
# option 1
#process.filterSequence = cms.Sequence(process.selectZprime*process.filterZprime*process.selectMu*process.selectMupair*process.filterMupair)
# option 2
process.filterSequence = cms.Sequence(process.selectZprime*process.filterZprime*process.selectFinalMu*process.selectFinalAntimu*process.filterFinalMu*process.filterFinalAntimu)
process.path = cms.Path(process.genParticles*process.filterSequence*process.generatorSmeared)
process.outpath = cms.EndPath(process.output)
