// -*- C++ -*-
#include "Rivet/Analysis.hh"
#include "Rivet/Projections/FinalState.hh"
#include "Rivet/Projections/FastJets.hh"
#include <iostream>
#include <fstream>
/// @todo Include more projections as required, e.g. ChargedFinalState, FastJets, ZFinder...



namespace Rivet {


  class RAnalysis : public Analysis {
  public:

    /// Constructor
    RAnalysis()
      : Analysis("RAnalysis")
    {    }

    /// @name Analysis methods
    //@{

    /// Book histograms and initialise projections before the run
    void init() {
      // Projections
      //FinalState fs;
      //declare(fs, "FS");
      //FastJets jets(fs, FastJets::ANTIKT, 0.4);
      //declare(jets, "Jets");

      declare(FinalState(), "FS");
      declare(FastJets(FinalState(), FastJets::ANTIKT, 0.4), "Jets");

      book(_n_evt, "N_evt", 5,0,5);
      book(_n_rad, "N_rad", 5,0,5);

      book(_h_ptj0_true,"h_ptj0_true",50,0,500);
      book(_h_ptj1_true,"h_ptj1_true",50,0,500);
      book(_h_ptj2_true,"h_ptj2_true",50,0,500);
      book(_h_ptj3_true,"h_ptj3_true",50,0,500);
      book(_h_ptq_true,"h_ptq_true",50,0,500);
      book(_h_ptzp_true,"h_ptzp_true",50,0,500);
      book(_h_ptmu_true,"h_ptmu_true",100,0,200);
      book(_h_ptlmu_true,"h_ptlmu_true",100,0,200);
      book(_h_ptsmu_true,"h_ptsmu_true",100,0,200);

	  book(_h_yzp_true,"h_yzp_true",50,0,5);
	  book(_h_ptzp_proj_true,"h_ptzp_proj_true",50,0,500);

      book(_h_invmzp_true,"h_invmzp_true",160,0,80);
      book(_h_mzp_true,"h_mzp_true",160,0,80);

      book(_h_drqz_true,"h_drqz_true",80,0,4);
      book(_h_drjlmu_true,"h_drjlmu_true",80,0,4);
      book(_h_drjsmu_true,"h_drjsmu_true",80,0,4);

      book(_h_z_q1_true,"h_z_q1_true",50,0,1);
      book(_h_z_q2_true,"h_z_q2_true",50,0,1);

      genHistoryFile.open("genHistory.txt");
    }

    /// Perform the per-event analysis
    void analyze(const Event& event) {
      double wgt = 1.; // event.weight(); -> deprecated. weights are counted automatically.

      //setup analysis
      const FinalState& fs = applyProjection<FinalState>(event, "FS");
      const FastJets& alljets = applyProjection<FastJets>(event, "Jets");
      const Jets& ptjets = alljets.jetsByPt();   
      const Particles& allPtls = event.allParticles();

      _n_evt->fill(0,wgt);
      int zpPid = 9900032;

      ///////////////////
      // evt sel 1: z'
      ///////////////////
      int nRad = 0;
      Particle zp, zpLast;
      for(const auto& p: allPtls){
          //if( p.abspid()==zpPid && p.hasParentWithout(Cuts::abspid==zpPid) ){
          if( p.abspid()==zpPid && !p.hasParentWith(Cuts::abspid==zpPid) ){
              nRad++;
              zp = p; // not an array cause we only see one zp event
          }
      }
      _n_rad->fill(nRad,wgt);
      if( nRad != 1 ) vetoEvent;

      zpLast = zp;
      while( zpLast.children().size()==1 ){
          Particle child = (zpLast.children())[0];
          if( child.pid() == zpLast.pid() )
              zpLast = child;
          else
              break;
      }

      Particles zpPartners, zpPartnersLast;
      Particle zpMom = (zp.parents())[0];
      for(const auto& q: zpMom.children()){
          if( q.abspid() > 6 ) continue;
          zpPartners.push_back(q);
          Particle zpPartnerLast = q;
          while( zpPartnerLast.children().size()==1 ){
              Particle child = (zpPartnerLast.children())[0];
              if( child.pid() == zpPartnerLast.pid() )
                  zpPartnerLast = child;
              else
                  break;
          }
          zpPartnersLast.push_back(zpPartnerLast);
      }

      /*
      Particles muons, muonsZp;
      for(const Particle& p : fs.particles()) {
        if( p.abspid()==13 ){
            muons.push_back(p);
            if( p.hasAncestorWith(Cuts::abspid==zpPid,false) ) muonsZp.push_back(p);
        }
      }
      if( muonsZp.size()!= 2 ) vetoEvent;
      */
      _n_evt->fill(1,wgt);

      ///////////////////
      // fill hist
      ///////////////////
      /*
      Particle lmuZp, smuZp;
      if( muonsZp[0].pt()>muonsZp[1].pt() )
          lmuZp = muonsZp[0], smuZp = muonsZp[1];
      else
          lmuZp = muonsZp[1], smuZp = muonsZp[0];

      Particle zp_reco_true = Particle(zpPid, lmuZp.momentum()+smuZp.momentum());
      _h_invmzp_true->fill(zp_reco_true.mass(),wgt);
      _h_ptlmu_true->fill(lmuZp.pt(),wgt);
      _h_ptsmu_true->fill(smuZp.pt(),wgt);
      */
      _h_mzp_true->fill(zp.mass(),wgt);

      double drqz = 999;
      Particle bquark;
      for(const auto& b: zpPartnersLast){
          double dR = deltaR(b.momentum(),zpLast.momentum());
          if( dR < drqz ){
              drqz = dR;
              bquark = b;
          }
      }
      if( bquark.pt()>30. ){
          _h_drqz_true->fill(drqz,wgt);
          _h_ptzp_true->fill(zpLast.pt(),wgt);
          _h_yzp_true->fill(zpLast.absrap(),wgt);
          _h_ptq_true->fill(bquark.pt(),wgt);
      }
      if( ptjets.size()>0 )
          _h_ptj0_true->fill(ptjets[0].pt(),wgt);
      if( ptjets.size()>1 )
          _h_ptj1_true->fill(ptjets[1].pt(),wgt);
      if(  ptjets.size()>2 )
          _h_ptj2_true->fill(ptjets[2].pt(),wgt);
      if( ptjets.size()>3 )
          _h_ptj3_true->fill(ptjets[3].pt(),wgt);

      // only for Herwig
      /*
      FourVector n(1,0,0,-1);
      double momFrac1 = zp.momentum().dot(n) / zpMom.momentum().dot(n) ;
      double momFrac2 = zpPartner.momentum().dot(n) / zpMom.momentum().dot(n);
      _h_z_q1_true->fill(momFrac1,wgt);
      _h_z_q2_true->fill(momFrac2,wgt);
      double evolScale1 = ( 2*zp.momentum().dot(zpPartner.momentum())+zp.mass2()+zpPartner.mass2()-zpMom.mass2() ) / ( momFrac1*(1-momFrac1) );
      double evolScale2 = ( 2*zp.momentum().dot(zpPartner.momentum())+zp.mass2()+zpPartner.mass2()-zpMom.mass2() ) / ( momFrac2*(1-momFrac2) );
      */

      /*
      for(const auto& m: zp.parents()){
          genHistoryFile << "mom: " << std::fixed << m.pid() << " ";
          genHistoryFile << std::scientific << std::setprecision(16) << m.px() << "\n";
          for(const auto& d: m.children()){
              genHistoryFile << "daughter: " << std::fixed << d.pid() << " ";
              genHistoryFile << std::scientific << std::setprecision(16) << d.px() << "\n";
          }
      }
      genHistoryFile << "==========" << std::endl;
      */

    }

    /// Normalise histograms etc., after the run
    void finalize() {
      double weight = crossSection()/sumOfWeights()/femtobarn;

      scale(_n_evt, weight );
      scale(_n_rad, weight );

      scale(_h_ptj0_true, weight );
      scale(_h_ptj1_true, weight );
      scale(_h_ptj2_true, weight );
      scale(_h_ptj3_true, weight );
      scale(_h_ptq_true, weight );
      scale(_h_ptzp_true, weight );
      scale(_h_ptmu_true, weight );
      scale(_h_ptlmu_true, weight );
      scale(_h_ptsmu_true, weight );

      scale(_h_invmzp_true, weight );
      scale(_h_mzp_true, weight );

	  scale(_h_yzp_true, weight );
	  scale(_h_ptzp_proj_true, weight );

      scale(_h_drqz_true, weight );
      scale(_h_drjlmu_true, weight );
      scale(_h_drjsmu_true, weight );

      scale(_h_z_q1_true, weight );
      scale(_h_z_q2_true, weight );

      // data file
      std::ofstream file;
      string fname = "RAnalysis.dat";
      file.open(fname.c_str());
      file << "PLOT\n";
      file.close();
      genHistoryFile.close();
    }
    //@}

  private:
    // Data members like post-cuts event weight counters go here

    /// @name Histograms
    //@{
    Histo1DPtr _n_evt;
    Histo1DPtr _n_rad;

    Histo1DPtr _h_ptj0_true;
    Histo1DPtr _h_ptj1_true;
    Histo1DPtr _h_ptj2_true;
    Histo1DPtr _h_ptj3_true;
    Histo1DPtr _h_ptq_true;
    Histo1DPtr _h_ptzp_true;
    Histo1DPtr _h_ptmu_true;
    Histo1DPtr _h_ptlmu_true;
    Histo1DPtr _h_ptsmu_true;

	Histo1DPtr _h_yzp_true;
	Histo1DPtr _h_ptzp_proj_true;

    Histo1DPtr _h_invmzp_true;
    Histo1DPtr _h_mzp_true;

    Histo1DPtr _h_drqz_true;
    Histo1DPtr _h_drjlmu_true;
    Histo1DPtr _h_drjsmu_true;

    Histo1DPtr _h_z_q1_true;
    Histo1DPtr _h_z_q2_true;

    std::ofstream genHistoryFile;
    //@}
  };

  // The hook for the plugin system
  DECLARE_RIVET_PLUGIN(RAnalysis);
}
