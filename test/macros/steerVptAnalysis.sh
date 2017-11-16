#!/bin/bash

WHAT=${1}

script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runVptAnalysis_cfg.py
#py8cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py

export LSB_JOB_REPORT_MAIL=N

case $WHAT in
    TEST )

        #to be hadronized
        inF=/store/mc/RunIIWinter15wmLHE/WplusJ_WToMuNu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1/50000/FE65D6B6-6E16-E711-A413-A0369F310374.root
        #inF=/store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_ptsqmin4/LHE/MCRUN2_71_V1-v1/120000/FEB8D25D-D0F5-E611-A0E5-0CC47A1DF806.root         
	cmsRun ${cfg} output=test saveEDM=False \
            usePoolSource=True input=${inF} \
            seed=1 nFinal=2 \
            genParams="photos=off,ueTune=CUETP8M1,SpaceShower:alphaSvalue=0.100,BeamRemnants:primordialKThard=2.722,MultiPartonInteractions:pT0Ref=2.5" \
            weightListForRivet=0;

        #allready hadronized
        #cmsRun ${cfg} output=test saveEDM=False \
        #    usePoolSource=True \
        #    input=/store/mc/RunIISummer15GS/DYToMuMu_M_50_TuneAZ_PDFfix_8TeV_pythia8/GEN/GenOnly_MCRUN2_71_V1-v3/10000/FA9D3615-8788-E711-85F2-0CC47A7AB7A0.root \
        #    noHadronizer=True \
        #    weightListForRivet=0 useMEWeightsForRivet=False;
	;;

    NTUPLE)

	#baseeos=/store/mc/RunIIWinter15wmLHE/ZJ_ZToMuMu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1
        #tag=ZJ_central

	baseeos=/store/mc/RunIIWinter15wmLHE/WminusJ_WToMuNu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1
        tag=WminusJ_central
        
        baseeos=/store/mc/RunIIWinter15wmLHE/WplusJ_WToMuNu_powheg_minlo_8TeV_NNPDF30_central/LHE/MCRUN2_71_V1-v1
        tag=WplusJ_central

        #baseeos=/store/mc/RunIISummer15GS/DYToMuMu_M_50_TuneAZ_PDFfix_8TeV_pythia8/GEN/GenOnly_MCRUN2_71_V1-v3
        #tag=PY8_TuneAZ

	subdirs=(`eos ls ${baseeos}`);
	for i in ${subdirs[@]}; do
	    a=(`eos ls ${baseeos}/${i}`)
	    for k in ${a[@]}; do		    
		num=$((num + 1));
		input=${baseeos}/${i}/${k};
                
                genParams="photos=off,ueTune=CUETP8M1,SpaceShower:alphaSvalue=0.100,BeamRemnants:primordialKThard=2.722,MultiPartonInteractions:pT0Ref=2.5"
		cmd="cmsRun ${cfg} output=${tag}_${num} saveEDM=False usePoolSource=True input=${input} seed=${num} nFinal=2 genParams=${genParams}"
         
                #cmd="cmsRun ${cfg} output=${tag}_${num} saveEDM=False usePoolSource=True input=${input} noHadronizer=True weightListForRivet=0 useMEWeightsForRivet=False"
                echo ${cmd}
		bsub -q 2nw $script "${cmd}";
	    done
	done
        ;;

    MERGE )
        mergeOutput=/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central
        chunksDir=/store/cmst3/user/psilva/Wmass/ntuples/Chunks
        #python test/macros/checkNtupleIntegrity.py /eos/cms/${chunksDir} ZJ_central
        #python test/macros/checkNtupleIntegrity.py /eos/cms/${chunksDir} PY8_TuneAZ
        python test/macros/checkNtupleIntegrity.py /eos/cms/${chunksDir} WplusJ_central
        python test/macros/checkNtupleIntegrity.py /eos/cms/${chunksDir} WminusJ_central
        eos mkdir ${mergeOutput}
	python scripts/mergeOutputs.py /eos/cms/${chunksDir} /eos/cms/${mergeOutput}
	;;

    RIVET )
        yodaDir=/eos/cms/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central
	rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
            -o ~/public/html/ZJ_WM2 \
	    ${yodaDir}/w0_ZJ_central.yoda:'PW WM2 $(\mu_{R},\mu_{F})=(1,1)$' \
            ${yodaDir}/w48_ZJ_central.yoda:'PW WM2 $(\mu_{R},\mu_{F})=(4,4)$' \
            ${yodaDir}/w0_PY8_TuneAZ.yoda:'PY8 AZ'
 
	rivet-mkhtml -s --times \
	    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
            -o ~/public/html/ZJ_WM2_PY8 \
            ${yodaDir}/w0_PY8_TuneAZ.yoda:'PY8 AZ' \
	    ${yodaDir}/w48_ZJ_central.yoda:'PW WM2 $(\mu_{R},\mu_{F})=(4,4)$' 
        ;;

    RIVET2ROOT )

	yodaDir=/eos/cms/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central/
	
	#convert yodas to root 
	mkdir -p plots
	cd plots
	yoda2root.py ../data/ATLAS_2015_I1408516_MU.yoda
	baseTags=(
            ZJ_central
            PY8_TuneAZ
        )
	for i in ${baseTags[@]}; do
	    for w in `seq 0 121`; do
                file=${yodaDir}/w${w}_${i}.yoda
                if [ -f ${file} ]; then 
	            echo "Converting $file"
	            yoda2root.py ${file}
                fi
	    done
	done
	cd -
	;;

    OPTIMIZEQCDSCALE )
        python test/macros/xsec.py
        python test/macros/scanChisquareSimple.py
        ;;

    ANA )
        baseDir=/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central/
        a=(`ls /eos/cms/${baseDir}/*.root`)

        template=plots/ana_template.root
        python test/macros/runNtupleAnalysis.py --nbins 20 -o ${template} -i /eos/cms/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central/WplusJ_central_0.root
        
        for i in ${a[@]}; do
            oname=`basename ${i}`;
            echo ${i} ${oname}
            python test/macros/runNtupleAnalysis.py  --templ ${template} -o plots/${oname} -i ${i} &      
        done
        ;;
    MERGEANA )
        for i in ZJ_central WplusJ_central WminusJ_central PY8_TuneAZ; do
            rm plots/${i}_merged.root;
            hadd -f -k plots/${i}_merged.root plots/${i}_*.root;
        done
        ;;

    RIVETTUNE)
	yodaDir=eos/cms/store/cmst3/user/psilva/Wmass
	for p in central ptsqmin4; do
	    for w in 0 24 48; do
		rivet-mkhtml -s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' \
		    --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot \
		    -o ~/public/html/Zj_spaceshower_${p}_${w} \
		    ${yodaDir}/ntuples/ZJ_${p}.w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(2,0.2)$' \
		    ${yodaDir}/ntuples/TuneScan/ZJ_${p}_Scan0w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(1,0.5)$' \
		    ${yodaDir}/ntuples/TuneScan/ZJ_${p}_Scan1w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(2,0.5)$' \
		    ${yodaDir}/ntuples/TuneScan/ZJ_${p}_Scan2w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(2,1)$' \
		    ${yodaDir}/ntuples/TuneScan/ZJ_${p}_Scan3w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(10,0.5)$' \
		    ${yodaDir}/ntuples/TuneScan/ZJ_${p}_Scan4w${w}.yoda:'$(p_T^{0ref},p_T^{\min})=(10,5)$';
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