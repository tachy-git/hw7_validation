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
      declare(FinalState(), "FS");
      declare(FastJets(FinalState(), FastJets::ANTIKT, 0.4), "Jets");

	  book(_n_evt,	"n_evt",	10,0,10);
	  book(_n_mu,	"n_mu",	10,0,10);
	  book(_n_mu_all,	"n_mu_all",	10,0,10);
	  book(_n_mu_injet,	"n_mu_injet",	10,0,10);

      book(_h_pt_jet,   "h_pt_jet",   40,0.,200.0);
      book(_h_pt_muon,   "h_pt_muon",   100,0.,100.);
      book(_h_pt_zp,   "h_pt_zp",   40,0.,200.0);
      book(_h_pt_zp_nocut,   "h_pt_zp_nocut",   40,0.,200.0);
      book(_h_pt_branch,   "h_pt_branch",   40,0.,200.0);
      book(_h_pt_lmu,   "h_pt_lmu",   100,0.,100.);
      book(_h_pt_smu,   "h_pt_smu",   100,0.,100.);
      book(_h_pt_cmu1,   "h_pt_cmu1",   100,0.,100.);
      book(_h_pt_cmu2,   "h_pt_cmu2",   100,0.,100.);

      book(_h_eta_zp,  "h_eta_zp",  100,-5.,5.);
      book(_h_eta_zp_nocut,  "h_eta_zp_nocut",  100,-5.,5.);

      book(_h_dR_jz, "h_dR_jz", 40, 0., 4.);
      book(_h_dR_jz_nocut, "h_dR_jz_nocut", 40, 0., 4.);
      book(_h_dR_jlmu, "h_dR_jlmu", 40, 0., 4.);
      book(_h_dR_jsmu, "h_dR_jsmu", 40, 0., 4.);
      book(_h_dR_jcmu1, "h_dR_jcmu1", 40, 0., 4.);
      book(_h_dR_jcmu2, "h_dR_jcmu2", 40, 0., 4.);

      book(_h_invm1,  "h_invm1",  40,0.,20.);
      book(_h_invm2,  "h_invm2",  40,0.,20.);

      //book(_n_h, "n_h", 1,0.,1.);
      //book(_s_h, "s_z_h", 50, 0.,1., 50, 0.,1.);

    }

    /// Perform the per-event analysis
    void analyze(const Event& event) {
      //setup analysis
      const double weight = 1.;

      const FinalState& fs = applyProjection<FinalState>(event, "FS");
      const Particles& allPtls = event.allParticles();
      const FastJets& alljets = applyProjection<FastJets>(event, "Jets");
      const Jets& ptjets = alljets.jetsByPt(0.*GeV);

      int NZp=0;
      // find particles
      Particle out;
      for(const Particle& p : allPtls) {
        if( p.pid()==9900032 && !p.hasChildWith(Cuts::abspid==9900032) ){
          out = p; 
          NZp++;
        }
      }
	  _n_evt->fill(0,weight);
      if( NZp!=1 ) vetoEvent;
	  _n_evt->fill(1,weight);
	  // ////////////////////////
	  // This is for the selecting same phase space both for FO and RS sample
	  // only works for RS sample, not for FO sample
	  for(const auto &p: ((out.parents())[0].parents())[0].children() ){
          if( p.pid() == 9900032 ) continue;
          if( p.pt()<20. )  vetoEvent;
      }
	  _n_evt->fill(2,weight);
	  ///////////////////////////
	  _h_pt_zp_nocut -> fill(out.pt(), weight);
      _h_eta_zp_nocut -> fill(out.eta(), weight);

      Jets jets;
      for(const auto& j: ptjets){
          if( j.abseta() > 2.4 ) continue;
          _h_pt_jet -> fill(j.pt(), weight);
          jets.push_back(j);
      }
      Particles muons, muons_all;
      for(const auto& p: fs.particles()){
          //if( p.abspid()==13 && p.abseta()<2.4 && p.hasAncestorWith(Cuts::abspid==9900032,false) )
          if( p.abspid()==13 && p.abseta()<2.4 ){
              muons_all.push_back(p);
              _h_pt_muon -> fill(p.pt(), weight);
			  if( p.pt()>10. ) muons.push_back(p);
          }
      }
	  _n_mu_all -> fill(muons_all.size(), weight);
	  _n_mu -> fill(muons.size(), weight);

      double dRjz = 999;
      Jet branch;
      for(const auto& j: jets){
          double dR = deltaR(j.momentum(), out.momentum());
          if( dR<dRjz ){
              dRjz = dR;
              branch = j;
          }
      }
      if( dRjz == 999 ) vetoEvent; // no jet for branch candidate
      _n_evt -> fill(3, weight);
      _h_dR_jz_nocut -> fill(dRjz, weight);
      _h_pt_branch -> fill(branch.pt(), weight);
	  int Nmu_injet = 0;
	  for(const auto& m: muons){
		if( deltaR(branch.momentum(), m.momentum())<0.4 ){
			Nmu_injet++;
		}
	  }
	  _n_mu_injet -> fill(Nmu_injet, weight);

      if( branch.pt()<30. ) vetoEvent;
      _n_evt -> fill(4, weight);
      if ( muons.size() < 2 ) vetoEvent;
      _n_evt -> fill(5, weight);

      _h_dR_jz -> fill(dRjz, weight);
      _h_pt_zp -> fill(out.pt(), weight);
      _h_eta_zp -> fill(out.eta(), weight);

      Particle lmu, smu, cmu1, cmu2; // leading, sub-leading, closest, second closest
      double ptMax1 = -999, ptMax2 = -999;
      double dRMin1 = 999, dRMin2 = 999;
      for(const auto& m: muons){
          double pt = m.pt();
          double dR = deltaR(out.momentum(), m.momentum());
          if( pt > ptMax1 ){
              ptMax2 = ptMax1;
              smu = lmu;
              ptMax1 = pt;
              lmu = m;
          }
          else if( pt > ptMax2 ){
              ptMax2 = pt;
              smu = m;
          }
          if( dR < dRMin1 ){
              dRMin2 = dRMin1;
              cmu2 = cmu1;
              dRMin1 = dR;
              cmu1 = m;
          }
          else if( dR < dRMin2 ){
              dRMin2 = dR;
              cmu2 = m;
          }
      }
      _h_pt_lmu -> fill(lmu.pt(), weight);
      _h_pt_smu -> fill(smu.pt(), weight);
      _h_pt_cmu1 -> fill(cmu1.pt(), weight);
      _h_pt_cmu2 -> fill(cmu2.pt(), weight);
      _h_dR_jlmu -> fill(deltaR(branch.momentum(),lmu.momentum()), weight);
      _h_dR_jsmu -> fill(deltaR(branch.momentum(),smu.momentum()), weight);
      _h_dR_jcmu1 -> fill(deltaR(branch.momentum(),cmu1.momentum()), weight);
      _h_dR_jcmu2 -> fill(deltaR(branch.momentum(),cmu2.momentum()), weight);

      Particle recoZp1 = Particle(9900032, lmu.momentum()+smu.momentum());
      _h_invm1 -> fill(recoZp1.mass(), weight);
      Particle recoZp2 = Particle(9900032, cmu1.momentum()+cmu2.momentum());
      _h_invm2 -> fill(recoZp2.mass(), weight);

    }

    /// Normalise histograms etc., after the run
    void finalize() {
      double weight = crossSection()/sumOfWeights()/femtobarn * numEvents()/20000.;

	  scale(_n_evt, weight);
	  scale(_n_mu, weight);
	  scale(_n_mu_all, weight);
	  scale(_n_mu_injet, weight);

	  scale(_h_pt_jet, weight);
	  scale(_h_pt_muon, weight);
	  scale(_h_pt_zp, weight);
	  scale(_h_pt_zp_nocut, weight);
	  scale(_h_pt_branch, weight);
	  scale(_h_pt_lmu, weight);
	  scale(_h_pt_smu, weight);
	  scale(_h_pt_cmu1, weight);
	  scale(_h_pt_cmu2, weight);

	  scale(_h_eta_zp, weight);
	  scale(_h_eta_zp_nocut, weight);

	  scale(_h_dR_jz, weight);
	  scale(_h_dR_jz_nocut, weight);
	  scale(_h_dR_jlmu, weight);
	  scale(_h_dR_jsmu, weight);
	  scale(_h_dR_jcmu1, weight);
	  scale(_h_dR_jcmu2, weight);

	  scale(_h_invm1, weight);
	  scale(_h_invm2, weight);




      //normalize(_s_h);
      // data file
      std::ofstream file;
      string fname = "RAnalysis.dat";
      file.open(fname.c_str());
      //for(unsigned int ix=0;ix<_scatter_h.size();++ix) {
      //  file << _scatter_h[ix].first << " " <<  _scatter_h[ix].second << "\n";
      //}
      file << "PLOT\n";
      file.close();
    }

    //@}


  private:


    // Data members like post-cuts event weight counters go here


    /// @name Histograms
    //@{
	
	Histo1DPtr _n_evt;
	Histo1DPtr _n_mu;
	Histo1DPtr _n_mu_all;
	Histo1DPtr _n_mu_injet;

	Histo1DPtr _h_pt_jet;
	Histo1DPtr _h_pt_muon;
	Histo1DPtr _h_pt_zp;
	Histo1DPtr _h_pt_zp_nocut;
	Histo1DPtr _h_pt_branch;
	Histo1DPtr _h_pt_lmu;
	Histo1DPtr _h_pt_smu;
	Histo1DPtr _h_pt_cmu1;
	Histo1DPtr _h_pt_cmu2;

	Histo1DPtr _h_eta_zp;
	Histo1DPtr _h_eta_zp_nocut;

	Histo1DPtr _h_dR_jz;
	Histo1DPtr _h_dR_jz_nocut;
	Histo1DPtr _h_dR_jlmu;
	Histo1DPtr _h_dR_jsmu;
	Histo1DPtr _h_dR_jcmu1;
	Histo1DPtr _h_dR_jcmu2;

	Histo1DPtr _h_invm1;
	Histo1DPtr _h_invm2;





    //@}

    //vector<pair<double,double> > _scatter_h;
  };



  // The hook for the plugin system
  DECLARE_RIVET_PLUGIN(RAnalysis);


}
