// -*- C++ -*-
//
// Package:    UserCode/VptGenAnalyzer
// Class:      VptGenAnalyzer
// 
/**\class VptGenAnalyzer VptGenAnalyzer.cc UserCode/VptGenAnalyzer/plugins/VptGenAnalyzer.cc

 Description: [one line class summary]

 Implementation:
     [Notes on implementation]
*/
//
// Original Author:  Pedro Vieira De Castro Ferreira Da Silva
//         Created:  Tue, 25 Oct 2016 10:05:31 GMT
//
//


// system include files
#include <memory>
#include "FWCore/Framework/interface/Frameworkfwd.h"
#include "FWCore/Framework/interface/one/EDAnalyzer.h"
#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/MakerMacros.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "DataFormats/HepMCCandidate/interface/GenParticle.h"
#include "SimDataFormats/GeneratorProducts/interface/GenEventInfoProduct.h"
#include "SimDataFormats/GeneratorProducts/interface/LHEEventProduct.h"
#include "CommonTools/UtilAlgos/interface/TFileService.h"
#include "FWCore/ServiceRegistry/interface/Service.h"

#include "fastjet/JetDefinition.hh"
#include "fastjet/ClusterSequence.hh" 

#include "TTree.h"

struct MiniEvent_t
{
  Int_t nw;
  Float_t w[500];
};

typedef reco::Particle::LorentzVector LorentzVector;
typedef fastjet::JetDefinition JetDef;

class VptGenAnalyzer : public edm::one::EDAnalyzer<edm::one::SharedResources>  
{
public:
  explicit VptGenAnalyzer(const edm::ParameterSet&);
  ~VptGenAnalyzer();
  static void fillDescriptions(edm::ConfigurationDescriptions& descriptions);

private:
  virtual void beginJob() override;
  virtual void analyze(const edm::Event&, const edm::EventSetup&) override;
  virtual void endJob() override;
  
  bool isBHadron(const reco::Candidate* p) const;
  bool isBHadron(const unsigned int pdgId) const;
  bool isFromHadron(const reco::Candidate* p) const;
  
  edm::EDGetTokenT<edm::View<reco::Candidate> > genParticleToken_;
  edm::EDGetTokenT<GenEventInfoProduct> generatorToken_;
  edm::EDGetTokenT<LHEEventProduct> generatorlheToken_;
  const float leptonConeSize_, leptonMinPt_, leptonMaxEta_;
  
  std::shared_ptr<JetDef> fjLepDef_;
  
  edm::Service<TFileService> fs;
  TTree *tree_;
  MiniEvent_t ev_;
};

//
VptGenAnalyzer::VptGenAnalyzer(const edm::ParameterSet &pset) :
  genParticleToken_(consumes<edm::View<reco::Candidate> >(pset.getParameter<edm::InputTag>("genParticles"))),
  generatorToken_(consumes<GenEventInfoProduct>(edm::InputTag("generator"))),
  generatorlheToken_(consumes<LHEEventProduct>(edm::InputTag("externalLHEProducer",""))),
  leptonConeSize_(pset.getParameter<double>("leptonConeSize")),
  leptonMinPt_(pset.getParameter<double>("leptonMinPt")),
  leptonMaxEta_(pset.getParameter<double>("leptonMaxEta"))
{
  fjLepDef_ = std::shared_ptr<JetDef>(new JetDef(fastjet::antikt_algorithm, leptonConeSize_));
  
  tree_=fs->make<TTree>("data","data");
  tree_->Branch("nw", &ev_.nw, "nw/F");
  tree_->Branch("w",   ev_.w,  "w[nw]/F");
}


//
VptGenAnalyzer::~VptGenAnalyzer()
{
}


//
void VptGenAnalyzer::analyze(const edm::Event& iEvent, const edm::EventSetup& iSetup)
{
   using namespace edm;

   //event weights
   edm::Handle<GenEventInfoProduct> evt;
   iEvent.getByToken( generatorToken_,evt);   
   edm::Handle<LHEEventProduct> evet;
   iEvent.getByToken(generatorlheToken_, evet);
   ev_.nw=0;
   if(evet.isValid())
     {
       double asdd=evet->originalXWGTUP();
       for(unsigned int i=0  ; i<evet->weights().size();i++){
	 double asdde=evet->weights()[i].wgt;
	 ev_.w[ev_.nw]=evt->weight()*asdde/asdd;
	 ev_.nw++;
       }

   //get genParticles
   edm::Handle<edm::View<reco::Candidate> > genParticleHandle;
   iEvent.getByToken(genParticleToken_, genParticleHandle);

   // Collect stable leptons and neutrinos, compute momentum-balance flavours
   std::vector<size_t> lepPhoIdxs,nuIdxs;
   LorentzVector balance(0,0,0,0), chBalance(0,0,0,0);
   for ( size_t i=0, n=genParticleHandle->size(); i<n; ++i )
     {
       const reco::Candidate& p = genParticleHandle->at(i);
       if ( p.status() != 1 ) continue;
       if ( p.numberOfMothers() == 0 ) continue; // Skip orphans (if exists)
       //if ( p.mother()->status() == 4 ) continue; // Treat particle as hadronic if directly from the incident beam (protect orphans in MINIAOD)

       //fiducial cut
       if ( p.pt()<0.5 || fabs(p.eta())>4.7) continue;

       //momentum-balance
       balance += p.p4();
       if( fabs(p.eta())<2.4 && p.charge()!=0) chBalance += p.p4();

       //save leptons and neutrinos (exclude b-hadrons)
       if ( isFromHadron(&p) ) continue;
       const int absPdgId = abs(p.pdgId());
       switch ( absPdgId )
	 {
	 case 11: case 13: case 22: // leptons and photons
	   lepPhoIdxs.push_back(i);
	   break;
	 case 12: case 14: case 16: //neutrions
	   nuIdxs.push_back(i);
	   break;
	 }
     }

   // build dressed leptons with anti-kt(0.1) algorithm
   std::vector<fastjet::PseudoJet> fjLepInputs;
   fjLepInputs.reserve(lepPhoIdxs.size());
   for ( auto index : lepPhoIdxs )
     {
       const reco::Candidate& p = genParticleHandle->at(index);
       if ( std::isnan(p.pt()) or p.pt() <= 0 ) continue;
       fjLepInputs.push_back(fastjet::PseudoJet(p.px(), p.py(), p.pz(), p.energy()));
       fjLepInputs.back().set_user_index(index);
     }
   fastjet::ClusterSequence fjLepClusterSeq(fjLepInputs, *fjLepDef_);
   std::vector<fastjet::PseudoJet> fjLepJets = fastjet::sorted_by_pt(fjLepClusterSeq.inclusive_jets(leptonMinPt_));
   
   //prune the output
   std::vector<std::pair<reco::CandidatePtr,LorentzVector > > lepJets;
   for ( auto& fjJet : fjLepJets )
     {
       if ( abs(fjJet.eta()) > leptonMaxEta_ ) continue;
       
       const std::vector<fastjet::PseudoJet> fjConstituents = fastjet::sorted_by_pt(fjJet.constituents());
       std::vector<reco::CandidatePtr> constituents;
       reco::CandidatePtr lepCand;
       for ( auto& fjConstituent : fjConstituents )
	 {
	   const size_t index = fjConstituent.user_index();
	   reco::CandidatePtr cand = genParticleHandle->ptrAt(index);
	   const int absPdgId = abs(cand->pdgId());
	   if ( absPdgId == 11 or absPdgId == 13 )
	     {
	       if ( lepCand.isNonnull() and lepCand->pt() > cand->pt() ) continue; // Choose one with highest pt
	       lepCand = cand;
	     }
	   constituents.push_back(cand);
	 }
       if ( lepCand.isNull() ) continue;
       if ( lepCand->pt() < fjJet.pt()/2 ) continue; // Central lepton must be the major component
       
       LorentzVector dressedP4(fjJet.px(), fjJet.py(), fjJet.pz(), fjJet.E());
       lepJets.push_back( std::pair<reco::CandidatePtr, LorentzVector>(lepCand,dressedP4) );
     }
     }
}
   
bool VptGenAnalyzer::isFromHadron(const reco::Candidate* p) const
{
  for ( size_t i=0, n=p->numberOfMothers(); i<n; ++i )
    {
    const reco::Candidate* mother = p->mother(i);
    if ( mother->numberOfMothers() == 0 ) continue; // Skip incident beam
    const int pdgId = abs(mother->pdgId());

    if ( pdgId > 100 ) return true;
    else if ( isFromHadron(mother) ) return true;
  }
  return false;
}


bool VptGenAnalyzer::isBHadron(const reco::Candidate* p) const
{
  const unsigned int absPdgId = abs(p->pdgId());
  if ( !isBHadron(absPdgId) ) return false;

  // Do not consider this particle if it has B hadron daughter
  // For example, B* -> B0 + photon; then we drop B* and take B0 only
  for ( int i=0, n=p->numberOfDaughters(); i<n; ++i )
  {
    const reco::Candidate* dau = p->daughter(i);
    if ( isBHadron(abs(dau->pdgId())) ) return false;
  }

  return true;
}

bool VptGenAnalyzer::isBHadron(const unsigned int absPdgId) const
{
  if ( absPdgId <= 100 ) return false; // Fundamental particles and MC internals
  if ( absPdgId >= 1000000000 ) return false; // Nuclei, +-10LZZZAAAI

  // General form of PDG ID is 7 digit form
  // +- n nr nL nq1 nq2 nq3 nJ
  //const int nJ = absPdgId % 10; // Spin
  const int nq3 = (absPdgId / 10) % 10;
  const int nq2 = (absPdgId / 100) % 10;
  const int nq1 = (absPdgId / 1000) % 10;

  if ( nq3 == 0 ) return false; // Diquarks
  if ( nq1 == 0 and nq2 == 5 ) return true; // B mesons
  if ( nq1 == 5 ) return true; // B baryons

  return false;
}



// ------------ method called once each job just before starting event loop  ------------
void 
VptGenAnalyzer::beginJob()
{
}

// ------------ method called once each job just after ending the event loop  ------------
void 
VptGenAnalyzer::endJob() 
{
}

// ------------ method fills 'descriptions' with the allowed parameters for the module  ------------
void
VptGenAnalyzer::fillDescriptions(edm::ConfigurationDescriptions& descriptions) {
  //The following says we do not know what parameters are allowed so do no validation
  // Please change this to state exactly what you do use, even if it is no parameters
  edm::ParameterSetDescription desc;
  desc.setUnknown();
  descriptions.addDefault(desc);
}

//define this as a plug-in
DEFINE_FWK_MODULE(VptGenAnalyzer);
