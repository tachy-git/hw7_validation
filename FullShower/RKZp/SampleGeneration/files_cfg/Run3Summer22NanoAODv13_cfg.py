# Auto generated configuration file
# using: 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: --eventcontent NANOEDMAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier NANOAODSIM --conditions 133X_mcRun3_2022_realistic_ForNanov13_v1 --step NANO --scenario pp --era Run3 --python_filename GEN-Run3Summer22NanoAODv13-00019_1_cfg.py --fileout file:GEN-Run3Summer22NanoAODv13-00019.root --filein __INPUT__.root --number 1763 --number_out 1763 --no_exec --mc
import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Run3_cff import Run3

process = cms.Process('NANO',Run3)

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
    output = cms.untracked.int32(-1)
)

# Input source
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('__INPUT__'),
    secondaryFileNames = cms.untracked.vstring()
)

process.options = cms.untracked.PSet(
    IgnoreCompletely = cms.untracked.vstring(),
    Rethrow = cms.untracked.vstring(),
    TryToContinue = cms.untracked.vstring(),
    accelerators = cms.untracked.vstring('*'),
    allowUnscheduled = cms.obsolete.untracked.bool,
    canDeleteEarly = cms.untracked.vstring(),
    deleteNonConsumedUnscheduledModules = cms.untracked.bool(True),
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
    modulesToCallForTryToContinue = cms.untracked.vstring(),
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
    annotation = cms.untracked.string('--eventcontent nevts:1763'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# Output definition

process.NANOEDMAODSIMoutput = cms.OutputModule("NanoAODOutputModule",
    compressionAlgorithm = cms.untracked.string('LZMA'),
    compressionLevel = cms.untracked.int32(9),
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string('NANOAODSIM'),
        filterName = cms.untracked.string('')
    ),
    fileName = cms.untracked.string('__OUTPUT__'),
    outputCommands = process.NANOAODSIMEventContent.outputCommands
)

# Additional output definition

# Other statements
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '133X_mcRun3_2022_realistic_ForNanov13_v1', '')

# Path and EndPath definitions
process.nanoAOD_step = cms.Path(process.nanoSequenceMC)
process.endjob_step = cms.EndPath(process.endOfProcess)
process.NANOEDMAODSIMoutput_step = cms.EndPath(process.NANOEDMAODSIMoutput)

# Schedule definition
process.schedule = cms.Schedule(process.nanoAOD_step,process.endjob_step,process.NANOEDMAODSIMoutput_step)
from PhysicsTools.PatAlgos.tools.helpers import associatePatAlgosToolsTask
associatePatAlgosToolsTask(process)

# customisation of the process.

# Automatic addition of the customisation function from Configuration.DataProcessing.Utils
from Configuration.DataProcessing.Utils import addMonitoring 

#call to customisation function addMonitoring imported from Configuration.DataProcessing.Utils
process = addMonitoring(process)

# Automatic addition of the customisation function from PhysicsTools.NanoAOD.nano_cff
from PhysicsTools.NanoAOD.nano_cff import nanoAOD_customizeCommon 

#call to customisation function nanoAOD_customizeCommon imported from PhysicsTools.NanoAOD.nano_cff
process = nanoAOD_customizeCommon(process)

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
    #for name, mod in process.producers_().items():
    #    for attr in mod.parameterNames_():
    #        val = getattr(mod, attr)
    #        if isinstance(val, cms.InputTag) and val.moduleLabel == "generator":
    #            print(f"Patching {name}.{attr}: generator -> source:generator:GEN")
    #            setattr(mod, attr, cms.InputTag("source", "generator", "GEN"))

    return process

process = customizeForExternalMiniAOD(process)

# End of customisation functions


# Customisation from command line

# Add early deletion of temporary data products to reduce peak memory need
from Configuration.StandardSequences.earlyDeleteSettings_cff import customiseEarlyDelete
process = customiseEarlyDelete(process)
# End adding early deletion
