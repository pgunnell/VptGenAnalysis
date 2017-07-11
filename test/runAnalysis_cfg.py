# Auto generated configuration file
# using:mz 
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
                 "save EDM output"
                 )
options.register('doRivetScan',
                 False,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.bool,
                 "do rivet scan, no ntuple"
                 )
options.register('meWeight',
                 0,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "ME weight to apply in RIVET"
                 )
options.register('input', 
		 '/store/mc/RunIISummer15GS/DYToMuMu_M_50_TuneAZ_8TeV_pythia8/GEN-SIM/GenOnly_MCRUN2_71_V1-v3/100000/02B00892-5740-E711-87B1-A0369F7FCDF4.root',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "input file to process"
                 )
options.parseArguments()


process = cms.Process('ANA')

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
process.source=cms.Source('EmptySource')
process.source = cms.Source("PoolSource",
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

#tfile service                                                                                                                                                 
process.TFileService = cms.Service("TFileService",
				   fileName = cms.string(options.output+'.root')
				   )


# add analysis
process.load('UserCode.VptGenAnalysis.vptAnalysis_cff')


# Path and EndPath definitions
process.generation_step = cms.Path()
process.analysis_step = cms.Path(process.analysis)
process.schedule = cms.Schedule(process.generation_step, process.analysis_step)

#add RIVET routine
from UserCode.RivetAnalysis.rivet_customise import *
if options.doRivetScan:	
	for i in xrange(0,282):
		from GeneratorInterface.RivetInterface.rivetAnalyzer_cfi import rivetAnalyzer
		LHECollection = cms.InputTag('externalLHEProducer') if options.usePoolSource else cms.InputTag('source')
		setattr(process,
			'rivetAnalyzer%d'%i,
			rivetAnalyzer.clone( AnalysisNames = cms.vstring('ATLAS_2015_I1408516_MU'),
					     UseExternalWeight = cms.bool(True),
					     useLHEweights = cms.bool(True),
					     LHEweightNumber = cms.int32(i),
					     LHECollection = LHECollection,
					     HepMCCollection = cms.InputTag('generator'),
					     OutputFile = cms.string( '%s.w%d.yoda'%(options.output,i)),
					     )
			)
		process.generation_step+=getattr(process,'rivetAnalyzer%d'%i)
else:
	process = customiseZPt(process,options.meWeight)
	process.rivetAnalyzer.OutputFile = cms.string(options.output + 'w%d.yoda'%options.meWeight)
	process.rivetAnalyzer.HepMCCollection = cms.InputTag('generator')

process.MessageLogger.cerr.FwkReport.reportEvery = 5000
