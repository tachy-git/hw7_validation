#!/usr/bin/env python3

import os
import glob
#import ROOT
from array import array

zpmass=55

ptbin=[130,135,140,150,160,170,200,250,9999]
ptbin=[200,210,220,230,250,280,350,9999]
eff=[]

def calcEff(yodafile):

    yoda = open(yodafile,"r")
    lines = yoda.readlines()
    idx = next(i for i, line in enumerate(lines) if "Path: /RAW/RAnalysis/N_evt" in line)
    total = float(lines[idx+11].split()[-1])
    zprad = float(lines[idx+12].split()[-1])
    nevts = float(lines[idx+13].split()[-1])

    eff.append(nevts/total)
    print(f"{total:.0f}\t{zprad:.0f}\t{nevts:.0f}")

def setParams(fit):

    C = min(eff)
    x1, x2, y1, y2 = ptbin[0], ptbin[-1], eff[0], eff[-1]
    B = ( ROOT.log(y2)-ROOT.log(y1)) / ( x2-x1 )
    A = y1

    fit.SetParameter(0,A)
    fit.SetParameter(1,B)
    fit.SetParameter(2,C)

def drawHisto():
    
    x_err = [0 for _ in range(len(ptbin)-1)]
    y_err = []
    for y in eff:
        binErr = ROOT.sqrt( 3000000*y*(1-y) ) / 3000000
# FIXME
        y_err.append(binErr)

    x_arr = array('d', ptbin[:-1])
    y_arr = array('d', eff)
    x_err_arr = array('d', x_err)
    y_err_arr = array('d', y_err)

    graph = ROOT.TGraphErrors(len(x_arr),x_arr,y_arr,x_err_arr,y_err_arr)
    graph.SetTitle()
    graph.GetXaxis().SetTitle("min. of jet p_{T} binning [GeV]")
    graph.GetYaxis().SetTitle("eff")
    graph.SetLineWidth(3)

    # fit function
    fit = ROOT.TF1("fit","[0]*exp([1]*x)+[2]",min(ptbin),max(ptbin))
    #fit = ROOT.TF1("fit","[0]*pow(x,[1])+[2]",min(ptbin),max(ptbin))
    setParams(fit)
    graph.Fit(fit,"R")
    fit_params = [fit.GetParameter(i) for i in range(fit.GetNpar())]
    print("Fit parameters: ", fit_params)

    c1 = ROOT.TCanvas("c1","c1",1000,700)
    graph.SetMinimum(min(eff)*0.5)
    graph.SetMaximum(max(eff)*2)
    c1.SetLogy()
    c1.cd()
    graph.Draw("AP")
    fit.Draw("SAME")
    c1.SaveAs(f"png/eff_{zpmass}.png")
    graph.SetMinimum(min(eff)*0.1)
    graph.SetMaximum(max(eff)*1.2)
    c1.SetLogy(False)
    c1.SaveAs(f"png/eff_{zpmass}_lin.png")

def main():
    for i in range(20):
        yodafile = f"yoda_{zpmass}/LHC-{i}.yoda"
        if not os.path.exists(yodafile): break
        calcEff(yodafile)
    #drawHisto()

if __name__ == "__main__" :
    main()
