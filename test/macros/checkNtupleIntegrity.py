import ROOT
import os,sys

baseDir,tag=sys.argv[1],sys.argv[2]
fList = [f for f in os.listdir(baseDir) if (os.path.isfile(os.path.join(baseDir, f)) and '.root' in f and tag in f)]
for f in fList:
    try:
        url=os.path.join(baseDir,f)
        fIn=ROOT.TFile.Open(url)
        weights=fIn.Get('analysis/weights')
        neg=0
        for xbin in xrange(1,weights.GetNbinsX()+1):
            w=weights.GetBinContent(xbin)
            if w>=0 : continue
            neg+=1
        fIn.Close()
        if neg==0 :
            print f,'is OK'
            continue
        raise ValueError
    except:
        fname=os.path.splitext(f)[0]
        print 'Will remove all matching *%s.*'%fname
        os.system('rm -v %s/*%s.*'%(baseDir,fname))
