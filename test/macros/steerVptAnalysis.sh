#!/bin/bash

WHAT=${1}
RIVETSCAN=${2}

script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
lhecfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENFromLHEandAnalysis_cfg.py
py8cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py

cffTags=(
    #az
    #nominal
    #noPrimKt
    #ueup
    #uedn
    #fsrup
    #fsrdown
    #isrup
    #isrdown    
    nominalphotos
)

tunesList=(
#    AZ
#    CUEP8M2T4
#    CUEP8M2T4:primordialKToff 
#    CUEP8M2T4up
#    CUEP8M2T4down
#    CUEP8M2T4FSRup
#    CUEP8M2T4FSRdown
#    CUEP8M2T4ISRup
#    CUEP8M2T4ISRdown
    CUEP8M2T4:Photos
)



export LSB_JOB_REPORT_MAIL=N

case $WHAT in
    TEST )
	#cmsRun ${py8cfg}  output=test hadronizer=ZToMuMu_CUEP8M2T4 seed=1 maxEvents=1000
	cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 photos=True doRivetScan=True nFinal=2 seed=1 maxEvents=1000
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 nFinal=1 seed=1 maxEvents=1000 input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_10001.lhe
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 photos=True nFinal=2 seed=1 maxEvents=1000 input=/store/group/phys_smp/Wmass/perrozzi/powheg/test_Zj_8TeV_ptsqmin4/cmsgrid_final.lhe.xz
	;;

    NTUPLEMCRUN2)
	lhe=(
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_central/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    #/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_hfact0p5/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    #/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin400/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
            #/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin20/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    #/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    #/ZJ_ZToMuMu_powheg_minlo_8TeV_CT14/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	)
	req=(
	    central
	    #hfact0p5
	    #ptsqmin400
	    #ptsqmin20
	    #ptsqmin4
	    #ct14
	)
	crabTempl=$CMSSW_BASE/src/UserCode/VptGenAnalysis/test/crab_VptAnalysis.py.templ
	for k in ${!lhe[@]}; do
	    i=${lhe[$k]};
	    j=${req[$k]};
	    sedstr="s%_REQUEST_%${j}%;s%_PSET_%${lhecfg}%;s%_DSET_%${i}%;"
	    cat ${crabTempl} | sed "${sedstr}" > crab_${j}.py
	    crab submit crab_${j}.py
	done
	;;
    NTUPLEVJscan )
	lheDir=/store/group/phys_smp/Wmass/perrozzi/powheg/test_Zj_8TeV_ptsqmin4/
	fcounter=1
	proc=Zj_ptsqmin4
	a=(`eos ls ${lheDir}`)
	for i in ${a[@]}; do
	    if [[ $i != *"cmsgrid"* ]]
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

		    baseOpts="${lhecfg} output=${proc}_${tag}_${fcounter} input=${lheDir}/${i} ueTune=${cff} nFinal=2 seed=${fcounter}"
		    if [[ $cff == *"Photos"* ]]
                    then
			baseOpts="${baseOpts} photos=True"
                    fi		    
		    if [[ $RIVETSCAN == *"True"* ]]
		    then
			baseOpts="${baseOpts} doRivetScan=True"

		    fi
		    #cmsRun ${baseOpts}		    
		    bsub -q 8nh $script "cmsRun ${baseOpts}";
		done
	    done
	done
	;;
    NTUPLEPY8 )

	cffTags=( 
	    renormup
	    renormdown
	    factup
	    factdown
	    combup
	    combdown
	)
	tunesList=(
	    CUEP8M2T4:renormUp
	    CUEP8M2T4:renormDown
	    CUEP8M2T4:factorUp
	    CUEP8M2T4:factorDown
	    CUEP8M2T4:factorUp:renormUp
	    CUEP8M2T4:factorDown:renormDown
	)

	#FROM PY8 STANDALONE
	for fcounter in `seq 0 250`; do
	    for proc in WToMuNu; do #ZToMuMu; 
		for k in "${!cffTags[@]}"; do 
		    cff=${tunesList[$k]};
		    tag=${cffTags[$k]};
		    echo "${proc}_${tag}_${fcounter} ${cff}"
		    bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_${tag}_${fcounter} hadronizer=${proc}_${cff} seed=${fcounter} maxEvents=20000";
		done

		#echo "${proc}_AZ CT10nlo_as_0118"
		#bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_azct10_${fcounter}      pdfSet=CT10nlo_as_0118 hadronizer=${proc}_AZ seed=${fcounter}        maxEvents=50000";
		#echo "${proc}_CUEP8M2T4 CT10nlo_as_0118"
		#bsub -q 8nh $script "cmsRun ${py8cfg} output=PY8${proc}_nominalct10_${fcounter} pdfSet=CT10nlo_as_0118 hadronizer=${proc}_CUEP8M2T4 seed=${fcounter} maxEvents=50000";
	    done
	done
	;;
    NTUPLEPW )

	for i in `seq 1 200`; do
	    for k in "${!cffTags[@]}"; do
                cff=${tunesList[$k]};
                tag=${cffTags[$k]};
       
		num=$((i + 10000))
		bsub -q 2nw $script "cmsRun ${lhecfg} output=dy2mumu_ct10_${tag}_${i} input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_${num}.lhe pdfSet=CT10nlo_as_0118 ueTune=${cff} nFinal=1 seed=${i}"
	    done
	done

	;;
    MERGE )
	/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select -b fuse mount eos
	python scripts/mergeOutputs.py eos/cms/store/cmst3/user/psilva/Wmass/ntuples/Chunks eos/cms/store/cmst3/user/psilva/Wmass/ntuples
	/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select -b fuse umount eos
	;;

    RIVETPLOT )
	
	yodaDir=eos/cms/store/cmst3/user/psilva/Wmass/ntuples

        rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Z_comp \
	    ${yodaDir}/Zj_nominal.yoda:'PW(Minlo)+PY8 (NNPDF3.0)' \
	    ${yodaDir}/dy2mumu_ct10_nominal.yoda:'PW+PY8 (CT10)' \
	    ${yodaDir}/PY8ZToMuMu_nominalct10.yoda:'PY8 (CT10)'

        rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Zj \
	    ${yodaDir}/Zj_nominalphotos_w0.yoda:'Zj+PY8+Photos' \
	    ${yodaDir}/Zj_nominal.yoda:'Zj+Pythia8'
	
	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Zj_ME \
	    ${yodaDir}/Zj_nominalphotos_w0.yoda:'Zj' \
	    ${yodaDir}/Zj_nominalphotos_w2.yoda:'$2\mu_F$' \
	    ${yodaDir}/Zj_nominalphotos_w3.yoda:'$1/2\mu_F$' \
	    ${yodaDir}/Zj_nominalphotos_w4.yoda:'$2\mu_R$' \
	    ${yodaDir}/Zj_nominalphotos_w5.yoda:'$2\mu_{R,F}$' \
	    ${yodaDir}/Zj_nominalphotos_w7.yoda:'$1/2\mu_R$' \
	    ${yodaDir}/Zj_nominalphotos_w9.yoda:'$1/2\mu_{R,F}$'

	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Zj_UE \
	    ${yodaDir}/Zj_nominalphotos_w0.yoda:'Zj' \
	    ${yodaDir}/Zj_fsrup.yoda:'FSR up' \
	    ${yodaDir}/Zj_fsrdown.yoda:'FSR dn' \
	    ${yodaDir}/Zj_isrup.yoda:'ISR up' \
	    ${yodaDir}/Zj_isrdown.yoda:'ISR dn' \
	    ${yodaDir}/Zj_ueup.yoda:'UE up' \
	    ${yodaDir}/Zj_uedn.yoda:'UE dn' \
	    ${yodaDir}/Zj_noPrimKt.yoda:'$k_{T}^{0}=0$'
	    
	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
	    -o ~/public/html/Zj_PY8 \
	    ${yodaDir}/Zj_nominalphotos_w0.yoda:'Zj' \
	    ${yodaDir}/PY8ZToMuMu_nominal.yoda:'PY8 CUETP8M2T4' \
	    ${yodaDir}/PY8ZToMuMu_nominalct10.yoda:'PY8 CUETP8M2T4 CT10'	
	;;
    ANA )


	NBINS=100
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Zj_nominal.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_nominal.root       -c nl==2;
	#for var in ; do # fsrup fsrdown isrup isrdown ueup uedn az noPrimKt; do
	    #python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Zj_${var}.root     -i /store/cmst3/user/psilva/Wmass/ntuples/Zj_${var}.root     -c nl==2 --templ Zj_nominal.root &
	#done
	
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wminusj_nominal.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_nominal.root -c nl==1 --templ Zj_nominal.root --templMode 2 
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -o Wplusj_nominal.root  -i /store/cmst3/user/psilva/Wmass/ntuples/Wplusj_nominal.root  -c nl==1 --templ Wminusj_nominal.root
	#for var in fsrup fsrdown isrup isrdown ueup uedn az noPrimKt; do
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Wminusj_${var}.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wminusj_${var}.root -c nl==1 --templ Wminusj_nominal.root&
	#
	#python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o Wplusj_${var}.root -i /store/cmst3/user/psilva/Wmass/ntuples/Wplusj_${var}.root -c nl==1 --templ Wminusj_nominal.root &
	#done


	for var in factup factdown renormup renormdown combup combdown; do #fsrup fsrdown isrup isrdown ueup uedn az noPrimKt azct10 nominal nominalct10; do
	    #python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o PY8ZToMuMu_${var}.root        -i /store/cmst3/user/psilva/Wmass/ntuples/PY8ZToMuMu_${var}.root  -c nl==2 --templ Zj_nominal.root  &
	    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o PY8ZWminusToMuMu_${var}.root  -i /store/cmst3/user/psilva/Wmass/ntuples/PY8WToMuNu_${var}.root  -c nl==1 --templ Wminusj_nominal.root --charge -1& 
	    python test/macros/runNtupleAnalysis.py --nbins ${NBINS} -w 0 -o PY8ZWplusToMuMu_${var}.root   -i /store/cmst3/user/psilva/Wmass/ntuples/PY8WToMuNu_${var}.root  -c nl==1 --templ Wminusj_nominal.root --charge 1& 
	done

	;;

esac