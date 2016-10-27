#! /usr/bin/env python
import ROOT

"""
phi* definition : EPJC 71:1600,2011
"""
def calcPhiStar(p1,p2):
    
    #get phi and eta
    phi1,phi2,eta1,eta2=None,None,None,None
    try:
        phi1,eta1=p1.Phi(),p1.Eta()
        phi2,eta2=p2.Phi(),p2.Eta()
    except:
        try :
            phi1,eta1=p1
            phi2,eta2=p2
        except:
            raise InputError('Unable to retrieve eta/phi')

    #compute the variable
    phi_acop      = ROOT.TMath.Pi()-ROOT.TVector2.Phi_mpi_pi(phi1-phi2)
    costhetastar  = ROOT.TMath.TanH(0.5*(eta1-eta2))
    sin2thetastar = 0.0 if costhetastar > 1 else (1.0 - ROOT.TMath.Sqrt(costhetastar))
    phistar       = ROOT.TMath.Tan(0.5*phi_acop) * ROOT.TMath.Sqrt( sin2thetastar )
    
    return phistar


"""
transverse mass
"""
def calcMt(p1,p2):

    #get pt and phi
    pt1, pt2, phi1,phi2=None,None,None,None
    try:
        pt1, phi1=p1.Pt(),p1.Phi()
        pt2, phi2=p2.Pt(),p2.Phi()
    except:
        try :
            pt1,phi1=p1
            pt1,phi2=p2
        except:
            raise InputError('Unable to retrieve eta/phi')

    dphi = ROOT.TVector2.Phi_mpi_pi(phi1-phi2)
    mt   = ROOT.TMath.Sqrt(2*pt1*pt2*(1-ROOT.TMath.Cos(dphi)))

    return mt


"""
transverse mass
"""
def calcMtVariations(pvis,pinv):

    p3vis=pvis.Vect().XYvector()
    p3inv=pinv.Vect().XYvector()

    mtVars = [ 2*p3vis.Mod(),
               2*ROOT.TMath.Sqrt( p3vis.Mod2() + p3vis*p3inv ),
               2*ROOT.TMath.Sqrt( p3vis.Mod2() + p3vis*p3inv + 0.25*( p3vis.Px()*p3inv.Py()-p3vis.Py()*p3inv.Px() )/p3vis.Mod2() ),
               calcMt(p1=pvis,p2=pinv) ]

    return mtVars

