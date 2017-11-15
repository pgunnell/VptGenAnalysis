#! /usr/bin/env python

"""\
%prog yoda file

Convert a YODA file to ROOT file
"""
import yoda, os, sys, optparse
from yoda.script_helpers import parse_x2y_args

import yoda, os, sys, optparse
from yoda.script_helpers import parse_x2y_args, filter_aos

#parse arguments
parser = optparse.OptionParser(usage=__doc__)
parser.add_option("-m", "--match", dest="MATCH", metavar="PATT", default=None,
                  help="Only write out histograms whose path matches this regex")
parser.add_option("-M", "--unmatch", dest="UNMATCH", metavar="PATT", default=None,
                  help="Exclude histograms whose path matches this regex")
opts, args = parser.parse_args()

in_out = parse_x2y_args(args, ".yoda",".dat")

#check arguments
if not in_out:
    sys.stderr.write("You must specify the FLAT and YODA file names\n")
    sys.exit(1)

cmssw_base=os.environ["CMSSW_BASE"]

for i, o in in_out:
    analysisobjects = yoda.readYODA(i)
    filter_aos(analysisobjects, opts.MATCH, opts.UNMATCH)
    yoda.writeAIDA(analysisobjects, o)    
    os.system('python %s/src/UserCode/VptGenAnalysis/scripts/aida2root %s'%(cmssw_base,o))
    os.system('mv %s %s'%(o,o.replace('.dat','.root')))
