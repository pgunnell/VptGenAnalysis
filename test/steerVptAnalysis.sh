#!/bin/bash

WHAT=${1}

outdir=/afs/cern.ch/user/p/psilva/work/Wmass/rivet/data

case $WHAT in
    NTUPLE )

	script=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh;
	cfg=${CMSSW_BASE}/src/UserCode/VptGenAnalysis/test/runGENandAnalysis_cfg.py
	mkdir -p ${outdir}	
	
	for i in `seq 1 100`; do
	    num=$((i + 10000))
	    bsub -q 8nh $script "cmsRun ${cfg} output=${outdir}/dy2mumu_ct10_${i} input=/store/lhe/5663/DYToMuMu_M-20_CT10_8TeV-powheg_${num}.lhe hadronizer=powhegEmissionVeto_1p_LHE_pythia8"
	done

	
	exit -1

	for proc in Zj Wj; do
	    for i in `seq 1 100`; do 
		commonOpts=test/runGENRivetModule_cfg.py module=ZPt input=/store/cmst3/user/psilva/Wmass/powhegbox_${proc}/seed_${i}_pwgevents.lhe;
		bsub -q 8nh $script "cmsRun $commonOpts output=${proc}/py8_noprimkt_${i}.yoda hadronizer=powhegEmissionVeto_2p_LHE_pythia8:primordialKToff";
		bsub -q 8nh $script "cmsRun $commonOpts output=${proc}/hwpp_${i}.yoda hadronizer=TuneEE_5C_8TeV_Herwigpp";
		for  w in 0 3 6 1 2 4 8 111; do
		    bsub -q 8nh $script "cmsRun $commonOpts LHEweightNumber=${w} output=${proc}/py8_w${w}_${i}.yoda hadronizer=powhegEmissionVeto_2p_LHE_pythia8";
		done
	    done
	done
	;;
    MERGE )
	WARN=""
	for proc in Zj Wj; do
		for prefix in hwpp py8_noprimkt py8_w0 py8_w3 py8_w6 py8_w1 py8_w2 py8_w4 py8_w8 py8_w111; do
		    toMerge=""
		    for i in `seq 1 100`; do
			file="${prefix}_${i}.yoda"
			if [ ! -f "${proc}/$file" ]; then
			    WARN="${WARN} ${proc}/${file}"
			    continue
			fi

			fileSize=`du -sb ${proc}/${file} | awk '{print $1}'`
			if [ $fileSize -gt 0 ]; then 
			    toMerge="${toMerge} ${proc}/${file}";
			else
			    WARN="${WARN} ${proc}/${file}"
			fi
		    done
		    
		    echo ${toMerge}
		    yodamerge -o ${proc}/${prefix}.yoda ${toMerge}
		    yoda2root.py ${proc}/${prefix}.yoda
		    mv ${prefix}.root ${proc}/
	            #rm ${toMerge}
		done
	done

	#rm ${WARN}
	echo "The following files were missing or corrupted: ${WARN}"
	;;

    PLOT )
	commonOpts="-s --times ../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.yoda:'data' --config=../../GeneratorInterface/RivetInterface/data/ATLAS_2015_I1408516_MU.plot --config=data/CMS_Z_Pt.plot"
	for proc in Zj; do
	    #rivet-mkhtml ${commonOpts} -o ~/public/html/${proc}/hadr ${proc}/dy2mumu_ct10.yoda:'PY8(CUETP8M1)'\
#		${proc}/dy2mumu_ct10_primkt.yoda:'PY8($k_{T}^{0}=0$,CUETP8M1)' \
#		${proc}/dy2mumu_ct10_hwpp.yoda:'HW++(EE5C)';
	    rivet-mkhtml ${commonOpts} -o ~/public/html/${proc}/minlo ${proc}/dy2mumu_ct10.yoda:'Zj(CT10)' ${proc}/py8_w0.yoda:'Zj Minlo (NNPDF3.0)';		
	    continue
	    rivet-mkhtml ${commonOpts} -o ~/public/html/${proc}/scales ${proc}/py8_w0.yoda:'($\mu_R,\mu_F$)=(1,1)' \
		${proc}/py8_w3.yoda:'(2,1)' \
		${proc}/py8_w6.yoda:'(1/2,1)' \
		${proc}/py8_w1.yoda:'(1,2)' \
		${proc}/py8_w2.yoda:'(1,1/2)' \
		${proc}/py8_w4.yoda:'(1/2,1/2)' \
		${proc}/py8_w8.yoda:'(2,2)';
	    rivet-mkhtml ${commonOpts} -o ~/public/html/${proc}/hadr ${proc}/py8_w0.yoda:'PY8(CUETP8M1)' \
		${proc}/py8_noprimkt.yoda:'PY8($k_{T}^{0}=0$,CUETP8M1)' \
		${proc}/hwpp.yoda:'HW++(EE5C)';
	    rivet-mkhtml ${commonOpts} -o ~/public/html/${proc}/pdfs ${proc}/py8_w0.yoda:'NNPDF30_nlo_as_0118' \
		${proc}/py8_w111.yoda:'CT14nlo' ;
	done
	
	;;
esac