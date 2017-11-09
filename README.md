# VptGenAnalysis

## Installation

```
cmsrel CMSSW_8_0_28_patch1
cd CMSSW_8_0_28_patch1/src
cmsenv
git cms-addpkg GeneratorInterface/RivetInterface
git clone -b 8028_dev git@github.com:pfs/VptGenAnalysis.git UserCode/VptGenAnalysis
cp UserCode/VptGenAnalysis/data/ATLAS* GeneratorInterface/RivetInterface/data/
scram b -j 8
```

## Running the ntuplizer/RIVET analysis from command line

The creation of the ntuples and running the RIVET modules can be done with the command below.
Check the example for the command line options in the test/macros/steerVptAnalysis.sh TEST step.
The output is a ROOT file with the ntuples and yoda file(s) with the histograms from the RIVET analysis.
A yoda file per event weight is produced.

```
cmsRun test/runVptAnalysis_cfg.py
```

## Running over the grid

To help doing it systematically you can use also the shell script below. Customize it for your own purposes. 
The second command should be used once the outputs of all batch jobs are available.
Update the storage area in EOS in `test/macros/steerVptAnalysis.sh` and `scripts/wrapLocalAnalysisRun.sh` and compile again.

```
sh test/macros/steerVptAnalysis.sh NTUPLE
sh test/macros/steerVptAnalysis.sh MERGE
```

## Plotting the RIVET output

This can be done with the standard rivet-mkhtml command. An example can be found runnning 

```
sh test/macros/steerVptAnalysis.sh RIVET
```

## Analysing the ntuples
