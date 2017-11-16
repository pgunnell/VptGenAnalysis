#/usr/bin/env python

import ROOT
from xsec import xsecList

VARTITLES={
    'v0':'p_{T} [GeV]',
    'v1':'#eta',
    'v2':'p_{T} [GeV]',
    'v3':'#eta',
    'v4':'M(V) [GeV]',
    'v5':'p_{T}(V) [GeV]',
    'v6':'y(V)',
    'v7':'MET [GeV]',
    'v8':'M_{T} [GeV]',
    'v9':'Recoil p_{T} [GeV]'
    }


def getHistos(url,name,xsec,color,title):
    """Read histos from file"""
    histos={}
    fIn=ROOT.TFile.Open(url)
    weights=fIn.Get('weights')
    for obj in fIn.GetListOfKeys():
        obj=obj.ReadObj()
        keyName=obj.GetName()
        if not obj.InheritsFrom('TH1') : continue

        v,w=keyName,-1
        try:
            v,w=keyName.split('_')
        except:
            pass
        w=int(w)

        if not v in histos: histos[v]={}
        histos[v][w]=obj.Clone('%s_%s'%(name,keyName))
        histos[v][w].SetDirectory(0)
        histos[v][w].SetLineColor(color)
        histos[v][w].SetLineWidth(2)
        histos[v][w].SetTitle(title)
        histos[v][w].GetXaxis().SetTitleSize(0.04)
        histos[v][w].GetYaxis().SetTitleSize(0.04)
        histos[v][w].GetXaxis().SetLabelSize(0.035)
        histos[v][w].GetYaxis().SetLabelSize(0.035)
        histos[v][w].GetYaxis().SetTitleOffset(1.2)


        #scale to xsec
        if w>=0:
            wVal=weights.GetBinContent(w+1)
            if wVal>0: histos[v][w].Scale(xsec/wVal)
            histos[v][w].GetYaxis().SetTitle('d#sigma/dX [pb/bin]')
            histos[v][w].GetXaxis().SetTitle(VARTITLES[v])

        #divide by bin width
        for xbin in xrange(1,histos[v][w].GetNbinsX()+1):
            wid=histos[v][w].GetBinWidth(xbin)
            val=histos[v][w].GetBinContent(xbin)
            unc=histos[v][w].GetBinError(xbin)
            histos[v][w].SetBinContent(xbin,val/wid)
            histos[v][w].SetBinError(xbin,unc/wid)

    fIn.Close()
    return histos

def drawHistos(histos,ran,name):
    """draw a set of histograms"""

    c=ROOT.TCanvas('c','c',500,500)
    c.SetRightMargin(0.02)
    c.SetTopMargin(0.05)
    c.SetLeftMargin(0.12)
    c.SetBottomMargin(0.12)
    c.Clear()

    drawOpt='hist'
    ymin,ymax=9999,0
    for i in xrange(len(histos)):
        ymax=max(ymax,histos[i].GetMaximum())
        ymin=min(ymax,histos[i].GetMinimum())
        histos[i].Draw(drawOpt)
        drawOpt='histsame'
    histos[0].GetYaxis().SetRangeUser(ymin*0.8,ymax*1.2)
    if ran: histos[0].GetXaxis().SetRangeUser(ran[0],ran[1])

    leg=c.BuildLegend(0.7,0.93,0.95,0.77)
    leg.SetBorderSize(0)
    leg.SetFillStyle(0)
    leg.SetTextFont(42)
    leg.SetTextSize(0.04)
    
    tex=ROOT.TLatex()
    tex.SetTextFont(42)
    tex.SetTextSize(0.04)
    tex.SetNDC()
    tex.DrawLatex(0.12,0.96,'#bf{CMS} #it{simulation preliminary} (#sqrt{s}=8 TeV)')
    c.Modified()
    c.Update()
    for ext in ['png','pdf']:
        c.SaveAs('plots/%s.%s'%(name,ext))
    raw_input()
    
histos={}
for proc,color in [('ZJ_central',     ROOT.TColor.GetColor('#5e3c99')),
                   ('PY8_TuneAZ',     ROOT.kGray),
                   ('WplusJ_central', ROOT.TColor.GetColor('#e66101')),
                   ('WminusJ_central', ROOT.TColor.GetColor('#fdb863'))]:
    if proc=='PY8_TuneAZ':        
        title,xsec,_=xsecList['ZJ_central']
        title += ' #scale[0.5]{(PY8AZ)}'
    else:
        title,xsec,_=xsecList[proc]
        
    histos[proc]=(title,getHistos('plots/%s_merged.root'%proc,
                                  proc,
                                  xsec=xsec,
                                  color=color,
                                  title=title))


ROOT.gStyle.SetOptStat(0)
ROOT.gStyle.SetOptTitle(0)
    
for v in histos['ZJ_central'][1]:
    if v=='weights' : continue

    mainHistos=[]
    for proc in ['WplusJ_central','WminusJ_central','PY8_TuneAZ','ZJ_central']:
        mainHistos.append(histos[proc][1][v][0])
    ratioHistos=[x.Clone('ratio_%s'%x.GetName()) for x in mainHistos]
    ratioHistos=ratioHistos[0:-1]
    for x in ratioHistos: 
        x.Divide(mainHistos[-1])
        x.GetYaxis().SetTitle('Ratio to %s'%xsecList[proc][0])

    ran=None
    if v=='v0': ran=(20.1,60)
    if v=='v2': ran=(20.1,45)
    if v=='v4': ran=(60,100)
    if v=='v5': ran=(0.1,50)
    if v=='v7': ran=(0.1,80)
    if v=='v8': ran=(0.1,90)
    if v=='v9': ran=(0.1,50)

    drawHistos(histos=mainHistos,ran=ran,name=v)
    drawHistos(histos=ratioHistos,ran=ran,name=v+'_ratio')

