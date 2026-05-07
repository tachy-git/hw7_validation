import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Run3_cff import Run3
from Configuration.Eras.Modifier_run3_nanoAOD_124_cff import run3_nanoAOD_124

process = cms.Process('NANO',Run3,run3_nanoAOD_124)

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('SimGeneral.MixingModule.mixNoPU_cfi')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('PhysicsTools.NanoAOD.nano_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(-1),
    output = cms.optional.untracked.allowed(cms.int32,cms.PSet)
)

# Input source
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('file:__INPUT__.root'),
    secondaryFileNames = cms.untracked.vstring()
)

process.options = cms.untracked.PSet(
    FailPath = cms.untracked.vstring(),
    IgnoreCompletely = cms.untracked.vstring(),
    Rethrow = cms.untracked.vstring(),
    SkipEvent = cms.untracked.vstring(),
    accelerators = cms.untracked.vstring('*'),
    allowUnscheduled = cms.obsolete.untracked.bool,
    canDeleteEarly = cms.untracked.vstring(),
    deleteNonConsumedUnscheduledModules = cms.untracked.bool(False),
    dumpOptions = cms.untracked.bool(False),
    emptyRunLumiMode = cms.obsolete.untracked.string,
    eventSetup = cms.untracked.PSet(
        forceNumberOfConcurrentIOVs = cms.untracked.PSet(
            allowAnyLabel_=cms.required.untracked.uint32
        ),
        numberOfConcurrentIOVs = cms.untracked.uint32(0)
    ),
    fileMode = cms.untracked.string('FULLMERGE'),
    forceEventSetupCacheClearOnNewRun = cms.untracked.bool(False),
    holdsReferencesToDeleteEarly = cms.untracked.VPSet(),
    makeTriggerResults = cms.obsolete.untracked.bool,
    modulesToIgnoreForDeleteEarly = cms.untracked.vstring(),
    numberOfConcurrentLuminosityBlocks = cms.untracked.uint32(0),
    numberOfConcurrentRuns = cms.untracked.uint32(1),
    numberOfStreams = cms.untracked.uint32(0),
    numberOfThreads = cms.untracked.uint32(1),
    printDependencies = cms.untracked.bool(False),
    sizeOfStackForThreadsInKB = cms.optional.untracked.uint32,
    throwIfIllegalParameter = cms.untracked.bool(True),
    wantSummary = cms.untracked.bool(False)
)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    annotation = cms.untracked.string('step1 nevts:1'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# ======================================================
# Use NanoAODOutputModule to get standard flat TTree
# with readable branch names like Muon_pt, Electron_eta.
# PoolOutputModule (NANOEDMAOD) produces ugly EDM object
# branch names like nanoaodFlatTable_vertexTable_pv_NANO.
# ======================================================
process.NANOAODSIMoutput = cms.OutputModule("NanoAODOutputModule",
    compressionAlgorithm = cms.untracked.string('LZMA'),
    compressionLevel = cms.untracked.int32(9),
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string('NANOAODSIM'),
        filterName = cms.untracked.string('')
    ),
    fileName = cms.untracked.string('file:__OUTPUT__.root'),
    outputCommands = process.NANOAODSIMEventContent.outputCommands
)

# Other statements
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '124X_mcRun3_2022_realistic_v12', '')

# Path and EndPath definitions
process.nanoAOD_step = cms.Path(process.nanoSequenceMC)
process.endjob_step = cms.EndPath(process.endOfProcess)
process.NANOAODSIMoutput_step = cms.EndPath(process.NANOAODSIMoutput)

# Schedule definition
process.schedule = cms.Schedule(process.nanoAOD_step,process.endjob_step,process.NANOAODSIMoutput_step)
from PhysicsTools.PatAlgos.tools.helpers import associatePatAlgosToolsTask
associatePatAlgosToolsTask(process)

# Setup FWK for multithreaded
process.options.numberOfThreads = 4
process.options.numberOfStreams = 0

# Automatic addition of the customisation function from PhysicsTools.NanoAOD.nano_cff
from PhysicsTools.NanoAOD.nano_cff import nanoAOD_customizeMC
process = nanoAOD_customizeMC(process)

# ======================================================
# Custom fix for MiniAOD input produced by external GEN.
# 1) Remove all modules that depend on missing products:
#    GenRunInfoProduct, HepMCProduct, GenFilterInfo
# 2) Remap InputTags pointing to 'generator' label to
#    actual location in this file: source:generator:GEN
# ======================================================
def customizeForExternalMiniAOD(process):

    task_cleanup = {
        "particleLevelTask": [
            "genParticles2HepMC",
            "genParticles2HepMCHiggsVtx",
            "particleLevel",
            "tautagger",
            "rivetProducerHTXS",
        ],
        "particleLevelTablesTask": [
            "rivetLeptonTable",
            "rivetPhotonTable",
            "rivetMetTable",
            "HTXSCategoryTable",
            "lheInfoTable",
        ],
        "electronMCTask": [
            "tautaggerForMatching",
            "matchingElecPhoton",
            "electronsMCMatchForTableAlt",
            "electronMCTable",
        ],
        "lowPtElectronMCTask": [
            "matchingLowPtElecPhoton",
            "lowPtElectronsMCMatchForTableAlt",
            "lowPtElectronMCTable",
        ],
        "globalTablesMCTask": [
            "genFilterEfficiencyProducer",
            "genFilterTable",
        ],
    }

    for taskname, modnames in task_cleanup.items():
        if hasattr(process, taskname):
            task = getattr(process, taskname)
            for modname in modnames:
                if hasattr(process, modname):
                    try:
                        task.remove(getattr(process, modname))
                        print(f"Removed {modname} from {taskname}")
                    except Exception:
                        pass

    # ======================================================
    # Remap all InputTags with moduleLabel 'generator' to
    # actual location: module=source, instance=generator, process=GEN
    # EDAlias cannot remap across process boundaries so we
    # patch each consumer's InputTag directly instead.
    # ======================================================
    for name, mod in process.producers_().items():
        for attr in mod.parameterNames_():
            val = getattr(mod, attr)
            if isinstance(val, cms.InputTag) and val.moduleLabel == "generator":
                print(f"Patching {name}.{attr}: generator -> source:generator:GEN")
                setattr(mod, attr, cms.InputTag("source", "generator", "GEN"))

    return process

process = customizeForExternalMiniAOD(process)

# Add early deletion of temporary data products to reduce peak memory need
from Configuration.StandardSequences.earlyDeleteSettings_cff import customiseEarlyDelete
process = customiseEarlyDelete(process)
# End adding early deletion
