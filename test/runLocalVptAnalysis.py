#! /usr/bin/env python
import ROOT
import optparse
import json
import sys
import os

from UserCode.VptGenAnalysis.vecbosKinUtils import *


"""
Analysis implementation
"""
def runAnalysis(fileName,outFileName):

    print '....analysing',fileName,'with output @',outFileName

    #book histograms
    observablesH={}
    observablesH['mll']=ROOT.TH1F('mll',';Dilepton invariant mass [GeV];Events',50,66,116)
    for var in observablesH:
        observablesH[var].SetDirectory(0)
        observablesH[var].Sumw2()


    #loop over events in tree
    tree=ROOT.TChain('analysis/data')
    tree.AddFile(fileName)
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



        #dilepton analysis
        if len(selLep)==2:

            #id/charge consistency
            if abs(tree.pid[ selLep[0] ]) != abs(tree.pid[ selLep[1] ]) : continue
            if tree.charge[ selLep[0] ] * tree.charge[ selLep[1] ] >= 0 : continue

            #lepton kinematics
            l1,l2=ROOT.TLorentzVector(),ROOT.TLorentzVector()
            l1.SetPtEtaPhiM( tree.dressed_pt[ selLep[0] ], tree.dressed_eta[ selLep[0] ], tree.dressed_phi[ selLep[0] ], tree.dressed_m[ selLep[0] ] )
            l2.SetPtEtaPhiM( tree.dressed_pt[ selLep[1] ], tree.dressed_eta[ selLep[1] ], tree.dressed_phi[ selLep[1] ], tree.dressed_m[ selLep[1] ] )
            
            mll=(l1+l2).M()
            if mll<66 or mll>116 : continue
                
            observablesH['mll'].Fill(mll,tree.w[0])


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
