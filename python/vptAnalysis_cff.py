import FWCore.ParameterSet.Config as cms

analysis = cms.EDAnalyzer("VptGenAnalyzer",                          
                          leptonMinPt    = cms.double(15),
                          leptonMaxEta   = cms.double(3.0),
                          leptons        = cms.InputTag('particleLevel:leptons'),
                          mets           = cms.InputTag('particleLevel:mets'),
                          neutrinos      = cms.InputTag('particleLevel:neutrinos'),
                          genEventInfoProduct = cms.InputTag('generator'),
                          lheEventProduct = cms.InputTag('externalLHEProducer') #source')
                          )
