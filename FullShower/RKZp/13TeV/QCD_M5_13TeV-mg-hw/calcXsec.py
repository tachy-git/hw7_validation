#!/usr/bin/env python3

import os
import glob
#import ROOT
from array import array

logpath="joblog"
zpmass = 25
jobnumbers=[i for i in range(1132252,1132259)]
jobnumbers=[1132246, 1132294, 1132295, 1132248, 1132249, 1132250, 1132251]
jobnumbers=[1132296, 1132297, 1132298, 1132299, 1132300, 1132258]
jobnumbers=[i for i in range(345510,345519)]
jobnumbers=[345524, 345525, 345526, 1132311, 1132312, 1132313, 1132314, 1132315]
xsec=[]

def calcXsec(jobnumber):

    logfiles = glob.glob(f"{logpath}/job.{jobnumber}.*.out")
    XsecSum = 0
    nJobs = 0
    for logfile in logfiles:
        logfile = open(logfile,"r")
        for line in logfile:
            if "Cross-section" in line:
                line = line.split()
                XsecSum += float(line[2])
                nJobs += 1
        logfile.close()

    if nJobs!=0:
        Xsec = XsecSum/nJobs
    else:
        Xsec = 0

    xsec.append(Xsec)
    print(f"{Xsec:.3e}")

def drawHisto():

    for i in range(len(ptbin)-1):
    # normalize xsec according to the pt range
        #print(xsec[i])
        #print(ptbin[i+1]-ptbin[i])
        xsec[i] = xsec[i]/( ptbin[i+1]-ptbin[i] )
        #print(xsec[i])

    x_arr = array('d', ptbin[:-1])
    y_arr = array('d', xsec)
    graph = ROOT.TGraph(len(x_arr),x_arr,y_arr)
    #graph.SetMarkerSize(20)
    graph.SetTitle()
    graph.GetXaxis().SetTitle("min. of jet p_{T} binning [GeV]")
    graph.GetYaxis().SetTitle("Cross section [pb] / GeV")
    graph.SetMinimum(min(xsec)*0.1)
    graph.SetMaximum(max(xsec)*1.2)

    # fit function
    fit = ROOT.TF1("fit","[0]*pow(x,[1])",min(ptbin),max(ptbin))
    fit.SetParameter(0,xsec[0])
    x1, x2, y1, y2 = ptbin[0], ptbin[-1], xsec[0], xsec[-1]
    slope = (ROOT.log(y2)-ROOT.log(y1)) / (ROOT.log(x2)-ROOT.log(x1))
    fit.SetParameter(1,slope)
    graph.Fit(fit,"R")
    fit_params = [fit.GetParameter(i) for i in range(fit.GetNpar())]
    print("Fit parameters: ", fit_params)

    c1 = ROOT.TCanvas("c1","c1",1000,700)
    #c1.SetLogy()
    c1.cd()
    graph.Draw()
    fit.Draw("SAME")
    graph.Draw("SAME")
    c1.SaveAs(f"png/xsec_{zpmass}.png")


def main():
    for jobnumber in jobnumbers:
        calcXsec(jobnumber)
    #drawHisto()

if __name__ == "__main__" :
    main()
