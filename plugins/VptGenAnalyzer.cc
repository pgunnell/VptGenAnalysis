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
#include "DataFormats/JetReco/interface/GenJetCollection.h"
#include "DataFormats/METReco/interface/METFwd.h"
#include "DataFormats/METReco/interface/MET.h"
#include "SimDataFormats/GeneratorProducts/interface/GenEventInfoProduct.h"
#include "SimDataFormats/GeneratorProducts/interface/LHEEventProduct.h"
#include "CommonTools/UtilAlgos/interface/TFileService.h"
#include "FWCore/ServiceRegistry/interface/Service.h"

#include "TH1F.h"
#include "TTree.h"

struct MiniEvent_t
{
  Int_t nw;
  Float_t w[500];
  Int_t nl;
  Int_t pid[20];
  Float_t pt[20],eta[20],phi[20],m[20];
  Float_t genmet_pt, genmet_eta, genmet_phi;
  Float_t nusum_pt, nusum_eta, nusum_phi;
  Int_t id1, id2;
  Float_t x1, x2, qscale;
};

typedef reco::Particle::LorentzVector LorentzVector;

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

  edm::EDGetTokenT<reco::GenJetCollection> genLeptonToken_;
  edm::EDGetTokenT<reco::METCollection> genMETToken_;
  edm::EDGetTokenT<reco::GenParticleCollection> genNeutrinosToken_;
  edm::EDGetTokenT<GenEventInfoProduct> generatorToken_;
  edm::EDGetTokenT<LHEEventProduct> generatorlheToken_;
  const float leptonMinPt_, leptonMaxEta_;
  
  edm::Service<TFileService> fs;
  TH1F *wgtH_;
  TTree *tree_;
  MiniEvent_t ev_;
};

//
VptGenAnalyzer::VptGenAnalyzer(const edm::ParameterSet &pset) :
  genLeptonToken_(consumes<reco::GenJetCollection>(pset.getParameter<edm::InputTag>("leptons"))),
  genMETToken_(consumes<reco::METCollection>(pset.getParameter<edm::InputTag>("mets"))),
  genNeutrinosToken_(consumes<reco::GenParticleCollection>(pset.getParameter<edm::InputTag>("neutrinos"))),
  generatorToken_(consumes<GenEventInfoProduct>(pset.getParameter<edm::InputTag>("genEventInfoProduct"))),
  generatorlheToken_(consumes<LHEEventProduct>(pset.getParameter<edm::InputTag>("lheEventProduct"))),
  leptonMinPt_(pset.getParameter<double>("leptonMinPt")),
  leptonMaxEta_(pset.getParameter<double>("leptonMaxEta"))
{  
  wgtH_ = fs->make<TH1F>("weights",";Weight number;Weight sum",500,0,500);
  
  tree_=fs->make<TTree>("data","data");
  tree_->Branch("nw", &ev_.nw, "nw/I");
  tree_->Branch("w",   ev_.w,  "w[nw]/F");

  tree_->Branch("nl",     &ev_.nl,     "nl/I");
  tree_->Branch("pid",     ev_.pid,    "pid[nl]/I");
  tree_->Branch("pt",      ev_.pt,     "pt[nl]/F");
  tree_->Branch("eta",     ev_.eta,    "eta[nl]/F");
  tree_->Branch("phi",     ev_.phi,    "phi[nl]/F");
  tree_->Branch("m",       ev_.m,      "m[nl]/F");

  tree_->Branch("genmet_pt",    &ev_.genmet_pt,   "genmet_pt/F");
  tree_->Branch("genmet_eta",   &ev_.genmet_eta,  "genmet_eta/F");
  tree_->Branch("genmet_phi",   &ev_.genmet_phi,  "genmet_phi/F");
  tree_->Branch("nusum_pt",     &ev_.nusum_pt,    "nusum_pt/F");
  tree_->Branch("nusum_eta",    &ev_.nusum_eta,   "nusum_eta/F");
  tree_->Branch("nusum_phi",    &ev_.nusum_phi,   "nusum_phi/F");

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

   //dressed leptons
   edm::Handle<reco::GenJetCollection> genLeptonHandle;
   iEvent.getByToken(genLeptonToken_,genLeptonHandle);
   for ( auto& l : *genLeptonHandle )
     {
       if ( l.pt() < leptonMinPt_ ) continue;
       if ( abs(l.eta()) > leptonMaxEta_ ) continue;              
       ev_.pid[ev_.nl] = l.pdgId();
       ev_.pt[ev_.nl]  = l.pt();
       ev_.eta[ev_.nl] = l.eta();
       ev_.phi[ev_.nl] = l.phi();
       ev_.m[ev_.nl]   = l.mass();
       ev_.nl++;
     }
   
   //gen-level MET
   edm::Handle<reco::METCollection> genMETHandle;
   iEvent.getByToken(genMETToken_,genMETHandle);
   ev_.genmet_pt  = (*genMETHandle)[0].pt();
   ev_.genmet_eta = (*genMETHandle)[0].eta();
   ev_.genmet_phi = (*genMETHandle)[0].phi();

   //gen-level neutrinos
   edm::Handle< reco::GenParticleCollection > genNeutrinosHandle;
   iEvent.getByToken(genNeutrinosToken_, genNeutrinosHandle);
   LorentzVector nusum(0,0,0,0);
   for ( auto &n : *genNeutrinosHandle ) nusum += n.p4();
   ev_.nusum_pt  = nusum.pt();
   ev_.nusum_eta = nusum.eta();
   ev_.nusum_phi = nusum.phi();
        
   //all done, save info
   if(ev_.nl>0) tree_->Fill();
}
 
//
void VptGenAnalyzer::resetMiniEvent()
{
  ev_.nw=0; 
  ev_.nl=0;
  for(size_t i=0; i<20; i++)
    {
      ev_.pid[i]=0; ev_.pt[i]=0; ev_.eta[i]=0; ev_.phi[i]=0; ev_.m[i]=0;
    }
  ev_.genmet_pt=0;  ev_.genmet_eta=0;	ev_.genmet_phi=0;
  ev_.nusum_pt=0;   ev_.nusum_eta=0;	ev_.nusum_phi=0;

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
