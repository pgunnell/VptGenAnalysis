#!/usr/bin/env python

import ROOT
import math


def getPlotFrom(url,name,tag):
    fIn=ROOT.TFile.Open(url)
    h=fIn.Get(name).Clone(tag)
    h.SetDirectory(0)
    fIn.Close()
    return h

plotList=[ ('h_d15_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, |y_{ll}|<2.4'),
           ('h_d05_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, |y_{ll}|<0.4'),
           ('h_d06_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, 0.4<|y_{ll}|<0.8'),
           ('h_d07_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, 0.8<|y_{ll}|<1.2'),
           ('h_d08_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, 1.2<|y_{ll}|<1.6'),
           ('h_d09_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, 1.6<|y_{ll}|<2.0'),
           ('h_d10_x01_y04','1/#sigma d#sigma/d#phi*_{#eta} 66#leqm_{ll}/GeV#leq116, 2.0<|y_{ll}|<2.4'),
           ('h_d27_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, |y_{ll}|<2.4'),
           ('h_d17_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, |y_{ll}|<0.4'),
           ('h_d18_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, 0.4<|y_{ll}|<0.8'),
           ('h_d19_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, 0.8<|y_{ll}|<1.2'),
           ('h_d20_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, 1.2<|y_{ll}|<1.6'),
           ('h_d21_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, 1.6<|y_{ll}|<2.0'),
           ('h_d22_x01_y04','1/#sigma d#sigma/dp_{T}^{ll} 66#leqm_{ll}/GeV#leq116, 2.0<|y_{ll}|<2.4'),
           ]

wgtList=[]
with open('/afs/cern.ch/user/p/psilva/public/forLuca/ZJ_weightList.txt','r')  as f:
    line_words = [line.split() for line in f]
    line_words = filter(lambda x : len(x)>0 and x[0].isdigit(), line_words)
    for i in xrange(0,121):
        x=line_words[i]
        wgtList.append( (int(x[0]),
                         float(x[3].split('=')[1]),
                         float(x[4].split('=')[1])) )


ROOT.gStyle.SetOptStat(0)
ROOT.gStyle.SetOptTitle(0)
ROOT.gROOT.SetBatch(True)
c=ROOT.TCanvas('c','c',500,500)
c.SetTopMargin(0.01)
c.SetLeftMargin(0.12)
c.SetRightMargin(0.12)
c.SetBottomMargin(0.1)
c.SetLogz()
c.SetLogx()
c.SetLogy()

optimResults={}

for name,title in plotList:

    dataH=getPlotFrom('plots/ATLAS_2015_I1408516_MU.root',name,'data')
    chi2scan=ROOT.TGraph2D()
    muRmin,muFmin,chi2min=1,1,9999999
    wgtIdxmin=1
    for wgtIdx,muR,muF in wgtList:
        
        h=getPlotFrom('plots/w%d_ZJ_central.root'%wgtIdx,name,'mc')

        chi2,ndof=0.,0
        for xbin in xrange(1,h.GetNbinsX()+1):
            xcen=h.GetXaxis().GetBinCenter(xbin)
            if 'p_{T}^{ll}' in title and xcen>30 : continue
            err2=dataH.GetBinError(xbin)**2+h.GetBinError(xbin)**2
            diff2=(h.GetBinContent(xbin)-dataH.GetBinContent(xbin))**2
            if err2==0 : continue
            chi2 += diff2/err2
            ndof += 1
        h.Delete()
        if chi2>1000: continue
        if chi2<chi2min:  muRmin,muFmin,chi2min,wgtIdxmin=muR,muF,chi2,wgtIdx
        chi2scan.SetPoint(chi2scan.GetN(),muR,muF,chi2)
        
    if chi2scan.GetN()<2 : continue
    c.Clear()
    chi2scan.Draw('colz')
    chi2scanH=chi2scan.GetHistogram()
    chi2scanH.GetZaxis().SetTitleOffset(0.8)
    chi2scanH.GetZaxis().SetTitle('#chi^{2}')
    chi2scanH.GetXaxis().SetTitle('#mu_{R}')
    chi2scanH.GetYaxis().SetTitle('#mu_{F}')
    chi2scanH.GetXaxis().SetMoreLogLabels()
    chi2scanH.GetYaxis().SetMoreLogLabels()
    chi2scanH.GetZaxis().SetRangeUser(0.1,1e3)

    txt=ROOT.TLatex()
    txt.SetNDC(True)
    txt.SetTextFont(42)
    txt.SetTextSize(0.03)
    txt.SetTextAlign(12)
    txt.DrawLatex(0.15,0.95,'#bf{CMS} #it{simulation}, #bf{ATLAS} #it{data} (#sqrt{s}=8 TeV)')
    txt.DrawLatex(0.15,0.9,title)
    
    gr=ROOT.TGraph()
    gr.SetMarkerStyle(20)
    gr.SetPoint(0,muRmin,muFmin)
    gr.Draw('p')

    key=(muRmin,muFmin)
    if not key in optimResults: optimResults[key]=0
    optimResults[key]+=1

    c.Modified()
    c.Update()
    for ext in ['png','pdf']:
        c.SaveAs('plots/%s.%s'%(name,ext))

c.Clear()
c.SetLogy(False)
c.SetLogx(False)
hsummary=ROOT.TH1F('summary',';(#mu_{R},#mu_{F});# distributions',len(optimResults),0,len(optimResults))
xbin=1
for key in optimResults:
    hsummary.SetBinContent(xbin,optimResults[key])
    hsummary.GetXaxis().SetBinLabel(xbin,'(%3.1f,%3.1f)'%key)
    xbin+=1
hsummary.SetLineWidth(2)
hsummary.GetYaxis().SetRangeUser(0,len(optimResults)*0.9)
hsummary.Draw('hist')
txt=ROOT.TLatex()
txt.SetNDC(True)
txt.SetTextFont(42)
txt.SetTextSize(0.03)
txt.SetTextAlign(12)
txt.DrawLatex(0.15,0.95,'#bf{CMS} #it{simulation}, #bf{ATLAS} #it{data} (#sqrt{s}=8 TeV)')
c.Modified()
c.Update()
for ext in ['png','pdf']:
    c.SaveAs('plots/optimsummary.%s'%(ext))
