#! /usr/bin/env python
import ROOT
import optparse
import json
import sys
import os
from array import array

from UserCode.VptGenAnalysis.vecbosKinUtils import *


"""
Analysis implementation
"""
def runAnalysis(fileName,outFileName):

    print '....analysing',fileName,'with output @',outFileName

    #book histograms
    observablesH={}
    observablesH['mll']=ROOT.TH1F('mll',';Dilepton invariant mass [GeV];Events',50,66,116)
    observablesH['y']=ROOT.TH2F('y',';Dilepton rapidity;Incoming partons;Events',50,-3,3,121,0,121)
    observablesH['ypos']=ROOT.TH2F('ypos',';Positive lepton rapidity;Incoming partons;Events',50,-3,3,121,0,121)
    observablesH['yneg']=ROOT.TH2F('yneg',';Negative lepton rapidity;Incoming partons;Events',50,-3,3,121,0,121)

    phistarBins=[2.000000e-03,6.000000e-03,1.000000e-02,1.400000e-02,1.800000e-02,2.200000e-02,2.650000e-02,3.150000e-02,3.650000e-02,4.200000e-02,4.800000e-02,5.400000e-02,6.050000e-02,6.800000e-02,7.650000e-02,8.600000e-02,9.650000e-02,1.080000e-01,1.210000e-01,1.365000e-01,1.550000e-01,1.770000e-01,2.040000e-01,2.385000e-01,2.850000e-01,3.515000e-01,4.575000e-01,6.095000e-01,8.065000e-01,1.035500e+00,1.324500e+00,1.721500e+00,2.234500e+00,2.899500e+00,4.138500e+00,7.500000e+00]
    observablesH['phistar']=ROOT.TH2F('phistar',';#phi^{*};Weight number;Events',len(phistarBins)-1,array('d',phistarBins),200,0,200)

    ptllBins=[1.000000e+00,3.000000e+00,5.000000e+00,7.000000e+00,9.000000e+00,1.100000e+01,1.300000e+01,1.500000e+01,1.700000e+01,1.900000e+01,2.125000e+01,2.375000e+01,2.625000e+01,2.875000e+01,3.150000e+01,3.450000e+01,3.750000e+01,4.050000e+01,4.350000e+01,4.650000e+01,4.950000e+01,5.250000e+01,5.550000e+01,5.900000e+01,6.300000e+01,6.750000e+01,7.250000e+01,7.750000e+01,8.250000e+01,9.000000e+01,1.000000e+02,1.150000e+02,1.375000e+02,1.625000e+02,1.875000e+02,2.250000e+02,2.750000e+02,3.250000e+02,3.750000e+02,4.350000e+02,5.100000e+02,6.000000e+02,7.750000e+02]
    observablesH['ptll']=ROOT.TH2F('ptll',';Dilepton transverse momentum [GeV];Weight number;Events',len(ptllBins)-1,array('d',ptllBins),200,0,200)

    observablesH['phistarvsptll']=ROOT.TH2F('phistarvsptll',';Dilepton transverse momentum [GeV];;#phi^{*};Events',len(ptllBins)-1,array('d',ptllBins),len(phistarBins)-1,array('d',phistarBins))

    for var in observablesH:
        observablesH[var].SetDirectory(0)
        observablesH[var].Sumw2()


    #loop over events in tree
    fIn=ROOT.TFile.Open(fileName)
    tree=fIn.Get('analysis/data')
    observablesH['weights']=fIn.Get('analysis/weights')
    observablesH['weights'].Clone()
    totalEntries=tree.GetEntries()
    for i in xrange(0,totalEntries):

        tree.GetEntry(i)
        if i%100==0 : sys.stdout.write('\r [ %d/100 ] done' %(int(float(100.*i)/float(totalEntries))) )

        #select leptons
        selLep=[]
        for il in xrange(0,tree.nl):
            if tree.dressed_pt[il]<20 or abs(tree.dressed_eta[il])>2.5 : continue
            selLep.append( il )            
        if len(selLep)==0: continue

        incPartonsBin=(tree.id1+5)*11+(tree.id2+5)
        
        #dilepton analysis
        if len(selLep)==2:

            #id/charge consistency
            if abs(tree.pid[ selLep[0] ]) != abs(tree.pid[ selLep[1] ]) : continue
            if tree.charge[ selLep[0] ] * tree.charge[ selLep[1] ] >= 0 : continue

            #lepton kinematics
            l1,l2=ROOT.TLorentzVector(),ROOT.TLorentzVector()
            l1.SetPtEtaPhiM( tree.dressed_pt[ selLep[0] ], tree.dressed_eta[ selLep[0] ], tree.dressed_phi[ selLep[0] ], tree.dressed_m[ selLep[0] ] )
            l2.SetPtEtaPhiM( tree.dressed_pt[ selLep[1] ], tree.dressed_eta[ selLep[1] ], tree.dressed_phi[ selLep[1] ], tree.dressed_m[ selLep[1] ] )
            
            #dilepton invariant mass
            ll=l1+l2
            mll=ll.M()
            if mll<66 or mll>116 : continue
                
            observablesH['mll'].Fill(mll,tree.w[0])
            observablesH['y'].Fill(ll.Rapidity(),incPartonsBin,tree.w[0])
            if  tree.charge[ selLep[0] ] >0 :
                observablesH['ypos'].Fill(l1.Rapidity(),incPartonsBin,tree.w[0])
                observablesH['yneg'].Fill(l2.Rapidity(),incPartonsBin,tree.w[0])
            else:
                observablesH['ypos'].Fill(l2.Rapidity(),incPartonsBin,tree.w[0])
                observablesH['yneg'].Fill(l1.Rapidity(),incPartonsBin,tree.w[0])

            phistar=calcPhiStar(l1,l2)
            observablesH['phistarvsptll'].Fill(ll.Pt(),phistar,tree.w[0])
            for iw in xrange(0,tree.nw):
                observablesH['phistar'].Fill(phistar,iw,tree.w[iw])
                observablesH['ptll'].Fill(ll.Pt(),iw,tree.w[iw])                

    #save results
    fOut=ROOT.TFile.Open(outFileName,'RECREATE')
    for var in observablesH: observablesH[var].Write()
    fOut.Close()


"""
Wrapper for when the analysis is run in parallel
"""
def runAnalysisPacked(args):
    try:
        fileNames,outFileName=args
        runAnalysis(fileNames,outFileName)
    except : # ReferenceError:
        print 50*'<'
        print "  Problem with", name, "continuing without"
        print 50*'<'
        return False

"""
Create analysis tasks
"""
def createAnalysisTasks(opt):

    onlyList=opt.only.split('v')

    ## Local directory
    file_list=[]
    if os.path.isdir(opt.input):
        for file_path in os.listdir(opt.input):
            if file_path.endswith('.root'):
                file_list.append(os.path.join(opt.input,file_path))
    elif '.root' in opt.input:
        file_list.append(opt.input)

    #list of files to analyse
    tasklist=[]
    for filename in file_list:
        baseFileName=os.path.basename(filename)
        tag,ext=os.path.splitext(baseFileName)
        if len(onlyList)>0:
            processThis=False
            for filtTag in onlyList:
                if filtTag in tag:
                    processThis=True
            if not processThis : continue
        tasklist.append((filename,'%s/%s'%(opt.output,baseFileName)))

    #loop over tasks
    if opt.queue=='local':
        if opt.jobs>1:
            print ' Submitting jobs in %d threads' % opt.jobs
            import multiprocessing as MP
            pool = MP.Pool(opt.jobs)
            pool.map(runAnalysisPacked,tasklist)
        else:
            for fileName,outFileName in tasklist:
                runAnalysis(fileName,outFileName)
    else:
        cmsswBase=os.environ['CMSSW_BASE']
        for fileName,_ in tasklist:
            localRun='python %s/src/UserCode/VptGenAnalysis/test/runLocalVptAnalysis.py -i %s -o %s -q local'%(cmsswBase,fileName,opt.output)
            cmd='bsub -q %s %s/src/UserCode/VptGenAnalysis/scripts/wrapLocalAnalysisRun.sh \"%s\"' % (opt.queue,cmsswBase,localRun)
            print cmd
            os.system(cmd)

"""
steer
"""
def main():
	usage = 'usage: %prog [options]'
	parser = optparse.OptionParser(usage)
	parser.add_option('-i', '--input',
                          dest='input',
                          default='/afs/cern.ch/user/p/psilva/work/TopWidth',
                          help='input directory with the files [default: %default]')
	parser.add_option('--jobs',
                          dest='jobs',
                          default=1,
                          type=int,
                          help='# of jobs to process in parallel the trees [default: %default]')
	parser.add_option('--only',
                          dest='only',
                          default='',
                          type='string',
                          help='csv list of tags to process')
	parser.add_option('-o', '--output',
                          dest='output',
                          default='analysis',
                          help='Output directory [default: %default]')
	parser.add_option('-q', '--queue',
                          dest='queue',
                          default='local',
                          help='Batch queue to use [default: %default]')
	(opt, args) = parser.parse_args()

        #prepare output
	os.system('mkdir -p %s' % opt.output)

        #create analysis tasks to run locally or to submit
        createAnalysisTasks(opt)


if __name__ == "__main__":
	sys.exit(main())
