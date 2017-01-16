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

#include "TH1F.h"
#include "TTree.h"

struct MiniEvent_t
{
  Int_t nw;
  Float_t w[500];
  Int_t nl;
  Int_t pid[20],charge[20];
  Float_t pt[20],eta[20],phi[20],m[20];
  Float_t dressed_pt[20],dressed_eta[20],dressed_phi[20],dressed_m[20];
  Float_t imbalance_pt[3],imbalance_eta[3], imbalance_phi[3];
  Float_t vecbos_pt, vecbos_eta, vecbos_phi, vecbos_m;
  Int_t id1, id2;
  Float_t x1, x2, qscale;
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
  void resetMiniEvent();
  const reco::Candidate *getParticleMother(const reco::Candidate *p)
  {
    if(p==0) return 0;
    const reco::Candidate *mother=p->mother();
    if(mother==0) return 0;
    if(mother->pdgId()==p->pdgId()) return getParticleMother(mother);
    return mother;
  }

  bool isBHadron(const reco::Candidate* p) const;
  bool isBHadron(const unsigned int pdgId) const;
  bool isFromHadron(const reco::Candidate* p) const;
  
  edm::EDGetTokenT<reco::GenParticleCollection> genParticleToken_;
  edm::EDGetTokenT<GenEventInfoProduct> generatorToken_;
  edm::EDGetTokenT<LHEEventProduct> generatorlheToken_;
  const float leptonConeSize_, leptonMinPt_, leptonMaxEta_;
  
  std::shared_ptr<JetDef> fjLepDef_;
  
  edm::Service<TFileService> fs;
  TH1F *wgtH_;
  TTree *tree_;
  MiniEvent_t ev_;
};

//
VptGenAnalyzer::VptGenAnalyzer(const edm::ParameterSet &pset) :
  genParticleToken_(consumes<reco::GenParticleCollection>(pset.getParameter<edm::InputTag>("genParticles"))),
  generatorToken_(consumes<GenEventInfoProduct>(pset.getParameter<edm::InputTag>("genEventInfoProduct"))),
  generatorlheToken_(consumes<LHEEventProduct>(pset.getParameter<edm::InputTag>("lheEventProduct"))),
  leptonConeSize_(pset.getParameter<double>("leptonConeSize")),
  leptonMinPt_(pset.getParameter<double>("leptonMinPt")),
  leptonMaxEta_(pset.getParameter<double>("leptonMaxEta"))
{
  fjLepDef_ = std::shared_ptr<JetDef>(new JetDef(fastjet::antikt_algorithm, leptonConeSize_));

  
  wgtH_ = fs->make<TH1F>("weights",";Weight number;Weight sum",500,0,500);
  
  tree_=fs->make<TTree>("data","data");
  tree_->Branch("nw", &ev_.nw, "nw/I");
  tree_->Branch("w",   ev_.w,  "w[nw]/F");

  tree_->Branch("nl",     &ev_.nl,     "nl/I");
  tree_->Branch("pid",     ev_.pid,    "pid[nl]/I");
  tree_->Branch("charge",  ev_.charge, "charge[nl]/I");
  tree_->Branch("pt",      ev_.pt,     "pt[nl]/F");
  tree_->Branch("eta",     ev_.eta,    "eta[nl]/F");
  tree_->Branch("phi",     ev_.phi,    "phi[nl]/F");
  tree_->Branch("m",       ev_.m,      "m[nl]/F");
  tree_->Branch("dressed_pt",       ev_.dressed_pt,      "dressed_pt[nl]/F");
  tree_->Branch("dressed_eta",      ev_.dressed_eta,     "dressed_eta[nl]/F");
  tree_->Branch("dressed_phi",      ev_.dressed_phi,     "dressed_phi[nl]/F");
  tree_->Branch("dressed_m",        ev_.dressed_m,       "dressed_m[nl]/F");
  tree_->Branch("imbalance_pt",     ev_.imbalance_pt,    "imbalance_pt[3]/F");
  tree_->Branch("imbalance_eta",    ev_.imbalance_eta,   "imbalance_eta[3]/F");
  tree_->Branch("imbalance_phi",    ev_.imbalance_phi,   "imbalance_phi[3]/F");
  tree_->Branch("vecbos_pt",        &ev_.vecbos_pt,      "vecbos_pt/F");
  tree_->Branch("vecbos_eta",       &ev_.vecbos_eta,     "vecbos_eta/F");
  tree_->Branch("vecbos_phi",       &ev_.vecbos_phi,     "vecbos_phi/F");
  tree_->Branch("vecbos_m",         &ev_.vecbos_m,       "vecbos_m/F");

  tree_->Branch("id1",     &ev_.id1,    "id1/I");
  tree_->Branch("id2",     &ev_.id2,    "id2/I");
  tree_->Branch("x1",      &ev_.x1,     "x1/F");
  tree_->Branch("x2",      &ev_.x2,     "x2/F");
  tree_->Branch("qscale",  &ev_.qscale, "qscale/F");
}


//
VptGenAnalyzer::~VptGenAnalyzer()
{
}


//
void VptGenAnalyzer::analyze(const edm::Event& iEvent, const edm::EventSetup& iSetup)
{
   using namespace edm;

   resetMiniEvent();

   //event weights
   edm::Handle<GenEventInfoProduct> evt;
   iEvent.getByToken( generatorToken_,evt);   
   edm::Handle<LHEEventProduct> evet;
   iEvent.getByToken(generatorlheToken_, evet);
   if(evt.isValid())
     {
       //PDF info
       ev_.qscale = evt->pdf()->scalePDF;
       ev_.x1     = evt->pdf()->x.first;
       ev_.x2     = evt->pdf()->x.second;
       ev_.id1    = evt->pdf()->id.first;
       ev_.id2    = evt->pdf()->id.second;

       //default event weight
       ev_.nw=1;
       ev_.w[0]=evt->weight();
       
       //event weights
       if(evet.isValid())
	 {
	   double asdd=evet->originalXWGTUP();
	   for(unsigned int i=0  ; i<evet->weights().size();i++){
	     double asdde=evet->weights()[i].wgt;
	     ev_.w[ev_.nw]=evt->weight()*asdde/asdd;
	     ev_.nw++;
	   }
	 }
     }

   //increment weight histogram for posterior normalization
   for(Int_t i=0; i<ev_.nw; i++) wgtH_->Fill(i,ev_.w[i]);

   //get genParticles
   edm::Handle< reco::GenParticleCollection > genParticleHandle;
   iEvent.getByToken(genParticleToken_, genParticleHandle);

   // Collect stable leptons and neutrinos, compute momentum-balance flavours
   
   std::vector<size_t> lepPhoIdxs;
   std::vector<LorentzVector> balance(3,LorentzVector(0,0,0,0));
   for ( size_t i=0, n=genParticleHandle->size(); i<n; ++i )
     {
       const reco::Candidate& p = genParticleHandle->at(i);
       if ( p.status() != 1 ) continue;
       if ( p.numberOfMothers() == 0 ) continue; // Skip orphans (if exists)
       //if ( p.mother()->status() == 4 ) continue; // Treat particle as hadronic if directly from the incident beam (protect orphans in MINIAOD)

       //fiducial cut
       if ( p.pt()<0.05 || fabs(p.eta())>4.7) continue;
     
       //momentum-balance
       balance[1] += p.p4();
       if( fabs(p.eta())<2.4 && p.charge()!=0) balance[2] += p.p4();

       //save leptons and neutrinos (exclude b-hadrons)
       if ( isFromHadron(&p) ) continue;
       const int absPdgId = abs(p.pdgId());
       switch ( absPdgId )
	 {
	 case 11: case 13: case 22: // leptons and photons
	   lepPhoIdxs.push_back(i);
	   break;
	 case 12: case 14: case 16: //neutrinos
	   balance[0] -= p.p4();
	   break;
	 }
     }

   //fill imbalance kinematics
   for(size_t i=0; i<3; i++)
     {
       balance[i] *= -1;
       ev_.imbalance_pt[i]=balance[i].pt();
       ev_.imbalance_eta[i]=balance[i].eta();
       ev_.imbalance_phi[i]=balance[i].phi();
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
   
   //prune the output and save the information on the leptons
   for ( auto& fjJet : fjLepJets )
     {
       if ( abs(fjJet.eta()) > leptonMaxEta_ ) continue;

       //match the lepton candidate of this jet
       const reco::Candidate *lepCand=0,*lepMother=0;       
       const std::vector<fastjet::PseudoJet> fjConstituents = fastjet::sorted_by_pt(fjJet.constituents());
       for ( auto& fjConstituent : fjConstituents )
	 {
	   const size_t index = fjConstituent.user_index();
	   const reco::Candidate& p  = genParticleHandle->at(index);
	   const int absPdgId = abs(p.pdgId());
	   if ( absPdgId != 11 && absPdgId != 13 ) continue;
	   if ( lepCand!=0 and lepCand->pt() > p.pt()) continue;
	   lepCand = &p;	   
	   lepMother=getParticleMother(&p);
	 }
       if ( lepCand==0 ) continue;
       if ( lepCand->pt() < fjJet.pt()/2 ) continue; // Central lepton must be the major component
       
       ev_.pid[ev_.nl]=lepCand->pdgId();
       ev_.charge[ev_.nl]=lepCand->charge();
       ev_.pt[ev_.nl]=lepCand->pt();
       ev_.eta[ev_.nl]=lepCand->eta();
       ev_.phi[ev_.nl]=lepCand->phi();
       ev_.m[ev_.nl]=lepCand->mass();
       ev_.dressed_pt[ev_.nl]=fjJet.pt();
       ev_.dressed_eta[ev_.nl]=fjJet.eta();
       ev_.dressed_phi[ev_.nl]=fjJet.phi();
       ev_.dressed_m[ev_.nl]=fjJet.m();
       ev_.nl++;

       if(lepMother==0) continue;
       int absMotherId( abs(lepMother->pdgId()) );
       if(absMotherId!=23 && absMotherId!=24) continue;
       ev_.vecbos_pt=lepMother->pt();
       ev_.vecbos_eta=lepMother->eta();
       ev_.vecbos_phi=lepMother->phi();
       ev_.vecbos_m=lepMother->mass();
     }
     
   //all done, save info
   if(ev_.nl>0) tree_->Fill();
}
 
//  
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


//
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

//
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

//
void VptGenAnalyzer::resetMiniEvent()
{
  ev_.nw=0; 
  ev_.nl=0;
  for(size_t i=0; i<20; i++)
    {
      ev_.pt[i]=0; ev_.eta[i]=0; ev_.phi[i]=0; ev_.m[i]=0;
      ev_.dressed_pt[i]=0; ev_.dressed_eta[i]=0; ev_.dressed_phi[i]=0; ev_.dressed_m[i]=0;
    }
  for(size_t j=0; j<3; j++)
    {
      ev_.imbalance_pt[j]=0;	ev_.imbalance_eta[j]=0;	ev_.imbalance_phi[j]=0;
    }
  ev_.vecbos_pt=0; ev_.vecbos_eta=0; ev_.vecbos_phi=0; ev_.vecbos_m=0;
}

//
void VptGenAnalyzer::beginJob()
{
}

//
void VptGenAnalyzer::endJob() 
{
}

//
void VptGenAnalyzer::fillDescriptions(edm::ConfigurationDescriptions& descriptions) {
  edm::ParameterSetDescription desc;
  desc.setUnknown();
  descriptions.addDefault(desc);
}


//define this as a plug-in
DEFINE_FWK_MODULE(VptGenAnalyzer);
