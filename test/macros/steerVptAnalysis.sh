#!/bin/bash

WHAT=${1}

outdir=/afs/cern.ch/user/p/psilva/work/Wmass/rivet/data
script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
lhecfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENFromLHEandAnalysis_cfg.py
py8cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/runGENandAnalysis_cfg.py

cffTags=(
    nominal
#    noPrimKt
    ueup
    uedn
    fsrup
    fsrdown
    isrup
    isrdown
#    hwpp
)

export LSB_JOB_REPORT_MAIL=N

case $WHAT in
    TEST )
	cmsRun ${py8cfg} \
	    output=/tmp/test \
	    hadronizer=ZToMuMu_CUEP8M2T4 \
	    seed=1 \
	    maxEvents=1000
	;;
    NTUPLE )

	mkdir -p ${outdir}	

	#FROM LHE stored in EOS
	#cffList=(
	#    Hadronizer_TuneCUETP8M2T4_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
        #    Hadronizer_TuneCUETP8M2T4_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff:primordialKToff
	#    Hadronizer_TuneCUETP8M2T4up_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	#    Hadronizer_TuneCUETP8M2T4down_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	#    Hadronizer_TuneCUETP8M2T4FSRup_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff    
        #    Hadronizer_TuneCUETP8M2T4FSRdown_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff  
	#    Hadronizer_TuneCUETP8M2T4ISRup_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
	#    Hadronizer_TuneCUETP8M2T4ISRdown_8TeV_powhegEmissionVeto_2p_LHE_pythia8_cff
        #    Hadronizer_TuneEE_5C_8TeV_Herwigpp_cff
	#)

	#for proc in Zj Wminusj; do #Wplusj 
	#    lheDir=/store/cmst3/user/psilva/Wmass/${proc}
	#    fcounter=1
	#    a=(`eos ls ${lheDir}`)
	#    for i in ${a[@]}; do
	#	if [[ $i == *"cmsgrid"* ]]
	#	then
	#	    continue
	#	fi
	#	fcounter=$((fcounter+1))
	#	for k in "${!cffList[@]}"; do 
	#	    cff=${cffList[$k]};
	#	    tag=${cffTags[$k]};
	#	    echo "${proc}_${tag}_${fcounter} ${cff}"
	#	    bsub -q 8nh $script "cmsRun ${lhecfg} output=${outdir}/${proc}_${tag}_${fcounter} input=${lheDir}/${i} hadronizer=${cff} seed=${fcounter}";
	#	done
	#    done
	#done

	#FROM PY8 STANDALONE
	cffList=(
	    CUEP8M2T4
	    #CUEP8M2T4:primordialKToff 
	    CUEP8M2T4up
	    CUEP8M2T4down
	    CUEP8M2T4FSRup
	    CUEP8M2T4FSRdown
	    CUEP8M2T4ISRup
	    CUEP8M2T4ISRdown
	    #HW
	)
	for fcounter in `seq 1 400`; do
	    for proc in ZToMuMu; do
		for k in "${!cffTags[@]}"; do 
		    cff=${cffList[$k]};
		    tag=${cffTags[$k]};
		    echo "${proc}_${tag}_${fcounter} ${cff}"
		    bsub -q 8nh $script "cmsRun ${py8cfg} output=${outdir}/${proc}_${tag}_${fcounter} hadronizer=${proc}_${tag} seed=${fcounter} maxEvents=5000";
		done
	    done
	done


#	for i in `seq 1 200`; do
#	    num=$((i + 10000))
#	    bsub -q 8nh $script "cmsRun ${lhecfg} output=${outdir}/dy2mumu_ct10_${i} input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_${num}.lhe hadronizer=powhegEmissionVeto_1p_LHE_pythia8"
#	done

	;;
    MERGE )
	for baseProc in Zj Wminusj; do #Wplusj
	    for k in "${!cffTags[@]}"; do 
		proc="${baseProc}_${cffTags[$k]}";

		regex=".*${proc}_[0-9]*\.yoda$"
		a=(`exec find ${outdir} -regex ${regex}`)
		if [ ${#a[@]} -eq 0 ]; then
		    continue
		fi

		yodaFiles=""
		rootFiles=""
		for i in ${a[@]}; do 
		    yodaFiles="${yodaFiles} ${i}"
		    rootFiles="${rootFiles} ${i/yoda/root}"
		done

		yodamerge -o ${outdir}/${proc}.yoda ${yodaFiles}
		hadd -f -k ${outdir}/${proc}.root ${rootFiles}
		#mv -t ${outdir}/Chunks ${yodaFiles}
		#mv -t ${outdir}/Chunks ${rootFiles}
		xrdcp ${outdir}/${proc}.root root://eoscms//eos/cms/store/cmst3/user/psilva/Wmass/ntuples/${proc}.root 
		rm ${outdir}/${proc}.root
	    done
	done
	;;

    RIVETPLOT )
	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Zj \
	    ${outdir}/Zj_nominal.yoda:'Zj CUETP8M2T4' \
	    ${outdir}/Zj_fsrup.yoda:'FSR up' \
	    ${outdir}/Zj_fsrdown.yoda:'FSR dn' \
	    ${outdir}/Zj_isrup.yoda:'ISR up' \
	    ${outdir}/Zj_isrdown.yoda:'ISR dn' \
	    ${outdir}/Zj_ueup.yoda:'UE up' \
	    ${outdir}/Zj_uedn.yoda:'UE dn' \
	    ${outdir}/Zj_noPrimKt.yoda:'$k_{T}^{0}=0$'
	;;
    ANA )

	NBINS=25
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Zj_nominal.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_nominal.root     -c nl==2;
	python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wminusj_nominal.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_nominal.root -c nl==1 --templ Zj_nominal.root &
	python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wplusj_nominal.root  -i /store/cmst3/user/psilva/Wmass/ntuples/Wplusj_nominal.root  -c nl==1 --templ Zj_nominal.root &
	for var in fsrup fsrdown isrup isrdown ueup uedn; do
	    #python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Zj_${var}.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_${var}.root     -c nl==2 --templ Zj_nominal.root &
	    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Wminusj_${var}.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_${var}.root -c nl==1 --templ Zj_nominal.root &
	done

	;;

esac