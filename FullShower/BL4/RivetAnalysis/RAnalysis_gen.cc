// -*- C++ -*-
#include "Rivet/Analysis.hh"
#include "Rivet/Projections/FinalState.hh"
#include "Rivet/Projections/FastJets.hh"
#include <iostream>
#include <fstream>
/// @todo Include more projections as required, e.g. ChargedFinalState, FastJets, ZFinder...

double norm = 1.;
int zp_pid = 9900032;

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

        book(_n_zp,    "n_zp",   5,0,5);

        book(_h_pt_zp, "h_pt_zp",   500,0.,1000.);
        book(_h_pt_q, "h_pt_q",   500,0.,1000.);
        book(_h_pt_lmu, "h_pt_lmu",   500,0.,1000.);
        book(_h_pt_smu, "h_pt_smu",   500,0.,1000.);

        book(_h_eta_zp, "h_eta_zp", 50, -5, 5);
        book(_h_eta_q, "h_eta_q", 50, -5, 5);
        book(_h_eta_lmu, "h_eta_lmu", 24, -2.4, 2.4);
        book(_h_eta_smu, "h_eta_smu", 24, -2.4, 2.4);

        book(_h_dR_qzp, "h_dR_qzp", 40,0,4.);
        book(_h_dR_qdimu, "h_dR_qdimu", 40,0,4.);
        book(_h_dR_qlmu, "h_dR_qlmu", 40,0,4.);
        book(_h_dR_qsmu, "h_dR_qsmu", 40,0,4.);
        book(_h_dR_dimu, "h_dR_dimu", 40,0,4.);

        book(_h_f_dR_qzp, "h_f_dR_qzp", 50,0,0.5);
        book(_h_f_dR_qdimu, "h_f_dR_qdimu", 50,0,0.5);
        book(_h_f_dR_qlmu, "h_f_dR_qlmu", 50,0,0.5);
        book(_h_f_dR_qsmu, "h_f_dR_qsmu", 50,0,0.5);
        book(_h_f_dR_dimu, "h_f_dR_dimu", 50,0,0.5);

        book(_h_invm_1, "h_invm_1", 80, 0, 80);
        book(_h_invm_2, "h_invm_2", 400, 0, 20);
      }
      Particles findZprimes(const Particles& allptc){
        Particles zps;
        for(const Particle& p : allptc){
          if(p.pid()==zp_pid && !p.hasChildWith(Cuts::abspid==zp_pid)) {
            zps.push_back(p);
          }
        }
        return zps;
      }
      Particles findOutPartons(const Particles& allptc){
        Particles outs;
        for(const auto& p : allptc) {
          auto gp = p.genParticle();
          if( !gp ) continue;
          if( gp->status() != 11 ) continue;
          auto vtx = gp->production_vertex();
          if( !vtx ) continue;
          if( vtx->particles_in().size()==2 && vtx->particles_out().size()>1 ) {
            if( p.abspid()<7 || p.pid()==21 ) {
              outs.push_back(p);
            }
          }
          if( outs.size() == 2 ) break;
        }
        return outs;
      }
      bool checkFSR(const Particles& outs){
        bool isFSR = false;
        for(const auto& p : outs) {
          if( p.pid() == 21 ) continue;
          Particle cand = p;
          while( cand.children().size()>0 && !isFSR ) {
            if( cand.children().size() == 1 ) {
              if( (cand.children())[0].pid() == p.pid() )
                cand = (cand.children())[0];
              else break;
            }
            else if( cand.children().size() == 2 ) {
              Particle p0 = (cand.children())[0];
              Particle p1 = (cand.children())[1];
              if( p0.pid() == p.pid() ) {
                if( p1.pid() == zp_pid ) isFSR = true;
                else if( 20 < p1.pid() && p1.pid() < 26 ) cand = p0;
                else break;
              }
              else if( p1.pid() == p.pid() ) {
                if( p0.pid() == zp_pid ) isFSR = true;
                else if( 20 < p0.pid() && p0.pid() < 26 ) cand = p1;
                else break;
              }
              else break;
            }
            else break;
          }
          if( isFSR ) break;
        }
        return isFSR;
      }
      Particles findLegPartons(const string sampleTag, const Particle& zp, const Particles& outs){
        Particles legs;
        bool isFSR = false;
        if( sampleTag == "RS" ) isFSR = checkFSR(outs);
        // ===========================================
        // FSR case
        // We can trace back to the hard scattering from the Zprime
        // and find which outgoing parton radiates the Zrpime
        // ==========================================
        if( isFSR ){
          if( zp.parents().size() != 1 ){
            cout << "[ERROR] # of Zprime mother: " << zp.parents().size() << endl;
            return legs;
          }
          // Find the outgoing parton from the Zprime
          Particle cand1 = (zp.parents())[0];
          while( cand1.children().size() == 1 ) { // The parent is Z' itself
            cand1 = (cand1.parents())[0];
          }
          // 'cand1' would be the parton that radiates the Zprime
          if( (cand1.children())[0].pid() == zp_pid ) cand1 = (cand1.children())[1];
          else cand1 = (cand1.children())[0];
          // find the cand1's final copy and push it back to 'legs'
          while( cand1.children().size() > 0 ) {
            if( cand1.children().size() == 1 ) {
              if( (cand1.children())[0].pid() == cand1.pid() )
                cand1 = (cand1.children())[0];
              else {
                legs.push_back(cand1);
                break;
              }
            }
            else {
              legs.push_back(cand1);
              break;
            }
          }
          // Find another leg that does not radiates the Zprime
          Particle cand2; Particle p = zp;
          while( p.parents().size() == 1 ) {
            p = (p.parents())[0];
            if( p.genParticle() == outs[0].genParticle() ) {
              cand2 = outs[1];
              break;
            }
            else if( p.genParticle() == outs[1].genParticle() ) {
              cand2 = outs[0];
              break;
            }
          }
          if( cand2.genParticle() == nullptr ) {
            cout<<"[ERROR] Wrong hard state quraks."<<endl;
            return legs;
          }
          while( cand2.children().size()>0 ) {
            if( cand2.children().size() == 1 ) {
              if( (cand2.children())[0].pid() == cand2.pid() )
                cand2 = (cand2.children())[0];
              else {
                legs.push_back(cand2);
                break;
              }
            }
            else {
              legs.push_back(cand2);
              break;
            }
          }
        } // End of if( isFSR )
        // ===========================================
        // We can find the final copy of the hard scattering outgoing parton
        // But cannot trace which one radiated the Zprime unless it is FSR
        // ===========================================
        else{
          for(const auto& p : outs) {
            Particle cand = p;
            while( cand.children().size()>0 ) {
              if( cand.children().size() == 1 ) {
                if( p.pid() == (cand.children())[0].pid() )
                  cand = (cand.children())[0];
                else {
                  legs.push_back(cand);
                  break; // Normally child's PID == 81, which means hadronisation (need to be checked)
                }
              }
              else if( cand.children().size() == 2 ) {
                Particle p0 = (cand.children())[0];
                Particle p1 = (cand.children())[1];
                if( ( cand.pid() == 21 && p0.abspid() == p1.abspid() ) // g -> qqbar or g -> gg
                    || ( p0.pid() == p.pid() && (20 < p1.pid() && p1.pid() < 26) ) // q -> qg
                    || ( p1.pid() == p.pid() && (20 < p0.pid() && p0.pid() < 26) ) // q -> gq
                  )
                  legs.push_back(cand);
                else { // For validation. One can remove this part in safe
                  cout<<endl<<"[ERROR] Something strange is radiated."<<endl;
                  cout<<"parent: "; print_particle(cand);
                  cout<<"p0: "; print_particle(p0);
                  cout<<"p1: "; print_particle(p1);
                  return legs;
                }
                break;
              }
              else {
                legs.push_back(cand);
                break;
              }
            }
          }
        } // End of else
        return legs;
      }
      Particle findPartnerQuark(const Particle & zp, const Particles& legs){
        Particle partner;
        double pT2[2], z[2];
        for(unsigned i=0; i<legs.size(); i++) {
          Particle leg = legs[i];
          double m1 = leg.momentum().mass();
          double m2 = zp.mass();
          FourMomentum p = leg.momentum()+zp;
          double absp3 = p.p();
          FourMomentum n;
          n.setT(1); n.setX(-p.x()/absp3); n.setY(-p.y()/absp3); n.setZ(-p.z()/absp3);
          z[i] = leg.momentum()*n/(p*n);
          pT2[i] = z[i]*(1.-z[i])*p.invariant()-(1.-z[i])*sqr(m1)-z[i]*sqr(m2);
        }
        if(pT2[0]>=0. && (pT2[0]<pT2[1] || pT2[1]<0.)) {
          partner = legs[0];
        }
        else {
          partner = legs[1];
        }
        return partner;
      }
      double getIso(const Particle& mu, const Particles& fsptls){
        double chaHadPt = 0;
        double neuHadEt = 0;
        double photonEt = 0;
        for(const auto& p: fsptls){
          if( deltaR(mu.momentum(),p.momentum())>0.4 ) continue;
          if( p.isHadron() ){
            if( p.isCharged() ){ chaHadPt += p.pt(); }
            else{ neuHadEt += p.Et(); }
          }
          else if( p.pid()==22 ){ photonEt += p.Et(); }
        }
        double PFIso = ( chaHadPt+neuHadEt+photonEt ) / mu.pt();
        return PFIso;
      }

      bool passJetID(const Jet& jet){
        Particles constituents = jet.constituents();
        int chaMul = 0;
        for(const auto& p: constituents){
          if( p.isCharged() ) chaMul += 1;
        }
        double neuHad = jet.neutralEnergy() / jet.totalEnergy();
        double chaHad = jet.hadronicEnergy() / jet.totalEnergy();
        int totMul = constituents.size();

        bool pass1 = neuHad < 0.9;
        bool pass2 = chaHad > 0;
        bool pass3 = totMul > 1;
        bool pass4 = chaMul > 0;

        return pass1 && pass2 && pass3 && pass4;
      }

      /// Perform the per-event analysis
      void analyze(const Event& event) {
        //setup analysis

        const FinalState& fs = applyProjection<FinalState>(event, "FS");
        const FastJets& alljets = applyProjection<FastJets>(event, "Jets");
        const Jets& ptjets = alljets.jetsByPt(20*GeV);
        const Particles& allptc = event.allParticles();

        // =======================================
        // Zprime selection (only for Signal)
        // =======================================
        Particle zp, partner;
        const string sampleTag = "__SAMPLETAG__";
        if( sampleTag == "FO" || sampleTag == "RS" ){
          Particles zps = findZprimes(allptc);
          int nZp = zps.size();
          _n_zp -> fill(nZp);
          if( zps.size() != 1 ) vetoEvent;
          zp = zps[0];

          Particles outs = findOutPartons(allptc);
          if( outs.size() != 2 ){
            cout << "[ERROR] # of outgoing parton: " << outs.size() << endl; 
            vetoEvent;
          }

          Particles legs = findLegPartons(sampleTag, zp, outs);
          if( legs.size() != 2 ){
            cout << "[ERROR] # of leg parton: " << legs.size() << endl;
            vetoEvent;
          }
          partner = findPartnerQuark(zp, legs);
        }

        // =======================================
        // GEN level study
        // =======================================
        if( partner.pt() < 30. || partner.abseta() > 2.4 ) vetoEvent;
        Particles muons;
        for(const auto& p: fs.particles()){
          if( p.abspid() != 13 )  continue;
          if( p.pt() < 10. )      continue;
          if( p.abseta() > 2.4 )  continue;
          muons.push_back(p);
        }
        if( muons.size() < 2 ) vetoEvent;
        std::sort(muons.begin(),muons.end(),[](const Particle& a,const Particle& b){return a.pt()>b.pt();});

        Particle lmu = muons[0]; Particle smu = muons[1];
        const FourMomentum dimuon = lmu.momentum() + smu.momentum();
        double invm = dimuon.mass();

        _h_pt_q->fill( partner.pt() );
        _h_pt_lmu->fill( lmu.pt() );
        _h_pt_smu->fill( smu.pt() );
        _h_pt_zp->fill( zp.pt() );

        _h_eta_q->fill( partner.eta() );
        _h_eta_lmu->fill( lmu.eta() );
        _h_eta_smu->fill( smu.eta() );
        _h_eta_zp->fill( zp.eta() );

        _h_dR_qlmu->fill( deltaR(partner.momentum(),lmu.momentum()) );
        _h_dR_qsmu->fill( deltaR(partner.momentum(),smu.momentum()) );
        _h_dR_qzp->fill( deltaR(partner.momentum(),zp.momentum()) );
        _h_dR_qdimu->fill( deltaR(partner.momentum(),dimuon) );
        _h_dR_dimu->fill( deltaR(lmu.momentum(),smu.momentum()));

        _h_f_dR_qlmu->fill( deltaR(partner.momentum(),lmu.momentum()) );
        _h_f_dR_qsmu->fill( deltaR(partner.momentum(),smu.momentum()) );
        _h_f_dR_qzp->fill( deltaR(partner.momentum(),zp.momentum()) );
        _h_f_dR_qdimu->fill( deltaR(partner.momentum(),dimuon) );
        _h_f_dR_dimu->fill( deltaR(lmu.momentum(),smu.momentum()));

        _h_invm_1->fill(invm);
        _h_invm_2->fill(invm);

      }// End of event loop

      /// Normalise histograms etc., after the run
      void finalize() {
        norm = (double)numEvents() / 20000.;
        double weight = crossSection()/sumOfWeights()/femtobarn * norm;

        scale(_n_zp, weight);

        scale(_h_pt_zp, weight);
        scale(_h_pt_q, weight);
        scale(_h_pt_lmu, weight);
        scale(_h_pt_smu, weight);

        scale(_h_eta_zp, weight);
        scale(_h_eta_q, weight);
        scale(_h_eta_lmu, weight);
        scale(_h_eta_smu, weight);

        scale(_h_dR_qzp, weight);
        scale(_h_dR_qdimu, weight);
        scale(_h_dR_qlmu, weight);
        scale(_h_dR_qsmu, weight);
        scale(_h_dR_dimu, weight);

        scale(_h_f_dR_qzp, weight);
        scale(_h_f_dR_qdimu, weight);
        scale(_h_f_dR_qlmu, weight);
        scale(_h_f_dR_qsmu, weight);
        scale(_h_f_dR_dimu, weight);

        scale(_h_invm_1, weight);
        scale(_h_invm_2, weight);

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
      Histo1DPtr _n_zp;
      Histo1DPtr _h_pt_zp;
      Histo1DPtr _h_pt_q;
      Histo1DPtr _h_pt_lmu;
      Histo1DPtr _h_pt_smu;
      Histo1DPtr _h_eta_zp;
      Histo1DPtr _h_eta_q;
      Histo1DPtr _h_eta_lmu;
      Histo1DPtr _h_eta_smu;
      Histo1DPtr _h_dR_mumu;
      Histo1DPtr _h_dR_qzp;
      Histo1DPtr _h_dR_qdimu;
      Histo1DPtr _h_dR_qlmu;
      Histo1DPtr _h_dR_qsmu;
      Histo1DPtr _h_dR_dimu;
      Histo1DPtr _h_f_dR_qzp;
      Histo1DPtr _h_f_dR_qdimu;
      Histo1DPtr _h_f_dR_qlmu;
      Histo1DPtr _h_f_dR_qsmu;
      Histo1DPtr _h_f_dR_dimu;
      Histo1DPtr _h_invm_1;
      Histo1DPtr _h_invm_2;
      //@}


      void print_particle(const Rivet::Particle& p) const {
        std::cout << p.pid()
          << " (" << p.pt()
          << ", " << p.eta()
          << ", " << p.phi() << ")"
          << std::endl;
      }
      void print_particle(const FourMomentum& p) const {
        std::cout << " (" << p.pt()
          << ", " << p.eta()
          << ", " << p.phi() << ")"
          << std::endl;
      }
      void print_particle(const Jet& p) const {
        std::cout << " (" << p.pt()
          << ", " << p.eta()
          << ", " << p.phi() << ")"
          << std::endl;
      }

  };


  // The hook for the plugin system
  //DECLARE_RIVET_PLUGIN(RAnalysis);
  RIVET_DECLARE_PLUGIN(RAnalysis);
}
