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

				//book(_h_pt_branch,   "h_pt_branch",   40,0.,200.0);
				book(_h_pt_branchQ,   "h_pt_branchQ",   40,0.,200.0);
				//book(_h_pt_jet,   "h_pt_jet",   40,0.,200.0);
				book(_h_pt_mu,   "h_pt_mu",   100,0.,100.);
				book(_h_pt_lmu,   "h_pt_lmu",   100,0.,100.);
				book(_h_pt_smu,   "h_pt_smu",   100,0.,100.);

        book(_h_dR_qzp, "h_dR_qzp", 40, 0., 4.);
        book(_h_dR_qlmu, "h_dR_qlmu", 40, 0., 4.);
        book(_h_dR_qsmu, "h_dR_qsmu", 40, 0., 4.);
        book(_h_dR_qmu, "h_dR_qmu", 40, 0., 4.);

        /*
				book(_h_dR_jzp, "h_dR_jzp", 40, 0., 4.);
				book(_h_dR_jlmu, "h_dR_jlmu", 40, 0., 4.);
				book(_h_dR_jsmu, "h_dR_jsmu", 40, 0., 4.);
				book(_h_dR_jmu, "h_dR_jmu", 40, 0., 4.);
        */

				book(_h_invm1,  "h_invm1",  40,0.,20.);

			}

			/// Perform the per-event analysis
			void analyze(const Event& event) {
				//setup analysis
				const double weight = 1.;

				const FinalState& fs = applyProjection<FinalState>(event, "FS");
				const Particles& allPtls = event.allParticles();
				const FastJets& alljets = applyProjection<FastJets>(event, "Jets");
				const Jets& ptjets = alljets.jetsByPt(0.*GeV);

        //========================================
        // Find Zprime
        // focus on evts w/ only one Zprime
        //========================================
				int NZp=0;
        int ZpPid = 9900032;
				//Particle out;
				for(const Particle& p : allPtls) {
					if( p.pid()==ZpPid && !p.hasChildWith(Cuts::abspid==ZpPid) ){
						//out = p; 
						NZp++;
					}
				}
				_n_evt->fill(0, weight);
				if( NZp!=1 ) vetoEvent;
				_n_evt->fill(1, weight);

        //========================================
        // Find final state quarks(from ME)
        // and save them as legs
        //========================================
        Particles outgoingPtls, legs;
				for(const auto& p: allPtls){
          auto gp = p.genParticle();
          if( !gp ) continue;
          auto vtx = gp->production_vertex();
          if( !vtx ) continue;
          if( vtx->particles_in().size()==2 && vtx->particles_out().size()>1 ){
            if( p.abspid()<7 ) outgoingPtls.push_back(p);
          }
          if( outgoingPtls.size()==2 ) break;
				}
        for(const auto& p: outgoingPtls){
          Particle pFinal = p;
          while( pFinal.children().size()==1 ){
            Particle pChild = (pFinal.children())[0];
            if( pFinal.pid() == pChild.pid() ) pFinal = pChild;
          }
          legs.push_back(pFinal);
        }
        
        //========================================
        // Event selection
        // Jet: pT > 30 GeV && |eta| < 2.4
        // OS Muon: pT > 10 GeV && |eta| < 2.4
        //========================================
				Particle mu1, mu2, lmu, smu; bool b_mu1 = false; bool b_mu2 = false;
				for(const Particle& p : fs.particles()) {
					if(p.pt() > 10.&&p.abseta()<2.4) {
						if(p.pid()==13&&!b_mu1) {
							mu1=p; b_mu1 = true;
						}
						else if(p.pid()==-13&&!b_mu2) {
							mu2=p; b_mu2 = true;
						}
					}
					if( b_mu1 && b_mu2 ) break;
				}
				if( !(b_mu1 && b_mu2) ) vetoEvent;
				_n_evt->fill(2, weight);

        //========================================
        // Main analyis part
        //========================================
        // Part0: Zprime reconstruction
				if(mu1.pt()>mu2.pt()) { lmu=mu1; smu=mu2; }
				else { lmu=mu2; smu=mu1; }

				const FourMomentum Zp = mu1.momentum() + mu2.momentum();

        _h_pt_mu->fill(mu1.pt(), weight);
        _h_pt_mu->fill(mu2.pt(), weight);
        _h_pt_lmu->fill(lmu.pt(), weight);
        _h_pt_smu->fill(smu.pt(), weight);
        _h_invm1->fill((mu1.momentum()+mu2.momentum()).mass(), weight);

        // Part1: Gen Analysis
        Particle branchQ;
        if( legs.size()==1 ) branchQ = legs[0];
        else if( legs.size()==2 ){
          // check pT2
          double pT2[2], z[2];
          for(unsigned i=0; i<2; i++) {
            double m1 = legs[i].momentum().mass();
            FourMomentum p = legs[i].momentum() + Zp;
            double absp3 = p.p();
            FourMomentum n;
            n.setT(1); n.setX(-p.x()/absp3); n.setY(-p.y()/absp3); n.setZ(-p.z()/absp3);
            z[i] = legs[i].momentum()*n/(p*n);
            pT2[i] = z[i]*(1.-z[i])*p.invariant()-(1.-z[i])*sqr(m1)-z[i]*sqr(m2);
          }

          if(pT2[0]>=0. && (pT2[0]<pT2[1] || pT2[1]<0.)) {
            branchQ = legs[0]; //recoil = legs[1];
            //pT = sqrt(pT2[0]);
            //zq = z[0];
          }
          else {
            branchQ = legs[1]; //recoil = legs[0];
            //pT = sqrt(pT2[1]);
            //zq = z[1];
          }
        }
        _h_pt_branchQ->fill(branchQ.pt(), weight);
        if( branchQ.pt()>30. ){
          _h_dR_qzp->fill(deltaR(branchQ.momentum(),Zp));
          _h_dR_qmu->fill(deltaR(branchQ.momentum(),lmu.momentum()));
          _h_dR_qmu->fill(deltaR(branchQ.momentum(),smu.momentum()));
          _h_dR_qlmu->fill(deltaR(branchQ.momentum(),lmu.momentum()));
          _h_dR_qsmu->fill(deltaR(branchQ.momentum(),smu.momentum()));
        }

        // Part2: Jet Analysis
        /*
				Jets jets; Jet branch;
				double dr = 999.;
				for(const auto& j: ptjets) {
					if( !(j.abseta() < 2.4 && j.pt() > 30.) ) continue;
					_h_pt_jet->fill(j.pt());
					jets.push_back(j);
					double dr_ = deltaR(j.momentum(), Zp);
					if( dr_ < dr ) {
						dr = dr_;
						branch = j;
					}
				}
				_h_pt_branch->fill(branch.pt(), weight);
				_h_dR_jzp->fill(dr, weight);
				_h_dR_jmu->fill(deltaR(branch.momentum(),lmu.momentum()), weight);
				_h_dR_jmu->fill(deltaR(branch.momentum(),smu.momentum()), weight);
				_h_dR_jlmu->fill(deltaR(branch.momentum(),lmu.momentum()), weight);
				_h_dR_jsmu->fill(deltaR(branch.momentum(),smu.momentum()), weight);
        */
			}

			/// Normalise histograms etc., after the run
			void finalize() {
				double weight = crossSection()/sumOfWeights()/femtobarn * numEvents()/20000.;

				scale(_n_evt, weight);

				//scale(_h_pt_branch, weight);
				scale(_h_pt_branchQ, weight);
				//scale(_h_pt_jet, weight);
				scale(_h_pt_mu, weight);
				scale(_h_pt_lmu, weight);
				scale(_h_pt_smu, weight);

				scale(_h_dR_qzp, weight);
				scale(_h_dR_qlmu, weight);
				scale(_h_dR_qsmu, weight);
				scale(_h_dR_qmu, weight);

        /*
        scale(_h_dR_jzp, weight);
        scale(_h_dR_jlmu, weight);
        scale(_h_dR_jsmu, weight);
        scale(_h_dR_jmu, weight);
        */

				scale(_h_invm1, weight);

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

			//Histo1DPtr _h_pt_branch;
			Histo1DPtr _h_pt_branchQ;
			//Histo1DPtr _h_pt_jet;
			Histo1DPtr _h_pt_mu;
			Histo1DPtr _h_pt_lmu;
			Histo1DPtr _h_pt_smu;

			Histo1DPtr _h_dR_qzp;
			Histo1DPtr _h_dR_qlmu;
			Histo1DPtr _h_dR_qsmu;
			Histo1DPtr _h_dR_qmu;

      /*
      Histo1DPtr _h_dR_jzp;
      Histo1DPtr _h_dR_jlmu;
      Histo1DPtr _h_dR_jsmu;
      Histo1DPtr _h_dR_jmu;
      */

			Histo1DPtr _h_invm1;


			//@}

			//vector<pair<double,double> > _scatter_h;
	};



	// The hook for the plugin system
	DECLARE_RIVET_PLUGIN(RAnalysis);


}
