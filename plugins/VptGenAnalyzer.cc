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
#include "PhysicsTools/CandUtils/interface/Thrust.h"
#include "PhysicsTools/CandUtils/interface/EventShapeVariables.h"
#include "TLorentzVector.h"
#include "TVector3.h"
#include "fastjet/contrib/Njettiness.hh"

#include "TH1F.h"
#include "TTree.h"

struct MiniEvent_t
{
  Int_t nw;
  Float_t w[500];
  Int_t nl;
  Int_t pid[300];
  Float_t pt[300],eta[300],phi[300],m[300], px[300], py[300];
  Float_t genmet_pt, genmet_eta, genmet_phi, genmet_px, genmet_py;
  Float_t wboson_pt[300], wboson_eta[300], wboson_phi[300];
  Float_t chgpart_pt[300], chgpart_eta[300], chgpart_phi[300];
  Float_t nusum_pt, nusum_eta, nusum_phi;
  Int_t id1, id2;
  Float_t x1, x2, qscale;
  Int_t genjet_mult;
  Int_t wboson_mult;
  Int_t chgpart_mult;
  Int_t genparticle_mult;
  Float_t thrust;
  Float_t sphericity;
  Float_t circularity;
  Float_t aplanarity;
  Float_t isotropy;
  Float_t tau1; Float_t tau2;  Float_t tau3;  Float_t tau4;
  Float_t genjetpt[300],genjeteta[300],genjetphi[300];
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
  edm::EDGetTokenT<reco::GenJetCollection> genJetToken_;
  edm::EDGetTokenT<reco::GenParticleCollection> genParticleToken_;
  edm::EDGetTokenT<reco::GenParticleCollection> genWBosonToken_;
  edm::EDGetTokenT<reco::METCollection> genMETToken_;
  edm::EDGetTokenT<reco::GenParticleCollection> genNeutrinosToken_;
  edm::EDGetTokenT<GenEventInfoProduct> generatorToken_;
  edm::EDGetTokenT<LHEEventProduct> generatorlheToken_;
  const float leptonMinPt_, leptonMaxEta_;
  const float jetMinPt_, jetMaxEta_;
  
  edm::Service<TFileService> fs;
  TH1F *wgtH_;
  TTree *tree_;
  MiniEvent_t ev_;


};

std::vector<math::XYZVector> makeVecForEventShape(std::vector<reco::GenJet> jets) {
  std::vector<math::XYZVector> p;
  for(std::vector<reco::GenJet>::const_iterator jet = jets.begin(); jet != jets.end(); ++jet){
    math::XYZVector Vjet;
    Vjet = math::XYZVector(jet->px(), jet->py(), jet->pz());
    p.push_back(Vjet);
  }
  return p;
}

//
VptGenAnalyzer::VptGenAnalyzer(const edm::ParameterSet &pset) :
  genLeptonToken_(consumes<reco::GenJetCollection>(pset.getParameter<edm::InputTag>("leptons"))),
  genJetToken_(consumes<reco::GenJetCollection>(pset.getParameter<edm::InputTag>("genjets"))),
  genParticleToken_(consumes<reco::GenParticleCollection>(pset.getParameter<edm::InputTag>("particles"))),
  genWBosonToken_(consumes<reco::GenParticleCollection>(pset.getParameter<edm::InputTag>("wbosons"))),
  genMETToken_(consumes<reco::METCollection>(pset.getParameter<edm::InputTag>("mets"))),
  genNeutrinosToken_(consumes<reco::GenParticleCollection>(pset.getParameter<edm::InputTag>("neutrinos"))),
  generatorToken_(consumes<GenEventInfoProduct>(pset.getParameter<edm::InputTag>("genEventInfoProduct"))),
  generatorlheToken_(consumes<LHEEventProduct>(pset.getParameter<edm::InputTag>("lheEventProduct"))),
  leptonMinPt_(pset.getParameter<double>("leptonMinPt")),
  leptonMaxEta_(pset.getParameter<double>("leptonMaxEta")),
  jetMinPt_(pset.getParameter<double>("jetMinPt")),
  jetMaxEta_(pset.getParameter<double>("jetMaxEta"))
{  
  wgtH_ = fs->make<TH1F>("weights",";Weight number;Weight sum",500,0,500);
  
  tree_=fs->make<TTree>("data","data");
  tree_->Branch("nw", &ev_.nw, "nw/I");
  tree_->Branch("w",   ev_.w,  "w[nw]/F");

  tree_->Branch("nl",     &ev_.nl,     "nl/I");
  tree_->Branch("pid",     ev_.pid,    "pid[nl]/I");
  tree_->Branch("pt",      ev_.pt,     "pt[nl]/F");
  tree_->Branch("px",      ev_.px,     "px[nl]/F");
  tree_->Branch("py",      ev_.py,     "py[nl]/F");
  tree_->Branch("eta",     ev_.eta,    "eta[nl]/F");
  tree_->Branch("phi",     ev_.phi,    "phi[nl]/F");
  tree_->Branch("m",       ev_.m,      "m[nl]/F");

  tree_->Branch("genmet_pt",    &ev_.genmet_pt,   "genmet_pt/F");
  tree_->Branch("genmet_py",    &ev_.genmet_py,   "genmet_py/F");
  tree_->Branch("genmet_px",    &ev_.genmet_px,   "genmet_px/F");
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

  //adding jet observables, down to low-pT
  tree_->Branch("genjet_mult",    &ev_.genjet_mult,   "genjet_mult/I");

  tree_->Branch("genjet_pt",    ev_.genjetpt,   "genjet_pt[genjet_mult]/F");
  tree_->Branch("genjet_eta",   ev_.genjeteta,  "genjet_eta[genjet_mult]/F");
  tree_->Branch("genjet_phi",   ev_.genjetphi,  "genjet_phi[genjet_mult]/F");

  //adding particle-level quantities
  tree_->Branch("wboson_mult",    &ev_.wboson_mult,   "wboson_mult/I");

  tree_->Branch("wboson_pt",    ev_.wboson_pt,   "wboson_pt[wboson_mult]/F");
  tree_->Branch("wboson_eta",   ev_.wboson_eta,  "wboson_eta[wboson_mult]/F");
  tree_->Branch("wboson_phi",   ev_.wboson_phi,  "wboson_phi[wboson_mult]/F");


  tree_->Branch("chgpart_mult",    &ev_.chgpart_mult,   "chgpart_mult/I");

  tree_->Branch("chgpart_pt",    ev_.chgpart_pt,   "chgpart_pt[chgpart_mult]/F");
  tree_->Branch("chgpart_eta",   ev_.chgpart_eta,  "chgpart_eta[chgpart_mult]/F");
  tree_->Branch("chgpart_phi",   ev_.chgpart_phi,  "chgpart_phi[chgpart_mult]/F");

  //adding event shape observables
  
  tree_->Branch("thrust",    &ev_.thrust,   "thrust/F");
  tree_->Branch("sphericity",    &ev_.sphericity,   "sphericity/F");
  tree_->Branch("aplanarity",    &ev_.aplanarity,   "aplanarity/F");
  tree_->Branch("isotropy",    &ev_.isotropy,   "isotropy/F");
  tree_->Branch("circularity",    &ev_.circularity,   "circularity/F");

  //n-jettiness
  tree_->Branch("tau1",    &ev_.tau1,   "tau1/F");
  tree_->Branch("tau2",    &ev_.tau2,   "tau2/F");
  tree_->Branch("tau3",    &ev_.tau3,   "tau3/F");
  tree_->Branch("tau4",    &ev_.tau4,   "tau4/F");


}


//
VptGenAnalyzer::~VptGenAnalyzer()
{
}


//
void VptGenAnalyzer::analyze(const edm::Event& iEvent, const edm::EventSetup& iSetup)
{
   using namespace edm;

   using namespace fastjet;

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
       ev_.px[ev_.nl]  = l.px();
       ev_.py[ev_.nl]  = l.py();
       ev_.eta[ev_.nl] = l.eta();
       ev_.phi[ev_.nl] = l.phi();
       ev_.m[ev_.nl]   = l.mass();
       ev_.nl++;
     }

   //gen jet quantities
   edm::Handle<reco::GenJetCollection> genJetHandle;
   iEvent.getByToken(genJetToken_,genJetHandle);

   std::vector<reco::GenJet> jets;

   for ( auto& j : *genJetHandle )
     {
       if ( j.pt() < jetMinPt_ ) continue;
       if ( abs(j.eta()) > jetMaxEta_ ) continue;              

       ev_.genjetpt[ev_.genjet_mult]  = j.pt();
       ev_.genjeteta[ev_.genjet_mult] = j.eta();
       ev_.genjetphi[ev_.genjet_mult] = j.phi();
       ev_.genjet_mult++;
       jets.push_back(j);
     }
   
   //particle quantities (+W boson)
   edm::Handle<reco::GenParticleCollection> genWBosonHandle;
   iEvent.getByToken(genWBosonToken_,genWBosonHandle);
   for ( auto& p : *genWBosonHandle )
     {
       ev_.wboson_pt[ev_.wboson_mult]  = p.pt();
       ev_.wboson_eta[ev_.wboson_mult]  = p.eta();
       ev_.wboson_phi[ev_.wboson_mult]  = p.phi();
       ev_.wboson_mult++;
     }

   //charged particle quantities
   std::vector<fastjet::PseudoJet> lClusterParticles;

   edm::Handle<reco::GenParticleCollection> genParticleHandle;
   iEvent.getByToken(genParticleToken_,genParticleHandle);
 
   for ( auto& p : *genParticleHandle )
     {
       ev_.chgpart_pt[ev_.chgpart_mult]  = p.pt();
       ev_.chgpart_eta[ev_.chgpart_mult]  = p.eta();
       ev_.chgpart_phi[ev_.chgpart_mult]  = p.phi();

       fastjet::PseudoJet   pPart(p.px(),p.py(),p.pz(),p.energy());
       lClusterParticles.push_back(pPart);
       ev_.chgpart_mult++;

     }

   //gen-level MET
   edm::Handle<reco::METCollection> genMETHandle;
   iEvent.getByToken(genMETToken_,genMETHandle);
   ev_.genmet_pt  = (*genMETHandle)[0].pt();
   ev_.genmet_eta = (*genMETHandle)[0].eta();
   ev_.genmet_phi = (*genMETHandle)[0].phi();
   ev_.genmet_px  = (*genMETHandle)[0].px();
   ev_.genmet_py  = (*genMETHandle)[0].py();

   //gen-level neutrinos
   edm::Handle< reco::GenParticleCollection > genNeutrinosHandle;
   iEvent.getByToken(genNeutrinosToken_, genNeutrinosHandle);
   LorentzVector nusum(0,0,0,0);
   for ( auto &n : *genNeutrinosHandle ) nusum += n.p4();
   ev_.nusum_pt  = nusum.pt();
   ev_.nusum_eta = nusum.eta();
   ev_.nusum_phi = nusum.phi();

   //Calculation of event shapes
   
   Thrust thrustAlgo(jets.begin(), jets.end());
   ev_.thrust = thrustAlgo.thrust();
  
   EventShapeVariables eventshape(makeVecForEventShape(jets));
   ev_.sphericity = eventshape.sphericity();
   ev_.isotropy = eventshape.isotropy();
   ev_.aplanarity = eventshape.aplanarity();
   ev_.circularity = eventshape.circularity();

   //try the njettiness
   fastjet::contrib::NormalizedMeasure normalizedMeasure(1.0,0.4);
   fastjet::contrib::Njettiness routine(fastjet::contrib::Njettiness::onepass_kt_axes,normalizedMeasure);
   float iTau1 = routine.getTau(1.,lClusterParticles);
   float iTau2 = routine.getTau(2.,lClusterParticles);
   float iTau3 = routine.getTau(3.,lClusterParticles);
   float iTau4 = routine.getTau(4.,lClusterParticles);   

   ev_.tau1 = iTau1;
   ev_.tau2 = iTau2;
   ev_.tau3 = iTau3;
   ev_.tau4 = iTau4;

   //all done, save info
   tree_->Fill();
}
 
//
void VptGenAnalyzer::resetMiniEvent()
{
  ev_.nw=0; 
  ev_.nl=0;
  ev_.genjet_mult=0;
  ev_.wboson_mult=0;
  ev_.chgpart_mult=0;
  ev_.genparticle_mult=0;

  for(size_t i=0; i<300; i++)
    {
      ev_.pid[i]=0; ev_.pt[i]=0; ev_.eta[i]=0; ev_.phi[i]=0; ev_.m[i]=0;
      ev_.genjetpt[i]=0; ev_.genjeteta[i]=0; ev_.genjetphi[i]=0; 
      ev_.wboson_pt[i]=0; ev_.wboson_eta[i]=0; ev_.wboson_phi[i]=0; 
      ev_.chgpart_pt[i]=0; ev_.chgpart_eta[i]=0; ev_.chgpart_phi[i]=0; 
    }

  ev_.tau1=0;   ev_.tau2=0;   ev_.tau3=0;   ev_.tau4=0; 
  ev_.thrust=0; ev_.sphericity=0;
  ev_.circularity=0; ev_.aplanarity=0; ev_.isotropy=0;
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
