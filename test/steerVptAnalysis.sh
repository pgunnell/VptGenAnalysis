#!/bin/bash

WHAT=${1}

outdir=/afs/cern.ch/user/p/psilva/work/Wmass/rivet/data

case $WHAT in
    TEST )
	cmsRun ${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py \
	    output=/tmp/psilva/test0 \
	    hadronizer=TuneCUETP8M2T4_8TeV_powhegEmissionVeto_2p_LHE_pythia8 seed=2
	   #hadronizer=gmZ_TuneCUETP8M2T4_8TeV_pythia8 seed=1 maxEvents=5000
	;;
    NTUPLE )

	mkdir -p ${outdir}	
	script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
	cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py

	cffList=(
	    Hadronizer_TuneCUETP8M2T4_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	    Hadronizer_TuneCUETP8M2T4_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff:primordialKToff
	    Hadronizer_TuneCUETP8M2T4up_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	    Hadronizer_TuneCUETP8M2T4down_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	    Hadronizer_TuneCUETP8M2T4FSRup_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff    
	    Hadronizer_TuneCUETP8M2T4FSRdown_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff  
	    Hadronizer_TuneCUETP8M2T4ISRup_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	    Hadronizer_TuneCUETP8M2T4ISRdown_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	    Hadronizer_TuneEE_5C_8TeV_Herwigpp_cff
	)
	cffTags=(
	    nominal
	    noPrimKt
	    ueup
	    uedn
	    fsrup
	    fsrdown
	    isrup
	    isrdown
	    hwpp
	)

	for proc in Zj Wplusj Wminusj; do
	    lheDir=/store/cmst3/user/psilva/Wmass/${proc}
	    fcounter=1
	    a=(`eos ls ${lheDir}`)
	    for i in ${a[@]}; do
		if [[ $i == *"cmsgrid"* ]]
		then
		    continue
		fi
		fcounter=$((fcounter+1))
		for k in "${!cffList[@]}"; do 
		    cff=${cffList[$k]};
		    tag=${cffTags[$k]};
		    echo "${proc}_${tag}_${fcounter} ${cff}"
		    bsub -q 8nh $script "cmsRun ${cfg} output=${outdir}/${proc}_${tag}_${fcounter} input=${lheDir}/${i} hadronizer=${cff} seed=${fcounter}";
		done
	    done
	done

#	for i in `seq 1 200`; do
#	    num=$((i + 10000))
#	    bsub -q 8nh $script "cmsRun ${cfg} output=${outdir}/z_py8_${fcounter} hadronizer=gmZ_TuneCUETP8M2T4_8TeV_pythia8 seed=${i} maxEvents=10000";
#	    bsub -q 8nh $script "cmsRun ${cfg} output=${outdir}/dy2mumu_ct10_${i} input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_${num}.lhe hadronizer=powhegEmissionVeto_1p_LHE_pythia8"
#	done

	;;
    MERGE )
	mkdir -p ${outdir}/Chunks
	for proc in dy2mumu_ct10 Zj_noPrimKt Zj; do
	    regex=".*${proc}_[0-9]*\.yoda$"
	    a=(`exec find ${outdir} -regex ${regex}`)
	    if [ ${#a[@]} -eq 0 ]; then
		continue
	    fi

	    yodaFiles=""
	    rootFiles=""
	    for i in ${a[@]}; do 
		yodaFiles="${yodaFiles} ${i}"
		rootfiles="${rootFiles} ${i/yoda/root}"
	    done

	    yodamerge -o ${outdir}/${proc}.yoda ${yodaFiles}
	    hadd -f -k ${outdir}/${proc}.root ${rootFiles}
	    mv -t ${outdir}/Chunks ${yodaFiles}
	    mv -t ${outdir}/Chunks ${rootFiles}
	done
	;;

    PLOT )
	commonOpts="-s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot --config=data/CMS_Z_Pt.plot"
	rivet-mkhtml ${commonOpts} \
	    -o ~/public/html/Zj \
	    ${outdir}/dy2mumu_ct10.yoda:'DY(M$>$20)' \
	    ${outdir}/Zj.yoda:'Zj' \
	    ${outdir}/Zj_noPrimKt.yoda:'Zj ($k_{T}^{0}=0)$' 
	;;
esac