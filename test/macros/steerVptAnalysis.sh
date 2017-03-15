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
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 photos=True doRivetScan=True nFinal=2 seed=1 maxEvents=1000
	cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4:SpaceShower:pT0Ref=1.5:SpaceShower:pTmin=0.4 photos=True doRivetScan=False meWeight=120 nFinal=2 seed=1 usePoolSource=True input=/store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/LHE/MCRUN2_71_V1-v1/120000/FEB8D25D-D0F5-E611-A0E5-0CC47A1DF806.root
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 nFinal=1 seed=1 maxEvents=1000 input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_10001.lhe
	#cmsRun ${lhecfg} output=test ueTune=CUEP8M2T4 photos=True nFinal=2 seed=1 maxEvents=1000 input=/store/group/phys_smp/Wmass/perrozzi/powheg/test_Zj_8TeV_ptsqmin4/cmsgrid_final.lhe.xz
	;;

    NTUPLETUNE)

	baseeosDirs=(
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/LHE/MCRUN2_71_V1-v1
	)
	baseTags=(
	    ZJ_central
	    ZJ_ptsqmin4
	)

	pT0RefScan=(1.0   2.0   2.0   10.0 10.0)
	pTminScan=(0.5 0.5 1.0 0.5 5.0)
	for w in 0 24 48; do
	    for p in "${!pT0RefScan[@]}"; do
		pT0Ref=${pT0RefScan[$p]};
		pTmin=${pTminScan[$p]}; 
	    
		for b in "${!baseeosDirs[@]}"; do 
		    baseeos=${baseeosDirs[$b]};
		    tag=${baseTags[$b]};
		    num=0;
		    subdirs=(`eos ls ${baseeos}`);
		    for i in ${subdirs[@]}; do
			a=(`eos ls ${baseeos}/${i}`)
			for k in ${a[@]}; do		    
			    num=$((num + 1));
			    input=${baseeos}/${i}/${k};

			    cmd="cmsRun ${lhecfg} output=${tag}_Scan${p}_${num} ueTune=CUEP8M2T4:SpaceShower:pT0Ref=${pT0Ref}:SpaceShower:pTmin=${pTmin} photos=True doRivetScan=False meWeight=${w} nFinal=2 seed=${num} usePoolSource=True input=${input}"
			    #echo ${cmd}
			    bsub -q 2nw $script "${cmd}";
			done
		    done
		done
	    done
	done
	;;



    NTUPLEMCRUN2)
	lhe=(
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_central/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_hfact0p5/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin400/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
            /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin20/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	    /ZJ_ZToMuMu_powheg_minlo_8TeV_CT14/RunIIWinter15wmLHE-MCRUN2_71_V1-v1/LHE
	)
	req=(
	    ZJ_central
	    ZJ_hfact0p5
	    ZJ_ptsqmin400
	    ZJ_ptsqmin20
	    ZJ_ptsqmin4
	    ZJ_ct14
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
    NTUPLEMCRUN2LOCAL)

	baseeosDirs=(
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_hfact0p5/LHE/MCRUN2_71_V1-v1
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/LHE/MCRUN2_71_V1-v1
	    /store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin400/LHE/MCRUN2_71_V1-v1
	)
	baseTags=(
	    ZJ_central
	    ZJ_hfact0p5
	    ZJ_ptsqmin4
	    ZJ_ptsqmin400
	)
	    
	for b in "${!baseeosDirs[@]}"; do 
	    baseeos=${baseeosDirs[$b]};
	    tag=${baseTags[$b]};
	    num=0;
	    subdirs=(`eos ls ${baseeos}`);
	    for i in ${subdirs[@]}; do
		a=(`eos ls ${baseeos}/${i}`)
		for k in ${a[@]}; do		    
		    num=$((num + 1));
		    input=${baseeos}/${i}/${k};		    
		    bsub -q 2nw $script "cmsRun ${lhecfg} output=${tag}_${num} input=${input} ueTune=CUEP8M2T4 photos=True nFinal=2 doRivetScan=True usePoolSource=True"; 
		done
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

    RIVETPLOTMCRUN2)

	yodaDir=eos/cms/store/cmst3/user/psilva/Wmass
	
	#convert yodas to root 
	mkdir plots
	cd plots
	yoda2root.py ../../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda
	baseTags=(
            ZJ_central
            ZJ_hfact0p5
            ZJ_ptsqmin4
            ZJ_ptsqmin400
        )
	for i in ${baseTags[@]}; do
	    for w in `seq 0 120`; do
		continue
		yoda2root.py ../${yodaDir}/ntuples/${i}.w${w}.yoda
	    done
	done
	cd -

	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
        #    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
        #    -o ~/public/html/Zj_check \
        #    ${yodaDir}/ntuples/Zj_nominalphotos.yoda:'PW(Minlo)+PY8 (NNPDF3.0) - private' \
        #    ${yodaDir}/ntuples/ZJ_central.w1.yoda:'PW(Minlo)+PY8 (NNPDF3.0) - central';

	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
            -o ~/public/html/Zj_check \
	    ${yodaDir}/ntuples/ZJ_central.w59.yoda:'$(\mu_{R},\mu_{F})=(8,4)$' \
	    ${yodaDir}/ntuples/ZJ_ptsqmin4.w47.yoda:'$ptsqmin=4, (\mu_{R},\mu_{F})=(4,3)$' \
	    ${yodaDir}/ntuples/ZJ_ptsqmin4.w60.yoda:'$ptsqmin=4, (\mu_{R},\mu_{F})=(8,8)$' 
            #${yodaDir}/ntuples/ZJ_central.w1.yoda:'PW(Minlo)+PY8 (NNPDF3.0)' \
            #${yodaDir}/ntuples/ZJ_central.w60.yoda:'$(\mu_{R},\mu_{F})=(8,8)$' \
            #${yodaDir}/ntuples/ZJ_central.w57.yoda:'$(\mu_{R},\mu_{F})=(8,2)$';


	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
        #    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
        #    -o ~/public/html/Zj_ptsqmin \
        #    ${yodaDir}/ntuples/ZJ_central.w1.yoda:'PW(Minlo)+PY8 (NNPDF3.0)' \
        #    ${yodaDir}/ntuples/ZJ_ptsqmin4.w1.yoda:'ptsqmin$=4$' \
        #    ${yodaDir}/ntuples/ZJ_ptsqmin400.w1.yoda:'ptsqmin$=400$';
	#
	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
        #    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
        #    -o ~/public/html/Zj \
        #    ${yodaDir}/ntuples/ZJ_central.w1.yoda:'PW(Minlo)+PY8 (NNPDF3.0)' \
        #    ${yodaDir}/ntuples/ZJ_hfact0p5.w1.yoda:'hfact=$M_{Z}/2$';
	#
	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	#    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
        #    -o ~/public/html/Z_muf \
        #    ${yodaDir}/ntuples/ZJ_central.w7.yoda:'$(\mu_{R},\mu_{F})=(1,1/4)$' \
        #    ${yodaDir}/ntuples/ZJ_central.w9.yoda:'(1,1/2)' \
        #    ${yodaDir}/ntuples/ZJ_central.w0.yoda:'(1,1)' \
        #    ${yodaDir}/ntuples/ZJ_central.w2.yoda:'(1,2)' \
        #    ${yodaDir}/ntuples/ZJ_central.w4.yoda:'(1,4)';
	
	#rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
        #    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
        #    -o ~/public/html/Z_mur \
        #    ${yodaDir}/ntuples/ZJ_central.w99.yoda:'$(\mu_{R},\mu_{F})=(1/2,1)$' \
        #    ${yodaDir}/ntuples/ZJ_central.w0.yoda:'(1,1)' \
        #    ${yodaDir}/ntuples/ZJ_central.w22.yoda:'(2,1)' \
        #    ${yodaDir}/ntuples/ZJ_central.w44.yoda:'(4,1)';

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