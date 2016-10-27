import ROOT

"""
"""
def getPartonName(pid):
    name=''
    if abs(pid)==5 : name='b'
    if abs(pid)==4 : name='c'
    if abs(pid)==3 : name='s'
    if abs(pid)==2 : name='d'
    if abs(pid)==1 : name='u'
    if pid==0      : name='g'
    if pid<0       : name='#bar{%s}'%name
    return name


c=ROOT.TCanvas('c','c',500,500)

fIn=ROOT.TFile('analysis//dy2mumu_ct10_5.root')

for dist in ['y','ypos','yneg']:

    #normalized distribution
    h2d=fIn.Get(dist)
    totalH=h2d.ProjectionX('inclusive')
    total=totalH.Integral()
    totalH.Scale(1./total)

    allH=[]
    for ybin in xrange(1,h2d.GetNbinsY()+1):

        tmp=h2d.ProjectionX('%s_%d'%(dist,ybin),ybin,ybin)
        if tmp.Integral()==0 : continue
        tmp.Scale(1./total)

        #title for this bin
        id2=(ybin-1)%11-5
        id1=int((ybin-1)/11)-5
        title='%s%s'%(getPartonName(id1),getPartonName(id2)) 
        if id1<id2 and id1!=0 and id2!=0 :
            title='%s%s'%(getPartonName(id2),getPartonName(id1)) 

        #check if already existing
        found=False
        for key,h in allH :
            if key!=title : continue
            h.Add(tmp)
            found=True
            break
        if found : continue

        #add new one
        allH.append( (title,tmp.Clone(title)) )

    allH=sorted(allH,  key=lambda histo: histo[1].Integral(), reverse=True)
    otherH=allH[0][1].Clone('others')
    otherH.Reset('ICE')
    for i in xrange(5,len(allH)): otherH.Add( allH[i][1] )

    c.Clear()
    totalH.Draw('hist')
    for i in xrange(0,5): allH[i][1].Draw('histsame')
    if otherH.Integral()!=0 : otherH.Draw('histsame')
    c.BuildLegend()
    c.Modified()
    c.Update()
    raw_input()
