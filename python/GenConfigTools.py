import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8PowhegEmissionVetoSettings_cfi import *
from Configuration.Generator.Pythia8CommonSettings_cfi import *

def configureGenerator(options,process):
    """configure the generator in the process"""

    #readoutConfiguration
    ueParameters=[]
    ueTune='CUETP8M1'
    photos='off'
    for arg in options.genParams.split(','):
        param,val=arg.split('=')
        if param=='ueTune'   : ueTune=val
        elif param=='photos' : photos=val
        else                 : ueParameters.append( arg )

    #prepare ueParams
    tuneSpecific=[]
    if ueTune=='CUETP8M1':
        tuneSpecific= [ 'Tune:pp 14',
                        'Tune:ee 7',
                        'MultipartonInteractions:pT0Ref=2.4024',
                        'MultipartonInteractions:ecmPow=0.25208',
                        'MultipartonInteractions:expPow=1.6',
                        'PDF:pSet=LHAPDF6:NNPDF30_lo_as_0130' ]

    #override if given in command line
    ictr=0
    for x in tuneSpecific:
        xparam=x.split('=')[0]

        overriden=False
        for y in ueParameters:
            yparam=y.split('=')[0]
            if xparam==yparam : overriden=True
        if overriden : continue

        ueParameters.insert(ictr,x)
        ictr+=1

    #debug
    print '#'*50
    print 'UE configuration will be made with the following set of parameters'
    print ueParameters
    print 'photos =',photos
    print '#'*50
        
    if photos=='on':
        process.generator = cms.EDFilter("Pythia8HadronizerFilter",
                                         maxEventsToPrint = cms.untracked.int32(0),
                                         pythiaPylistVerbosity = cms.untracked.int32(1),
                                         filterEfficiency = cms.untracked.double(1.0),
                                         pythiaHepMCVerbosity = cms.untracked.bool(False),
                                         comEnergy = cms.double(8000.),
                                         ExternalDecays = cms.PSet( Photos = cms.untracked.PSet(),
                                                                    parameterSets = cms.vstring( "Photos" )
                                                                    ),
                                         PythiaParameters = cms.PSet( pythia8CommonSettingsBlock,
                                                                      pythia8PowhegEmissionVetoSettingsBlock,
                                                                      processParameters = cms.vstring( 'POWHEG:nFinal = %d'%options.nFinal,   
                                                                                                       ## Number of final state particles (BEFORE THE DECAYS) in the LHE other than emitted extra parton
                                                                                                       'TimeShower:mMaxGamma = 1.0',
                                                                                                       # cutting off lepton-pair production in the electromagnetic show to not overlap with ttZ/gamma* samples
                                                                                                       ),
                                                                      ueParameters = cms.vstring(ueParameters),
                                                                      fsrParameters = cms.vstring('TimeShower:QEDshowerByL=off',
                                                                                                  'TimeShower:QEDshowerByQ = off',
                                                                                                  'TimeShower:QEDshowerByGamma = off',
                                                                                                  'ParticleDecays:allowPhotonRadiation = off'),
                                                                      parameterSets = cms.vstring('pythia8CommonSettings',
                                                                                                  'pythia8PowhegEmissionVetoSettings',
                                                                                                  'processParameters',
                                                                                                  'ueParameters',
                                                                                                  'fsrParameters'
                                                                                                  )
                                                                      )
                                         )
    else:
        process.generator = cms.EDFilter("Pythia8HadronizerFilter",
                                         maxEventsToPrint = cms.untracked.int32(1),
                                         pythiaPylistVerbosity = cms.untracked.int32(1),
                                         filterEfficiency = cms.untracked.double(1.0),
                                         pythiaHepMCVerbosity = cms.untracked.bool(False),
                                         comEnergy = cms.double(8000.),
                                         PythiaParameters = cms.PSet( pythia8CommonSettingsBlock,
                                                                      pythia8PowhegEmissionVetoSettingsBlock,
                                                                      ueParameters = cms.vstring(ueParameters),
                                                                      processParameters = cms.vstring( 'POWHEG:nFinal = %d'%options.nFinal,
                                                                                                       ## Number of final state particles (BEFORE THE DECAYS) in the LHE other than emitted extra parton
                                                                                                       'TimeShower:mMaxGamma = 1.0',
                                                                                                       # cutting off lepton-pair production in the electromagnetic show to not overlap with ttZ/gamma* samples
                                                                                                       ),
                                                                      parameterSets = cms.vstring('pythia8CommonSettings',
                                                                                                  'pythia8PowhegEmissionVetoSettings',
                                                                                                  'processParameters',
                                                                                                  'ueParameters'
                                                                                                  )
                                                                      )
                                         )
