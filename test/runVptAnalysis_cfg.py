# Auto generated configuration file
# using:mz 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: UserCode/RivetAnalysis/python/Hadronizer_TuneCUETP8M1_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff.py --filein /store/cmst3/user/psilva/Wmass/powhegbox_Zj/seed_6_pwgevents.lhe --fileout file:Events_6.root --mc --eventcontent RAWSIM --datatier GEN --step GEN -n -1 --conditions 80X_mcRun2_asymptotic_2016_v1
import FWCore.ParameterSet.Config as cms

from FWCore.ParameterSet.VarParsing import VarParsing
options = VarParsing ('python')
options.register('output',            'data.root',                                                   VarParsing.multiplicity.singleton, VarParsing.varType.string, "Output file name")
options.register('saveEDM',           False,                                                         VarParsing.multiplicity.singleton, VarParsing.varType.bool,   "save EDM output")
options.register('saveTuple',         True,                                                         VarParsing.multiplicity.singleton, VarParsing.varType.bool,   "save flat ntuple output")
options.register('usePoolSource',     False,                                                         VarParsing.multiplicity.singleton, VarParsing.varType.bool,   "use LHE from EDM format")
options.register('input',             '/store/cmst3/user/psilva/Wmass/Wminusj/seed_9_pwgevents.lhe', VarParsing.multiplicity.singleton, VarParsing.varType.string, "input file to process")
options.register('noHadronizer',     False,                                                          VarParsing.multiplicity.singleton, VarParsing.varType.bool,   "skip hadronization")
options.register('useMEWeightsForRivet',     True,                                                          VarParsing.multiplicity.singleton, VarParsing.varType.bool,   "use LHE weights")
options.register('weightListForRivet', ','.join(str(i) for i in range(0,121)),                        VarParsing.multiplicity.singleton, VarParsing.varType.string, "Weight list to apply in RIVET (CSV list)")
options.register('seed',              123456789,                                                     VarParsing.multiplicity.singleton, VarParsing.varType.int,    "seed to use")
options.register('nFinal',            2,                                                             VarParsing.multiplicity.singleton, VarParsing.varType.int,    "n particles in final state")
options.register('genParams',
		 'photos=off,ueTune=CUETP8M1,SpaceShower:alphaSvalue=0.100,BeamRemnants:primordialKThard=2.722,MultiPartonInteractions:pT0Ref=2.5',
                 VarParsing.multiplicity.singleton, VarParsing.varType.string, "UE snippet (ueTune), photos usage, pythia8 parameters (CSV list of param=val)"
                 )
options.parseArguments()

process = cms.Process('ANA' if options.noHadronizer else 'GEN' )

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

#add particle level producer
process.load("GeneratorInterface.RivetInterface.genParticles2HepMC_cfi")
process.load("GeneratorInterface.RivetInterface.particleLevel_cfi")
process.particleLevel.lepMinPt  = cms.double(15.)
process.particleLevel.lepMaxEta = cms.double(3.0)

# input configuration
process.maxEvents = cms.untracked.PSet(input = cms.untracked.int32(options.maxEvents))
process.source=cms.Source('EmptySource')
if options.usePoolSource:
	process.source = cms.Source("PoolSource",
				    fileNames = cms.untracked.vstring(options.input.split(',')),
				    inputCommands = cms.untracked.vstring('keep *')
				    )
else:
	process.source = cms.Source("LHESource",
				    dropDescendantsOfDroppedBranches = cms.untracked.bool(False),
				    fileNames = cms.untracked.vstring(options.input.split(',')),
				    inputCommands = cms.untracked.vstring('keep *')
				    )

process.options = cms.untracked.PSet()
process.MessageLogger.cerr.FwkReport.reportEvery = 5000

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
if not options.noHadronizer:
        from UserCode.VptGenAnalysis.GenConfigTools import configureGenerator
        configureGenerator(options,process)
        process.RandomNumberGeneratorService.generator.initialSeed=cms.untracked.uint32(options.seed)
        print 'Seed set to %d'%options.seed
        process.ProductionFilterSequence = cms.Sequence(process.generator)
else:
        print 'Source has already been hadronized, skipping generator sequence'

#tfile service                                                                                                                                                                
process.TFileService = cms.Service("TFileService",
				   fileName = cms.string(options.output+'.root')
				   )


# add analysis
process.load('UserCode.VptGenAnalysis.vptAnalysis_cff')
process.analysis.lheEventProduct = cms.InputTag('externalLHEProducer::LHE') if options.usePoolSource else cms.InputTag('source')

# Path and EndPath definitions
process.generation_step = cms.Path(process.pgen)
process.analysis_step = cms.Path(process.genParticles2HepMC*process.particleLevel)
if options.saveTuple:
        process.analysis_step = cms.Path(process.genParticles2HepMC*process.particleLevel*process.analysis)
process.genfiltersummary_step = cms.EndPath(process.genFilterSummary)
process.endjob_step = cms.EndPath(process.endOfProcess)

if options.saveEDM:
	process.RAWSIMoutput = cms.OutputModule("PoolOutputModule",
						SelectEvents = cms.untracked.PSet( SelectEvents = cms.vstring('generation_step') ),
						dataset = cms.untracked.PSet( dataTier = cms.untracked.string('GEN'),
                                                                              filterName = cms.untracked.string('')
                                                                              ),
						eventAutoFlushCompressedSize = cms.untracked.int32(5242880),
						fileName = cms.untracked.string('file:EDMEvents.root'),
						outputCommands = process.RAWSIMEventContent.outputCommands,
						splitLevel = cms.untracked.int32(0)
						)
	process.RAWSIMoutput_step = cms.EndPath(process.RAWSIMoutput)
        if options.noHadronizer:
                process.schedule = cms.Schedule(process.analysis_step, process.genfiltersummary_step, process.endjob_step,process.RAWSIMoutput_step)
        else:
                process.schedule = cms.Schedule(process.generation_step, process.analysis_step, process.genfiltersummary_step, process.endjob_step,process.RAWSIMoutput_step)
else:
        if options.noHadronizer:
                process.schedule = cms.Schedule(process.analysis_step, process.genfiltersummary_step, process.endjob_step)
        else:
                process.schedule = cms.Schedule(process.generation_step, process.analysis_step, process.genfiltersummary_step, process.endjob_step)

# filter all path with the production filter sequence
if not options.noHadronizer:
        for path in process.paths:
                getattr(process,path)._seq = process.ProductionFilterSequence * getattr(process,path)._seq

#add RIVET routines if needed
from GeneratorInterface.RivetInterface.rivetAnalyzer_cfi import rivetAnalyzer
if len(options.weightListForRivet) :
        print 'Enabling RIVET plugins for the following weights',options.weightListForRivet
        for x in options.weightListForRivet.split(','):
                setattr(process, 'rivetAnalyzer'+x,
                        rivetAnalyzer.clone( AnalysisNames = cms.vstring('ATLAS_2015_I1408516_MU'),
                                             UseExternalWeight = cms.bool(options.useMEWeightsForRivet),
                                             useLHEweights = cms.bool(options.useMEWeightsForRivet),
                                             LHEweightNumber = cms.int32(int(x)),
                                             LHECollection = process.analysis.lheEventProduct,
                                             HepMCCollection = cms.InputTag('generator' if options.noHadronizer else 'generatorSmeared'),
                                             OutputFile = cms.string( 'w%s_%s.yoda'%(x,options.output)),
                                             )
                        )
                process.analysis_step+=getattr(process,'rivetAnalyzer'+x)


