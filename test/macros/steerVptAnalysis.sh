#!/bin/bash

WHAT=${1}

script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
lhecfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENFromLHEandAnalysis_cfg.py
py8cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py

cffTags=(
    az
    nominal
    noPrimKt
    ueup
    uedn
    fsrup
    fsrdown
    isrup
    isrdown    
)

tunesList=(
    AZ
    CUEP8M2T4
    CUEP8M2T4:primordialKToff 
    CUEP8M2T4up
    CUEP8M2T4down
    CUEP8M2T4FSRup
    CUEP8M2T4FSRdown
    CUEP8M2T4ISRup
    CUEP8M2T4ISRdown
)



export LSB_JOB_REPORT_MAIL=N

case $WHAT in
    TEST )
	#cmsRun ${py8cfg}  output=test hadronizer=ZToMuMu_CUEP8M2T4 seed=1 maxEvents=1000
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 nFinal=2 seed=1 maxEvents=1000
	cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 nFinal=1 seed=1 maxEvents=1000 input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_10001.lhe
	;;
    NTUPLEVJ )

	#FROM LHE stored in EOS
	for proc in Zj Wminusj Wplusj; do
	    lheDir=/store/cmst3/user/psilva/Wmass/${proc}
	    fcounter=1
	    a=(`eos ls ${lheDir}`)
	    for i in ${a[@]}; do
		if [[ $i == *"cmsgrid"* ]]
		then
		    continue
		fi
		fcounter=$((fcounter+1))
		for k in "${!tunesList[@]}"; do 
		    cff=${tunesList[$k]};
		    tag=${cffTags[$k]};
		    echo "${proc}_${tag}_${fcounter} ${cff}"
		    bsub -q 8nh $script "cmsRun ${lhecfg} output=${proc}_${tag}_${fcounter} input=${lheDir}/${i} ueTune=${cff} nFinal=2 seed=${fcounter}";
		done
	    done
	done
	;;
    NTUPLEPY8 )

	#FROM PY8 STANDALONE
	for fcounter in `seq 0 400`; do
	    for proc in WToMuNu ZToMuMu; do
		for k in "${!cffTags[@]}"; do 
		    cff=${tunesList[$k]};
		    tag=${cffTags[$k]};
		    echo "${proc}_${tag}_${fcounter} ${cff}"
		    bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_${tag}_${fcounter} hadronizer=${proc}_${cff} seed=${fcounter} maxEvents=50000";
		done

		echo "${proc}_AZ CT10nlo_as_0118"
		bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_azct10_${fcounter}      pdfSet=CT10nlo_as_0118 hadronizer=${proc}_AZ seed=${fcounter}        maxEvents=50000";
		echo "${proc}_CUEP8M2T4 CT10nlo_as_0118"
		bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_nominalct10_${fcounter} pdfSet=CT10nlo_as_0118 hadronizer=${proc}_CUEP8M2T4 seed=${fcounter} maxEvents=50000";
	    done
	done
	;;
    NTUPLEPW )

	for i in `seq 1 200`; do
	    for k in "${!cffTags[@]}"; do
                cff=${tunesList[$k]};
                tag=${cffTags[$k]};
       
		num=$((i + 10000))
		bsub -q 2nw $script "cmsRun ${lhecfg} output=dy2mumu_ct10_${k}_${i} input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_${num}.lhe pdfSet=CT10nlo_as_0118 ueTune=${cff} nFinal=1 seed=${i}"
	    done
	done

	;;
    MERGE )
	#/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select -b fuse mount eos
	python scripts/mergeOutputs.py eos/cms/store/cmst3/user/psilva/Wmass/ntuples/Chunks eos/cms/store/cmst3/user/psilva/Wmass/ntuples
	#/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select -b fuse umount eos
	;;

    RIVETPLOT )
	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/PY8 \
	    ${outdir}/PY8ZToMuMu_nominal.yoda:'PY8 CUETP8M2T4' \
	    ${outdir}/PY8ZToMuMu_fsrup.yoda:'FSR up' \
	    ${outdir}/PY8ZToMuMu_fsrdown.yoda:'FSR dn' \
	    ${outdir}/PY8ZToMuMu_isrup.yoda:'ISR up' \
	    ${outdir}/PY8ZToMuMu_isrdown.yoda:'ISR dn' \
	    ${outdir}/PY8ZToMuMu_ueup.yoda:'UE up' \
	    ${outdir}/PY8ZToMuMu_uedn.yoda:'UE dn'
	    #${outdir}/Zj_noPrimKt.yoda:'$k_{T}^{0}=0$'

	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	#    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	#    -o ~/public/html/Zj \
	#    ${outdir}/Zj_nominal.yoda:'Zj CUETP8M2T4' \
	#    ${outdir}/Zj_fsrup.yoda:'FSR up' \
	#    ${outdir}/Zj_fsrdown.yoda:'FSR dn' \
	#    ${outdir}/Zj_isrup.yoda:'ISR up' \
	#    ${outdir}/Zj_isrdown.yoda:'ISR dn' \
	#    ${outdir}/Zj_ueup.yoda:'UE up' \
	#    ${outdir}/Zj_uedn.yoda:'UE dn' \
	#    ${outdir}/Zj_noPrimKt.yoda:'$k_{T}^{0}=0$'
	;;
    ANA )


	NBINS=100
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Zj_nominal.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_nominal.root       -c nl==2;
	#for var in fsrup fsrdown isrup isrdown ueup uedn az noPrimKt; do
	#    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Zj_${var}.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_${var}.root     -c nl==2 --templ Zj_nominal.root &
	#done

	python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wminusj_nominal.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_nominal.root -c nl==1 --templ Zj_nominal.root --templMode 2 
	python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wplusj_nominal.root  -i /store/cmst3/user/psilva/Wmass/ntuples/Wplusj_nominal.root  -c nl==1 --templ Wminusj_nominal.root
	for var in fsrup fsrdown isrup isrdown ueup uedn az noPrimKt; do
	    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Wminusj_${var}.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_${var}.root -c nl==1 --templ Wminusj_nominal.root &
	    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Wplusj_${var}.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wplusj_${var}.root -c nl==1 --templ Wminusj_nominal.root &
	done

	;;

esac