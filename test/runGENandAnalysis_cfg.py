# Auto generated configuration file
# using: 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: UserCode/RivetAnalysis/python/Hadronizer_TuneCUETP8M1_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff.py --filein /store/cmst3/user/psilva/Wmass/powhegbox_Zj/seed_6_pwgevents.lhe --fileout file:Events_6.root --mc --eventcontent RAWSIM --datatier GEN --step GEN -n -1 --conditions 80X_mcRun2_asymptotic_2016_v1
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
                 "event weight to use"
                 )
options.register('input', 
		 '/store/cmst3/user/psilva/Wmass/powhegbox_Zj/seed_6_pwgevents.lhe',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "input file to process"
                 )
options.register('hadronizer',
		 'powhegEmissionVeto_2p_LHE_pythia8',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "hardcoded hadronizer snippet to use"
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
process.load('IOMC.EventVertexGenerators.VtxSmearedRealistic50ns13TeVCollision_cfi')
process.load('GeneratorInterface.Core.genFilterSummary_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(options.maxEvents)
)

# Input source
process.source = cms.Source("LHESource",
			    dropDescendantsOfDroppedBranches = cms.untracked.bool(False),
			    fileNames = cms.untracked.vstring(options.input.split(',')),
			    inputCommands = cms.untracked.vstring('keep *')
)

process.options = cms.untracked.PSet(

)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    annotation = cms.untracked.string('UserCode/RivetAnalysis/python/Hadronizer_TuneCUETP8M1_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff.py nevts:-1'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# Other statements
process.genstepfilter.triggerConditions=cms.vstring("generation_step")
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '80X_mcRun2_asymptotic_2016_v1', '')

#generator definition
if 'powhegEmissionVeto_2p_LHE_pythia8' in options.hadronizer:
	from UserCode.RivetAnalysis.Hadronizer_TuneCUETP8M1_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff import generator
	process.generator=generator.clone()

if 'TuneEE_5C_8TeV_Herwigpp' in options.hadronizer:
	from UserCode.RivetAnalysis.Hadronizer_TuneEE_5C_8TeV_Herwigpp_cff import generator
        process.generator=generator.clone()

if 'powhegEmissionVeto_1p_LHE_pythia8' in options.hadronizer:
	from UserCode.RivetAnalysis.Hadronizer_TuneCUETP8M1_8TeV_powhegEmissionVeto_1p_LHE_pythia8_cff import generator
	process.generator=generator.clone()

if 'primordialKToff' in options.hadronizer:
	process.generator.PythiaParameters.processParameters.append('BeamRemnants:primordialKT = off')

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
						fileName = cms.untracked.string('file:EDMEvents.root'),
						outputCommands = process.RAWSIMEventContent.outputCommands,
						splitLevel = cms.untracked.int32(0)
						)
	
	process.RAWSIMoutput_step = cms.EndPath(process.RAWSIMoutput)
	process.schedule = cms.Schedule(process.generation_step, process.analysis_step, process.genfiltersummary_step, process.endjob_step,process.RAWSIMoutput_step)
else:
	process.schedule = cms.Schedule(process.generation_step, process.analysis_step, process.genfiltersummary_step, process.endjob_step)


# filter all path with the production filter sequence
for path in process.paths:
	getattr(process,path)._seq = process.ProductionFilterSequence * getattr(process,path)._seq

#add RIVET routine
from UserCode.RivetAnalysis.rivet_customise import *
process = customiseZPt(process,0)
process.rivetAnalyzer.OutputFile = cms.string(options.output + '.yoda')
process.rivetAnalyzer.HepMCCollection = cms.InputTag('generatorSmeared')

process.MessageLogger.cerr.FwkReport.reportEvery = 5000
