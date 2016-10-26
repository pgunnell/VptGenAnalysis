# VptGenAnalysis

## Installation

```
cmsrel CMSSW_8_0_8_patch1
cd CMSSW_8_0_8_patch1/src
cmsenv
git clone git@github.com:pfs/VptGenAnalysis.git UserCode/VptGenAnalysis
git clone git@github.com:pfs/RivetAnalysis.git  UserCode/RivetAnalysis
scram b -j 8
```

## Running the ntuplizer/RIVET analysis

wip

```
cmsRun test/runGENandAnalysis_cfg.py input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_10001.lhe saveEDM=False hadronizer=powhegEmissionVeto_1p_LHE_pythia8 &
```
