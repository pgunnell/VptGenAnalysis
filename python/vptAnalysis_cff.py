import FWCore.ParameterSet.Config as cms

analysis = cms.EDAnalyzer("VptGenAnalyzer",
                          leptonConeSize = cms.double(0.1),
                          leptonMinPt    = cms.double(15),
                          leptonMaxEta   = cms.double(3.0),
                          genParticles   = cms.InputTag('genParticles'),
                          genEventInfoProduct = cms.InputTag('generator'),
                          lheEventProduct = cms.InputTag('source')
                          )
