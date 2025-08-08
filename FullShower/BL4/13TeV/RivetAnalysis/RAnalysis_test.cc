// -*- C++ -*-
#include "Rivet/Analysis.hh"
#include "Rivet/Projections/FinalState.hh"
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

        book(_n_evt,	"n_evt",	10,0,10);

        book(_h_pt_branchQ,   "h_pt_branchQ",   40,0.,200.0);
        book(_h_eta_branchQ,  "h_eta_branchQ",  50,-5.,5.);
        book(_h_pt_zp,   "h_pt_zp",   40,0.,200.0);
        book(_h_eta_zp,  "h_eta_zp",  50,-5.,5.0);
        book(_h_pt_mu,   "h_pt_mu",   100,0.,100.);
        book(_h_pt_lmu,   "h_pt_lmu",   100,0.,100.);
        book(_h_pt_smu,   "h_pt_smu",   100,0.,100.);
        book(_h_eta_mu,   "h_eta_mu", 50, -5., 5.);

        book(_h_dR_qz, "h_dR_qz", 40, 0., 4.);
        book(_h_dEta_qz, "h_dEta_qz", 50,0,5);
        book(_h_dR_qlmu, "h_dR_qlmu", 40, 0., 4.);
        book(_h_dR_qsmu, "h_dR_qsmu", 40, 0., 4.);
        book(_h_dR_qmu, "h_dR_qmu", 40, 0., 4.);

        book(_h_m_qz,  "h_m_qz",  100,0.,500.);

        book(_h_pT,  "h_pT",  100,0.,100.0);
        book(_h_z,   "h_z",   100,0.,1.);

        book(_h_invm1,  "h_invm1",  200,0.,100.);


      }

      /// Perform the per-event analysis
      void analyze(const Event& event) {
        //setup analysis
        const double weight = 1.;

        const FinalState& fs = applyProjection<FinalState>(event, "FS");
        const Particles& allPtls = event.allParticles();

        Particle out, recoil, branchQ;
        vector<Particle> leg;

        // find events with Z'
        // and save Z' as 'out'
        // note that we will focus on events with only one Z'
        int NZp = 0;
        for(const Particle& p : allPtls) {
          if(p.pid()==9900032 && !p.hasChildWith(Cuts::abspid==9900032)) {
            out = p;
            NZp++;
          }
        }
        _n_evt->fill(0,weight);
        if( NZp!=1 ) vetoEvent;
        _n_evt->fill(1,weight);

        Particles outgoingPtls;
        for(const auto& p: allPtls){
          auto gp = p.genParticle();
          if( !gp ) continue;
          auto vtx = gp->production_vertex();
          if( !vtx ) continue;
          if( vtx->particles_in().size()==2 && vtx->particles_out().size()>1 ){
            if( p.abspid()<7 || p.pid()==21 ) outgoingPtls.push_back(p);
          }
          if( outgoingPtls.size()==2 ) break;
        }
        for(const auto& p: outgoingPtls){
          Particle pFinal = p;

          // Follow decay chain if only one child repeatedly
          while (pFinal.children().size() == 1) {
            Particle pChild = pFinal.children()[0];
            if (pFinal.pid() == pChild.pid()) {
              pFinal = pChild;
            } else {
              break;
            }
          }

          const auto& children = pFinal.children();

          // If two children, apply 9900032 logic
          if (children.size() == 2) {
            bool has9900032 = false;
            Particle non9900032;

            for (const auto& child : children) {
              if (child.pid() == 9900032) {
                has9900032 = true;
              } else {
                non9900032 = child;
              }
            }

            if (has9900032) {
              leg.push_back(non9900032);
            } else {
              leg.push_back(pFinal);
            }
          } else {
            // All other cases: just push pFinal
            leg.push_back(pFinal);
          }
        }
        if( leg.size()!=2 ) vetoEvent;
        _n_evt->fill(2,weight);
        double m0, m1, m2;
        m2 = out.momentum().mass();
        double pT, zq;
        for(const auto& l: leg){
          if( l.abseta() > 3. ) vetoEvent;
          if( l.pt() < 20. ) vetoEvent;
        }
        _n_evt->fill(3,weight);
        if( leg.size()==1 ){
          branchQ = leg[0];
          m1 = leg[0].momentum().mass();
          FourMomentum p = leg[0].momentum()+out.momentum();
          double absp3 = p.p();
          FourMomentum n;
          n.setT(1); n.setX(-p.x()/absp3); n.setY(-p.y()/absp3); n.setZ(-p.z()/absp3);
          zq = leg[0].momentum()*n/(p*n);
          pT = sqrt( zq*(1.-zq)*p.invariant()-(1.-zq)*sqr(m1)-zq*sqr(m2) );
        }
        else{
          if( deltaR(leg[0].momentum(),leg[1].momentum()) < 0.4 ) vetoEvent;

          double pT2[2], z[2];
          for(unsigned i=0; i<2; i++) {
            m1 = leg[i].momentum().mass();
            FourMomentum p = leg[i].momentum()+out.momentum();
            double absp3 = p.p();
            FourMomentum n;
            n.setT(1); n.setX(-p.x()/absp3); n.setY(-p.y()/absp3); n.setZ(-p.z()/absp3);
            z[i] = leg[i].momentum()*n/(p*n);
            pT2[i] = z[i]*(1.-z[i])*p.invariant()-(1.-z[i])*sqr(m1)-z[i]*sqr(m2);
          }

          if(pT2[0]>=0. && (pT2[0]<pT2[1] || pT2[1]<0.)) {
            branchQ = leg[0]; recoil = leg[1];
            pT = sqrt(pT2[0]);
            zq = z[0];
          }
          else {
            branchQ = leg[1]; recoil = leg[0];
            pT = sqrt(pT2[1]);
            zq = z[1];
          }
        }
        _n_evt->fill(5,weight);

        _h_pT->fill(pT);
        _h_z->fill(zq);

        _h_pt_branchQ->fill(branchQ.pt(),weight);
        _h_eta_branchQ->fill(branchQ.eta(),weight);
        _h_pt_zp->fill(out.pt(),weight);
        _h_eta_zp->fill(out.eta(),weight);

        //if( branchQ.pt()<30. ) vetoEvent;
        //_n_evt->fill(6,weight);

        double dR = deltaR(branchQ.momentum(),out.momentum());
        _h_dR_qz->fill(dR,weight);
        _h_dEta_qz->fill(deltaEta(branchQ.momentum(),out.momentum()),weight);

        _h_m_qz->fill((branchQ.momentum()+out.momentum()).mass(),weight);

        // muon
        Particle mu1, mu2, lmu, smu; bool b_mu1 = false; bool b_mu2 = false;
        for(const Particle& p : fs.particles()) {
          // no kinematic cuts on muons
          if( p.pt() < 10. || p.abseta() > 2.4 ) continue;
          if(p.pid()==13&&!b_mu1) {
            mu1=p; b_mu1 = true;
          }
          else if(p.pid()==-13&&!b_mu2) {
            mu2=p; b_mu2 = true;
          }
          if( b_mu1 && b_mu2 ) break;
        }
        if( !(b_mu1 && b_mu2) ) vetoEvent;
        _n_evt->fill(7,weight);

        if(mu1.pt()>mu2.pt()) { lmu=mu1; smu=mu2; }
        else { lmu=mu2; smu=mu1; }

        const FourMomentum Zp = mu1.momentum() + mu2.momentum();
        double invm = (mu1.momentum()+mu2.momentum()).mass();
        if( invm > 3.0 && invm < 3.2 ) vetoEvent;

        _h_pt_mu->fill(mu1.pt(), weight);
        _h_pt_mu->fill(mu2.pt(), weight);
        _h_eta_mu->fill(mu1.eta(), weight);
        _h_eta_mu->fill(mu2.eta(), weight);
        _h_pt_lmu->fill(lmu.pt(), weight);
        _h_pt_smu->fill(smu.pt(), weight);
        _h_invm1->fill(invm, weight);

        _h_dR_qmu->fill(deltaR(branchQ.momentum(),lmu.momentum()));
        _h_dR_qmu->fill(deltaR(branchQ.momentum(),smu.momentum()));
        _h_dR_qlmu->fill(deltaR(branchQ.momentum(),lmu.momentum()));
        _h_dR_qsmu->fill(deltaR(branchQ.momentum(),smu.momentum()));

      }

      /// Normalise histograms etc., after the run
      void finalize() {
        double weight = crossSection()/sumOfWeights()/femtobarn * numEvents()/20000.;

        scale(_n_evt, weight);

        scale(_h_pT, weight);
        scale(_h_z, weight);

        scale(_h_pt_branchQ, weight );
        scale(_h_eta_branchQ, weight );
        scale(_h_pt_zp, weight );
        scale(_h_eta_zp, weight );
        scale(_h_pt_mu, weight);
        scale(_h_pt_lmu, weight);
        scale(_h_pt_smu, weight);
        scale(_h_eta_mu, weight);

        scale(_h_dR_qz, weight );
        scale(_h_dEta_qz, weight );
        scale(_h_dR_qlmu, weight);
        scale(_h_dR_qsmu, weight);
        scale(_h_dR_qmu, weight);

        scale(_h_m_qz, weight );
        scale(_h_invm1, weight);

        // data file
        std::ofstream file;
        string fname = "RAnalysis.dat";
        file.open(fname.c_str());
        file << "PLOT\n";
        file.close();
      }

      //@}


    private:

      // Data members like post-cuts event weight counters go here


      /// @name Histograms
      //@{

      Histo1DPtr _n_evt;

      Histo1DPtr _h_pT;
      Histo1DPtr _h_qT;
      Histo1DPtr _h_z;

      Histo1DPtr _h_pt_branchQ;
      Histo1DPtr _h_eta_branchQ;
      Histo1DPtr _h_pt_zp;
      Histo1DPtr _h_eta_zp;
      Histo1DPtr _h_pt_mu;
      Histo1DPtr _h_pt_lmu;
      Histo1DPtr _h_pt_smu;
      Histo1DPtr _h_eta_mu;

      Histo1DPtr _h_dR_qz;
      Histo1DPtr _h_dEta_qz;
      Histo1DPtr _h_dR_qlmu;
      Histo1DPtr _h_dR_qsmu;
      Histo1DPtr _h_dR_qmu;

      Histo1DPtr _h_m_qz;
      Histo1DPtr _h_invm1;


      //@}
  };



  // The hook for the plugin system
  DECLARE_RIVET_PLUGIN(RAnalysis);


}
