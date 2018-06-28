#ifndef AnalysisTemplate_h
#define AnalysisTemplate_h

#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/EDAnalyzer.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/ServiceRegistry/interface/Service.h"
#include "CommonTools/UtilAlgos/interface/TFileService.h"

#include "TTree.h"
#include "TH1F.h"
#include "TH2F.h"
#include "TFile.h"
#include "TProfile.h"
#include <TMath.h>
using namespace edm;
using namespace std;

float DeltaR(float eta1,float phi1,float eta2,float phi2)
{
	float deltaPhi = TMath::Abs(phi1-phi2);
	float deltaEta = eta1-eta2;
	if(deltaPhi > TMath::Pi())
	deltaPhi = TMath::TwoPi() - deltaPhi;
	return TMath::Sqrt(deltaEta*deltaEta + deltaPhi*deltaPhi);
}

class Analysis_Template_MC : public edm::EDAnalyzer
 {

  //typedef reco::Particle::LorentzVector LorentzVector;

  public:
    explicit Analysis_Template_MC(edm::ParameterSet const& cfg);
    virtual void beginJob();
    virtual void analyze(edm::Event const& iEvent, edm::EventSetup const& iSetup);
    virtual void endJob();
    virtual ~Analysis_Template_MC();


  private:
    //---- configurable parameters --------
    std::string mFileName,mTreeName,mDirName;

    edm::Service<TFileService> fs;
    TTree *mTree;
    TFile *mInf, *mPuf;
    TDirectoryFile *mDir;

    //--------- Histogram Declaration --------------------//
    // Vertices
    int NEvents=0;
    ///Measurement Det jets
    TH1F *ptGENJet;
    TH1F *yGENJet;
    TH1F *phiGENJet;

    TH1F *Tau1GENEvent;
    TH1F *Tau2GENEvent;
    TH1F *Tau3GENEvent;
    TH1F *Tau4GENEvent;

    TH1F *ThrustGENEvent;
    TH1F *CircularityGENEvent;
    TH1F *SphericityGENEvent;
    TH1F *AplanarityGENEvent;
    TH1F *IsotropyGENEvent;
 
    TH2F *Tau1VsWBosonPt;
    TH2F *Tau2VsWBosonPt;
    TH2F *Tau3VsWBosonPt;
    TH2F *Tau4VsWBosonPt;

    TH2F *ThrustVsWBosonPt;
    TH2F *SphericityVsWBosonPt;
    TH2F *AplanarityVsWBosonPt;
    TH2F *IsotropyVsWBosonPt;
    TH2F *NJetsVsWBosonPt;
 };

#endif
