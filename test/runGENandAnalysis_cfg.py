# Auto generated configuration file
# using: 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: ZpMM_8TeV_TuneCUETP8M1_cfi --conditions auto:run1_mc -n 10 --eventcontent RAWSIM --relval 9000,200 -s GEN --datatier GEN --beamspot Realistic8TeVCollision --fileout file:step1.root
import FWCore.ParameterSet.Config as cms

from FWCore.ParameterSet.VarParsing import VarParsing
options = VarParsing ('python')
options.register('output', 
		 'data.root',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "Output file name"
                 )
options.register('saveEDM',
                 False,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.bool,
                 "save EDM output"
                 )
options.register('photos',
                 False,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.bool,
                 "add Photos for QED"
                 )
options.register('seed',
                 123456789,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "seed to use"
                 )
options.register('hadronizer',
		 'ZToMuMu_CUEP8M2T4',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "hardcoded hadronizer snippet to use"
                 )
options.register('pdfSet',
		 'NNPDF30_lo_as_0130',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "PDF set to use"
                 )
options.parseArguments()

process = cms.Process('GEN')

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('SimGeneral.MixingModule.mixNoPU_cfi')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('Configuration.StandardSequences.Generator_cff')
process.load('IOMC.EventVertexGenerators.VtxSmearedRealistic8TeVCollision_cfi')
process.load('GeneratorInterface.Core.genFilterSummary_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(options.maxEvents)
)

# Input source
process.source = cms.Source("EmptySource")

process.options = cms.untracked.PSet(

)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    annotation = cms.untracked.string('ZpMM_8TeV_TuneCUETP8M1_cfi nevts:10'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# Additional output definition

# Other statements
process.genstepfilter.triggerConditions=cms.vstring("generation_step")
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'auto:run1_mc', '')

#generator definition
from UserCode.RivetAnalysis.Pythia8HardProcs_cff import getGeneratorFor
getGeneratorFor(hardProc=options.hadronizer,pdfSet=options.pdfSet,process=process,addPhotos=options.photos)

process.ProductionFilterSequence = cms.Sequence(process.generator)

process.RandomNumberGeneratorService.generator.initialSeed=cms.untracked.uint32(options.seed)
print 'Seed initiated to %d'%options.seed
process.ProductionFilterSequence = cms.Sequence(process.generator)

#tfile service                                                                                                                                                                
process.TFileService = cms.Service("TFileService",
				   fileName = cms.string(options.output+'.root')
				   )


# add analysis
process.load('UserCode.VptGenAnalysis.vptAnalysis_cff')


# Path and EndPath definitions
process.generation_step = cms.Path(process.pgen)
process.analysis_step = cms.Path(process.analysis)
process.genfiltersummary_step = cms.EndPath(process.genFilterSummary)
process.endjob_step = cms.EndPath(process.endOfProcess)


# Output definition
if options.saveEDM:
	process.RAWSIMoutput = cms.OutputModule("PoolOutputModule",
						SelectEvents = cms.untracked.PSet(
			SelectEvents = cms.vstring('generation_step')
			),
						dataset = cms.untracked.PSet(
			dataTier = cms.untracked.string('GEN'),
			filterName = cms.untracked.string('')
			),
						eventAutoFlushCompressedSize = cms.untracked.int32(5242880),
						fileName = cms.untracked.string('file:step1.root'),
						outputCommands = process.RAWSIMEventContent.outputCommands,
						splitLevel = cms.untracked.int32(0)
						)

	process.RAWSIMoutput_step = cms.EndPath(process.RAWSIMoutput)
	process.schedule = cms.Schedule(process.generation_step,process.analysis_step,process.genfiltersummary_step,process.endjob_step,process.RAWSIMoutput_step)
else:
	process.schedule = cms.Schedule(process.generation_step,process.analysis_step,process.genfiltersummary_step,process.endjob_step)

# filter all path with the production filter sequence
for path in process.paths:
	getattr(process,path)._seq = process.ProductionFilterSequence * getattr(process,path)._seq 


#add RIVET routine
from UserCode.RivetAnalysis.rivet_customise import *
process = customiseZPt(process,0)
process.rivetAnalyzer.OutputFile = cms.string(options.output + '.yoda')
process.rivetAnalyzer.HepMCCollection = cms.InputTag('generatorSmeared')

process.MessageLogger.cerr.FwkReport.reportEvery = 5000


