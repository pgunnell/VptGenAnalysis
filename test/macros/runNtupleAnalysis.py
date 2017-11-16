import ROOT
import os
import sys
import optparse
import numpy as np
import array

from UserCode.VptGenAnalysis.vecbosKinUtils import *

def parseDataFromTree(opt,histos=None,maxPerc=25):
    """loops over the tree to retrive kinematics or fill histograms"""
    
    #analyse events in trees
    url=opt.input
    if opt.input.find('/store')==0 : url='root://eoscms//eos/cms/%s'%opt.input
    fIn=ROOT.TFile.Open(url)
    data=fIn.Get('analysis/data')
    nevts=data.GetEntries()
    print '[parseDataFromTree] with %d'%nevts
    cut=None
    if opt.cuts:
        cut=ROOT.TTreeFormula('cuts',opt.cuts,data)
        print '\t pre-selection to be applied is %s'%opt.cuts

    isW = True if 'WplusJ' in url or 'WminusJ' in url else False

    #replicate histos (1 per weight)
    if histos:
        data.GetEntry(0)
        print 'Replicating histograms for',data.nw,'weights'
        keys=histos.keys()
        for k in keys:
            for iw in xrange(0,data.nw):
                iv=int(filter(str.isdigit, k))
                histos[(iv,iw)]=histos[k].Clone('%s_%d'%(k,iw))
                histos[(iv,iw)].SetDirectory(0)

        histos['weights']=fIn.Get('analysis/weights').Clone()
        histos['weights'].SetDirectory(0)
                
    #for each event compute variables and store required weights
    nevtsSel=0
    evVals,wgtVals,iniWgtVals=[],[],[]
    lp4=[ROOT.TLorentzVector(0,0,0,0),ROOT.TLorentzVector(0,0,0,0)]
    for i in xrange(0,nevts):
        data.GetEntry(i)

        #print status of the analysis
        perc=float(100.*i)/float(nevts)
        if perc>maxPerc : break
        if i%1000==0 : 
            sys.stdout.write('\r [ %d/%d ] done' %(int(perc),int(maxPerc)))
            sys.stdout.flush()

        #presel events (it may issue a warning which can be safely disregarded)
        #cf https://root.cern.ch/phpBB3/viewtopic.php?t=14213
        if cut and not cut.EvalInstance() : continue

        #fill the lepton kinematics depending on whether it's a W or a Z like candidate
        if not isW and data.nl<2: continue
        if data.nl>1:
            for il in xrange(0,2):
                lp4[il].SetPtEtaPhiM(data.pt[il],data.eta[il],data.phi[il],data.m[il])
            if lp4[0].Pt()<20 or lp4[1].Pt()<20 or ROOT.TMath.Abs(lp4[0].Eta())>2.5 or ROOT.TMath.Abs(lp4[1].Eta())>2.5 : continue
        else:
            lp4[0].SetPtEtaPhiM(data.pt[0],data.eta[0],data.phi[0],data.m[0])
            lp4[1].SetPtEtaPhiM(data.nusum_pt,data.nusum_eta,data.nusum_phi,0.)
            if lp4[0].Pt()<20 or ROOT.TMath.Abs(lp4[0].Eta())>2.5 : continue

        nevtsSel+=1

        #lepton kinematics
        varVals=[lp4[0].Pt(), lp4[0].Eta(), lp4[1].Pt(), lp4[1].Eta()]

        #vector boson kinematics
        vpt = lp4[0]+lp4[1]
        varVals += [vpt.M(), vpt.Pt(), vpt.Rapidity()]
        
        #MET and transverse mass
        met=ROOT.TLorentzVector(0,0,0,0)
        met.SetPtEtaPhiM(data.genmet_pt,data.genmet_eta,data.genmet_phi,0.)
        varVals += [ met.Pt(), calcMt(p1=lp4[0],p2=met) ]

        #recoil
        recoil=met+lp4[0]
        if not isW: recoil+=lp4[1]
        varVals += [recoil.Pt()]

        #weights
        mewgts=[data.w[iw] for iw in xrange(0,data.nw)]

        #fill histograms or return selected values
        if histos:
            for iv in xrange(0,len(varVals)):
                for iw in xrange(0,len(mewgts)):
                    val=varVals[iv]
                    wgt=mewgts[iw]
                    histos[(iv,iw)].Fill(val,wgt)
        else:
            evVals.append( varVals )
            wgtVals.append( mewgts )

    print '[parseDataFromTree] %d events pre-selected'%nevtsSel

    #all done here
    fIn.Close()
    return (evVals,wgtVals)


def createTemplates(opt):
    """analyse a small set of events and create templates (equal statistics)"""

    data=parseDataFromTree(opt,maxPerc=20,histos=None)    
    print '[fillHistos] defining templates for %d variables and %d selected events'%(len(data[0][0]),len(data[0]))

    #compute quantiles for n bins
    q     = [(100.*i)/opt.nbins for i in xrange(0,opt.nbins+1)]
    qVals = np.percentile(np.array(data[0]),q, axis=0).T if data else None

    #write template histos to file
    fOut=ROOT.TFile.Open(opt.output,'RECREATE')
    for iv in xrange(0,len(data[0][0])):

        #bin definition for this variable
        binDef=[val for val in np.unique(qVals[iv]) if not np.isnan(val) ]
        
        #write histo to file
        histo=ROOT.TH1F('v%d'%iv,';;Events / bin',len(binDef)-1,array.array('d',binDef))
        histo.Sumw2()
        histo.SetDirectory(fOut)
        histo.Write()
    fOut.Close()


def fillHistos(opt) :
    """Fills histograms based on pre-defined templates"""
    
    #open file with template histograms
    histos={}
    fTempl=ROOT.TFile.Open(opt.templ)
    print '[fillHistos] using templates from %s'%fTempl.GetName()
    for obj in fTempl.GetListOfKeys():
        obj=obj.ReadObj()
        keyName=obj.GetName()
        if not obj.InheritsFrom('TH1') : continue

        histos[keyName]=obj.Clone()
        histos[keyName].SetDirectory(0)

    #fill histos 
    parseDataFromTree(opt,maxPerc=101,histos=histos)

    #write histos to file
    fOut=ROOT.TFile.Open(opt.output,'RECREATE')
    for key in histos:         
        if histos[key].GetEntries()==0 : continue
        histos[key].SetDirectory(fOut)
        histos[key].Write()
    fOut.Close()

    #all done here
    print '[fillHistos] %d results can be found in %s'%(len(histos),opt.output)



"""
"""
def main():

    #configuration
    usage = 'usage: %prog [options]'
    parser = optparse.OptionParser(usage)
    parser.add_option('-i', '--in',     dest='input',   help='input file [%default]',       default='/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central/ZJ_central.root', type='string')
    parser.add_option(      '--nbins',  dest='nbins',   help='n bins [%default]',           default=100,                                                       type=int)
    parser.add_option('-o', '--out',    dest='output',  help='output file [%default]',      default='ZJ_central.root',                                        type='string')
    parser.add_option('-c', '--cuts',   dest='cuts',    help='simple cuts to apply to the tree [%default]', default=None,                                  type='string')
    parser.add_option(      '--templ',  dest='templ',   help='histogram templates (keep binning) [%default]', default=None,                                   type='string')
    (opt, args) = parser.parse_args()

    if opt.templ:
        fillHistos(opt)
    else:
        createTemplates(opt)

"""
for execution from another script
"""
if __name__ == "__main__":
    sys.exit(main())
