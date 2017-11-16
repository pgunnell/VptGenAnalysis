#!/usr/bin/env python

import ROOT
import numpy as np

xsecList={'ZJ_central'     : ('Z#rightarrow#mu#mu',                    1.104, 2.538*1e-3),
          'WminusJ_central': ('W^{-}#rightarrow#mu^{-}#bar{#nu}_{#mu}',4.565, 31.77e-3),
          'WplusJ_central' : ('W^{+}#rightarrow#mu^{+}#nu_{#mu}',      6.449, 42.88e-3)
          }

"""
"""
def main():

    ROOT.gStyle.SetOptStat(0)
    ROOT.gStyle.SetOptTitle(0)
    ROOT.gROOT.SetBatch(True)
    ROOT.gStyle.SetPalette(ROOT.kTemperatureMap)
    ROOT.gStyle.SetPaintTextFormat("3.3f");
    c=ROOT.TCanvas('c','c',800,500)
    c.SetRightMargin(0.15)
    c.SetTopMargin(0.05)
    c.SetLeftMargin(0.12)
    c.SetBottomMargin(0.12)
      
    for proc in xsecList:
        title,xsec,xsecUnc=xsecList[proc]

        weights=None
        for i in xrange(0,4):
            try:
                fIn=ROOT.TFile.Open('/eos/cms/store/cmst3/user/psilva/Wmass/ntuples/ZJ_central/%s_%d.root'%(proc,i))
                w=fIn.Get('analysis/weights')
                if weights: 
                    weights.Add(w)
                else :
                    weights=w.Clone('w')
                    weights.SetDirectory(0)
                fIn.Close()
            except:
                pass

        wgtList=[]
        with open('plots/%s_weights.txt'%proc,'r')  as f:
            line_words = [line.split() for line in f]
            line_words = filter(lambda x : len(x)>0 and x[0].isdigit(), line_words)
            for i in xrange(0,len(line_words)): 
                x=line_words[i]
                if not 'muR=' in x[3] or not 'muF=' in x[4]: continue
                wgtList.append( (int(x[0]),
                                 float(x[3].split('=')[1]),
                                 float(x[4].split('=')[1])) )

        print 'Identified',len(wgtList),'QCD scale weights'
        muRbins=np.sort(list(set( [x for _,x,_ in wgtList] )))
        muFbins=np.sort(list(set( [x for _,_,x in wgtList] )))

        nx,ny=len(muRbins),len(muFbins)
        gr=ROOT.TH2F('xsec',';#mu_{R};#mu_{F};#sigma [nb]',nx,0,nx,ny,0,ny)
        for xbin in xrange(0,nx): gr.GetXaxis().SetBinLabel(xbin+1,'%3.3f'%muRbins[xbin])
        for ybin in xrange(0,ny): gr.GetYaxis().SetBinLabel(ybin+1,'%3.3f'%muFbins[ybin])

        w0=weights.GetBinContent(1)
        for wgtIdx,muR,muF in wgtList:
            w=weights.GetBinContent(wgtIdx+2)
            sf=w/w0
            x = np.where( muRbins==muR )[0][0]
            y = np.where( muFbins==muF )[0][0]
            gr.SetBinContent(x+1,y+1,sf*xsec)
            gr.SetBinError(x+1,y+1,sf*xsecUnc)

        c.cd()
        c.Clear()
        gr.Draw('colztext')
        gr.GetZaxis().SetRangeUser(xsec*0.25,xsec*2.)
        gr.GetYaxis().SetTitleSize(0.05)
        gr.GetXaxis().SetTitleSize(0.05)
        gr.GetZaxis().SetTitleSize(0.05)
        gr.GetYaxis().SetLabelSize(0.04)
        gr.GetXaxis().SetLabelSize(0.04)
        gr.GetZaxis().SetLabelSize(0.04)
        gr.GetYaxis().SetTitleOffset(1.0)

        tex=ROOT.TLatex()
        tex.SetTextFont(42)
        tex.SetTextSize(0.05)
        tex.SetNDC()
        tex.DrawLatex(0.12,0.96,'#bf{CMS} #it{simulation preliminary} #scale[0.7]{%s #it{Powheg+Minlo+Pythia8 (WM2) #sqrt{s}=8 TeV}}'%title)
        for ext in ['png','pdf']:
            c.SaveAs('plots/%s_pwminlo_xsec.%s'%(proc,ext))


if __name__ == "__main__":
    sys.exit(main())
