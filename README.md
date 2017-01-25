# VptGenAnalysis

## Installation

```
cmsrel CMSSW_8_0_8_patch1
cd CMSSW_8_0_8_patch1/src
cmsenv
git cms-addpkg GeneratorInterface/RivetInterface
git clone git@github.com:pfs/VptGenAnalysis.git UserCode/VptGenAnalysis
git clone git@github.com:pfs/RivetAnalysis.git  UserCode/RivetAnalysis
cp UserCode/RivetAnalysis/data/ATLAS* GeneratorInterface/RivetInterface/data/
scram b -j 8
```

## Running the ntuplizer/RIVET analysis

The creation of the ntuples and running the RIVET module can be run with test/runGENandAnalysis_cfg.py which contains some options to help steering it from command line. The output is a ROOT file with the ntuples and a yoda file with the histograms from the RIVET analysis

```
cmsRun test/runGENandAnalysis_cfg.py input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_10001.lhe saveEDM=False hadronizer=powhegEmissionVeto_1p_LHE_pythia8 output=dy2mumu &
```

To help doing it systematically you can use also the shell script below. Customize it for your own purposes. The second command should be used once the outputs of all batch jobs are available.
Update the storage area in EOS in `test/macros/steerVptAnalysis.sh` and `scripts/wrapLocalAnalysisRun.sh` and compile again.

```
sh test/macros/steerVptAnalysis.sh NTUPLE
sh test/macros/steerVptAnalysis.sh MERGE
```

## Plotting the RIVET output

## Analysing the ntuples