#include <iostream>
#include <sstream>
#include <istream>
#include <fstream>
#include <iomanip>
#include <string>
#include <cmath>
#include <functional>
#include <vector>
#include <cassert>
#include "TMath.h"
#include "TRandom.h"
#include "TFile.h"
#include "TTree.h"

#include "Analysis_Template_MC.h"

#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/Framework/interface/Frameworkfwd.h"
#include "FWCore/Framework/interface/MakerMacros.h"



using namespace std;

//---------------------------- Constructor Of The Class TriggerTurnOn -------------------------- //
Analysis_Template_MC::Analysis_Template_MC(edm::ParameterSet const& cfg)
{
     mFileName       = cfg.getParameter<std::string>               ("filename");
     mTreeName       = cfg.getParameter<std::string>               ("treename");
     mDirName        = cfg.getParameter<std::string>               ("dirname");
     
}

//------------------------------ Declaration Of The Function beginjob() ------------------------//
void Analysis_Template_MC::beginJob()
 {

     mInf = TFile::Open(mFileName.c_str());
     mDir = (TDirectoryFile*)mInf->Get(mDirName.c_str());
     mTree = (TTree*)mDir->Get(mTreeName.c_str());

     NEvents=0;
     
     //------------------ Histogram Booking --------------------------- //
     ptGENJet  = fs->make<TH1F>("ptGENJet","ptGENJet",200,0.,2000.); ptGENJet->Sumw2();
     yGENJet = fs->make<TH1F>("yGENJet","yGENJet",60,-3.,3.); yGENJet->Sumw2();
     phiGENJet = fs->make<TH1F>("phiGENJet","phiGENJet",60, -TMath::Pi(),TMath::Pi()); phiGENJet->Sumw2();

     Tau1GENEvent = fs->make<TH1F>("Tau1GENEvent","Tau1GENEvent",100,0.,7.);
     Tau2GENEvent = fs->make<TH1F>("Tau2GENEvent","Tau2GENEvent",100,0.,7.);
     Tau3GENEvent = fs->make<TH1F>("Tau3GENEvent","Tau3GENEvent",100,0.,7.);
     Tau4GENEvent = fs->make<TH1F>("Tau4GENEvent","Tau4GENEvent",100,0.,7.);

     ThrustGENEvent = fs->make<TH1F>("ThrustGENEvent","ThrustGENEvent",100,0.,1.);
     SphericityGENEvent = fs->make<TH1F>("SphericityGENEvent","SphericityGENEvent",100,0.,1.);
     AplanarityGENEvent = fs->make<TH1F>("AplanarityGENEvent","AplanarityGENEvent",100,0.,1.);
     IsotropyGENEvent = fs->make<TH1F>("IsotropyGENEvent","IsotropyGENEvent",100,0.,1.);
     CircularityGENEvent = fs->make<TH1F>("CircularityGENEvent","CircularityGENEvent",100,0.,1.);

     Tau1VsWBosonPt = fs->make<TH2F>("Tau1VsWBosonPt","Tau1VsWBosonPt",50,0.,500.,100,0.,8.);
     Tau2VsWBosonPt = fs->make<TH2F>("Tau2VsWBosonPt","Tau2VsWBosonPt",50,0.,500.,100,0.,8.);
     Tau3VsWBosonPt = fs->make<TH2F>("Tau3VsWBosonPt","Tau3VsWBosonPt",50,0.,500.,100,0.,8.);
     Tau4VsWBosonPt = fs->make<TH2F>("Tau4VsWBosonPt","Tau4VsWBosonPt",50,0.,500.,100,0.,8.);

     ThrustVsWBosonPt = fs->make<TH2F>("ThrustVsWBosonPt","ThrustVsWBosonPt",50,0.,500.,100,0.,1.);
     SphericityVsWBosonPt = fs->make<TH2F>("SphericityVsWBosonPt","SphericityVsWBosonPt",50,0.,500.,100,0.,1.);
     IsotropyVsWBosonPt = fs->make<TH2F>("IsotropyVsWBosonPt","IsotropyVsWBosonPt",50,0.,500.,100,0.,1.);
     AplanarityVsWBosonPt = fs->make<TH2F>("AplanarityVsWBosonPt","AplanarityVsWBosonPt",50,0.,500.,100,0.,1.);
     NJetsVsWBosonPt = fs->make<TH2F>("NJetsVsWBosonPt","NJetsVsWBosonPt",50,0.,500.,10,-0.5,9.5);

 } // end of function beginJob()


 //------------------------ endjob() function declaration ---------------------- //
 void Analysis_Template_MC::endJob()
 {
   mInf->Close();
   
 } // closing endJob()

 //--------------------------- analyze() fuction declaration ------------------ //
void Analysis_Template_MC::analyze(edm::Event const& iEvent, edm::EventSetup const& iSetup)
 {

   unsigned NEntries = mTree->GetEntries();
   cout<<"Reading TREE: "<<NEntries<<" events"<<endl;
   
   int decade = 0 ;
   
   float hweight=1.;  //Initial value set to one

   int nGenJets_=-100; int nChgparts_=-100; int nWBosons_=-100; int nLeptons_=-100;
   
   Float_t genjetPt_[300];   Float_t genjetEta_[300];   Float_t genjetPhi_[300];
   Float_t chgpartPt_[300];   Float_t chgpartEta_[300];   Float_t chgpartPhi_[300];
   Float_t wbosonPt_[300];   Float_t wbosonEta_[300];   Float_t wbosonPhi_[300];
   Float_t leptonPt_[300];   Float_t leptonEta_[300];   Float_t leptonPhi_[300];
   Float_t genmetPt_;    Float_t genmetEta_;   Float_t genmetPhi_;

   //event shapes
   Float_t tau1_;    Float_t tau2_;    Float_t tau3_;    Float_t tau4_;    
   Float_t thrust_;    Float_t sphericity_;    Float_t isotropy_;    Float_t aplanarity_;    Float_t circularity_;    

   mTree->SetBranchAddress("genjet_mult",&nGenJets_);
   mTree->SetBranchAddress("genjet_pt",&genjetPt_);
   mTree->SetBranchAddress("genjet_eta",&genjetEta_);
   mTree->SetBranchAddress("genjet_phi",&genjetPhi_);

   mTree->SetBranchAddress("genmet_pt",&genmetPt_);
   mTree->SetBranchAddress("genmet_eta",&genmetEta_);
   mTree->SetBranchAddress("genmet_phi",&genmetPhi_);

   mTree->SetBranchAddress("chgpart_mult",&nChgparts_);
   mTree->SetBranchAddress("chgpart_pt",&chgpartPt_);
   mTree->SetBranchAddress("chgpart_eta",&chgpartEta_);
   mTree->SetBranchAddress("chgpart_phi",&chgpartPhi_);

   mTree->SetBranchAddress("wboson_mult",&nWBosons_);
   mTree->SetBranchAddress("wboson_pt",&wbosonPt_);
   mTree->SetBranchAddress("wboson_eta",&wbosonEta_);
   mTree->SetBranchAddress("wboson_phi",&wbosonPhi_);

   mTree->SetBranchAddress("nl",&nLeptons_);
   mTree->SetBranchAddress("pt",&leptonPt_);
   mTree->SetBranchAddress("eta",&leptonEta_);
   mTree->SetBranchAddress("phi",&leptonPhi_);

   mTree->SetBranchAddress("tau1",&tau1_);
   mTree->SetBranchAddress("tau2",&tau2_);
   mTree->SetBranchAddress("tau3",&tau3_);
   mTree->SetBranchAddress("tau4",&tau4_);
   
   mTree->SetBranchAddress("thrust",&thrust_);
   mTree->SetBranchAddress("sphericity",&sphericity_);
   mTree->SetBranchAddress("aplanarity",&aplanarity_);
   mTree->SetBranchAddress("isotropy",&isotropy_);
   mTree->SetBranchAddress("circularity",&circularity_);

   for(unsigned  l=0; l<NEntries; l++) {
     
    //----------- progress report -------------
    double progress = 10.0*l/(1.0*NEntries);
    int k = TMath::FloorNint(progress);
    if (k > decade)
      cout<<10*k<<" %"<<endl;
    decade = k;
   
    //----------- read the event --------------
    mTree->GetEntry(l);
    
    for(int j=0; j< nGenJets_; j++){

      ptGENJet->Fill(genjetPt_[j],hweight);
      yGENJet->Fill(genjetEta_[j],hweight);
      phiGENJet->Fill(genjetPhi_[j],hweight);

    }

    if(nGenJets_>1){
      Tau1GENEvent->Fill(tau1_,hweight);
      Tau2GENEvent->Fill(tau2_,hweight);
      Tau3GENEvent->Fill(tau3_,hweight);
      Tau4GENEvent->Fill(tau4_,hweight);

      ThrustGENEvent->Fill(thrust_,hweight);
      SphericityGENEvent->Fill(sphericity_,hweight);
      AplanarityGENEvent->Fill(aplanarity_,hweight);
      IsotropyGENEvent->Fill(isotropy_,hweight);
      CircularityGENEvent->Fill(circularity_,hweight);

    }
    
    //start to fill 2D histograms
    if(nWBosons_==1){

      Tau1VsWBosonPt->Fill(wbosonPt_[0],tau1_,hweight);
      Tau2VsWBosonPt->Fill(wbosonPt_[0],tau2_,hweight);
      Tau3VsWBosonPt->Fill(wbosonPt_[0],tau3_,hweight);
      Tau4VsWBosonPt->Fill(wbosonPt_[0],tau4_,hweight);
      ThrustVsWBosonPt->Fill(wbosonPt_[0],thrust_,hweight);
      SphericityVsWBosonPt->Fill(wbosonPt_[0],sphericity_,hweight);
      AplanarityVsWBosonPt->Fill(wbosonPt_[0],aplanarity_,hweight);
      IsotropyVsWBosonPt->Fill(wbosonPt_[0],isotropy_,hweight);
      NJetsVsWBosonPt->Fill(wbosonPt_[0],nGenJets_,hweight);

    }
   } // end of event loop

   
 } // closing analyze() function

Analysis_Template_MC::~Analysis_Template_MC()
{
}


DEFINE_FWK_MODULE(Analysis_Template_MC);
