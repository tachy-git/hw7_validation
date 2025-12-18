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

      book(_n_evt,    "n_evt",   10,0,10);
      book(_n_zp,    "n_zp",   5,0,5);

      // before the event selection
      book(_h_pt_zp, "h_pt_zp",   100,0.,200.);
      book(_h_pt_q, "h_pt_q",   100,0.,200.);
      book(_h_eta_zp, "h_eta_zp", 50, -5, 5);
      book(_h_eta_q, "h_eta_q", 50, -5, 5);
      book(_h_dR_qzp, "h_dR_qzp", 40,0,4.);

      // after the event selection1
      book(_es_h_pt_zp, "es_h_pt_zp",   100,0.,200.);
      book(_es_h_pt_q, "es_h_pt_q",   100,0.,200.);
      book(_es_h_pt_j, "es_h_pt_j",   400,0.,800.);
      book(_es_h_pt_lmu, "es_h_pt_lmu",   50,0.,100.);
      book(_es_h_pt_smu, "es_h_pt_smu",   50,0.,100.);

      book(_es_h_eta_zp, "es_h_eta_zp", 50, -5, 5);
      book(_es_h_eta_q, "es_h_eta_q", 50, -5, 5);
      book(_es_h_eta_j, "es_h_eta_j", 24, -2.4, 2.4);
      book(_es_h_eta_lmu, "es_h_eta_lmu", 24, -2.4, 2.4);
      book(_es_h_eta_smu, "es_h_eta_smu", 24, -2.4, 2.4);

      book(_es_h_dR_mumu, "es_h_dR_mumu", 40,0,4.);
      book(_es_h_dR_qzp, "es_h_dR_qzp", 40,0,4.);
      book(_es_h_dR_qdimu, "es_h_dR_qdimu", 40,0,4.);
      book(_es_h_dR_qlmu, "es_h_dR_qlmu", 40,0,4.);
      book(_es_h_dR_qsmu, "es_h_dR_qsmu", 40,0,4.);
      book(_es_h_dR_jzp, "es_h_dR_jzp", 40,0,4.);
      book(_es_h_dR_jdimu, "es_h_dR_jdimu", 40,0,4.);
      book(_es_h_dR_jlmu, "es_h_dR_jlmu", 40,0,4.);
      book(_es_h_dR_jsmu, "es_h_dR_jsmu", 40,0,4.);

      book(_es_h_invm_1, "es_h_invm_1", 120, 0, 6);
      book(_es_h_invm_2, "es_h_invm_2", 100, 5, 15);
      book(_es_h_invm_3, "es_h_invm_3", 84, 18, 60);

      book(_es_h_sig_5, "es_h_sig_5", 1, 4.75, 5.25);
      book(_es_h_sig_8, "es_h_sig_8", 1, 7.6, 8.4);
      book(_es_h_sig_10, "es_h_sig_10", 1, 9.5, 10.5);
      book(_es_h_sig_12, "es_h_sig_12", 1, 11.4, 12.6);
      book(_es_h_sig_20, "es_h_sig_20", 1, 19, 21);
      book(_es_h_sig_30, "es_h_sig_30", 1, 28.5, 31.5);
      book(_es_h_sig_50, "es_h_sig_50", 1, 47.5, 52.5);


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

    double getMuFrac(const Jet& jet){
      Particles constituents = jet.constituents();
      double totMuE = 0;
      for(const auto& p: constituents){
        if( p.abspid()==13 ){
          totMuE += p.energy();
        }
      }
      double muFrac = totMuE / jet.totalEnergy();
      return muFrac;
    }

    /// Perform the per-event analysis
    void analyze(const Event& event) {
      //setup analysis

      const FinalState& fs = applyProjection<FinalState>(event, "FS");
      const FastJets& alljets = applyProjection<FastJets>(event, "Jets");
      const Jets& ptjets = alljets.jetsByPt(0.5*GeV);

      const Particles& allptc = event.allParticles();

      _n_evt->fill(0);

      // =======================================
      // Basic selection
      // N(Z') == 1
      // N(hard scatt parton) == 2
      // quark --> final copy w/ smallest pT2
      // =======================================
      // Select only one Z' boson
      Particle zp; int Nzp = 0;
      const string sampleTag = "RS";
      if (sampleTag == "FO" || sampleTag == "RS") {
        for(const Particle& p : allptc) {
          if(p.pid()==zp_pid && !p.hasChildWith(Cuts::abspid==zp_pid)) {
            zp = p; Nzp++;
          }
        }
        if( Nzp != 1 ) vetoEvent;
        _n_zp->fill(Nzp);
      }
      _n_evt->fill(1);

      // Select outgoing partons in hard scattering level
      Particles outs, legs;
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
      if( outs.size() == 0 || outs.size() > 2 ) {
        cout<<endl<<" *** ERROR *** No hard state quark or too many hard state quarks."<<endl;
        cout<<" #(hard state quark) = "<<outs.size()<<endl<<endl;
        vetoEvent;
      }
      _n_evt->fill(2);

      // For RS sample, check whether the event is FSR or ISR
      bool isFSR = false;
      if( sampleTag == "RS" ) {
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
      }

      // Find final copy of the quark
      if( isFSR ) { // FSR
//cout<<" [NOTICE] isFSR = 1"<<endl;
        if( zp.parents().size() == 1 ) {
          Particle cand = (zp.parents())[0];
          while( cand.children().size() == 1 ) { // The parent is Z' itself
            cand = (cand.parents())[0];
          }
          if( (cand.children())[0].pid() == zp_pid ) cand = (cand.children())[1];
          else cand = (cand.children())[0];
          while( cand.children().size() > 0 ) {
            if( cand.children().size() == 1 ) {
              if( (cand.children())[0].pid() == cand.pid() )
                cand = (cand.children())[0];
              else {
                legs.push_back(cand);
                break;
              }
            }
            else {
              legs.push_back(cand);
              break;
            }
          }
          if( cand.children().size() == 0 ) legs.push_back(cand); // This line is for GEN analysis. You can erase this life for jet analysis safely
        }
        else { // For validation. Impossible radiation.
          cout<<" *** ERROR *** Z' has two parents."<<endl;
          vetoEvent;
        }

        Particle cand; Particle p = zp;
        while( p.parents().size() == 1 ) {
          p = (p.parents())[0];
          if( p.genParticle() == outs[0].genParticle() ) {
            cand = outs[1];
            break;
          }
          else if( p.genParticle() == outs[1].genParticle() ) {
            cand = outs[0];
            break;
          }
        }
        if( cand.genParticle() == nullptr ) {
          cout<<" *** ERROR *** Wrong hard state quraks."<<endl;
          vetoEvent;
        }
        while( cand.children().size()>0 ) {
          if( cand.children().size() == 1 ) {
            if( (cand.children())[0].pid() == cand.pid() )
              cand = (cand.children())[0];
            else {
              legs.push_back(cand);
              break;
            }
          }
          else {
            legs.push_back(cand);
            break;
          }
        }
        if( cand.children().size() == 0 ) legs.push_back(cand); // This line is for GEN analysis. You can erase this life for jet analysis safely
      } // If FSR

      else { // FO, RS(ISR), backgrounds, or something else
//cout<<" [NOTICE] isFSR = 0"<<endl<<endl;
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
                cout<<endl<<" *** ERROR *** Something strange is radiated."<<endl;
                cout<<"parent: "; print_particle(cand);
                cout<<"p0: "; print_particle(p0);
                cout<<"p1: "; print_particle(p1);
                vetoEvent;
              }
              break;
            }
            else {
              legs.push_back(cand);
              break;
            }
          }
          if( cand.children().size() == 0 ) legs.push_back(cand); // This line is for GEN analysis. You can erase this life for jet analysis safely
        }
      }

      if( legs.size() != 2 ) { // legs.size() == 0 || legs.size() > 2
        cout<<" *** ERROR *** There is no good hard state quark or there are too many quark candidates.."<<endl;
        cout<<" - hard particles - "<<endl;
        for(const auto& p : outs) {
          print_particle(p);
        }
        cout<<" - final particles - "<<endl;
        for(const auto& p : legs) {
          print_particle(p);
        }
        vetoEvent;
      }
      _n_evt->fill(3);

      // Find the partner quark (the one w/ smallest pT2)
      Particle partner;
      if( legs.size() == 1 ) {
        partner = legs[0];
      }
      else {
        double pT2[2], z[2];
        for(int i=0; i<legs.size(); i++) {
          Particle leg = legs[i];
          double m1 = leg.momentum().mass();
          //double m2 = dimuon.mass();
          double m2 = zp.mass();
          //FourMomentum p = leg.momentum()+dimuon;
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
      }

      // Plot histograms before the event selection
      double zpPt = zp.pt();
      double qPt = partner.pt();
      double zpEta = zp.eta();
      double qEta = partner.eta();
      double drqzp = deltaR(partner.momentum(),zp.momentum());

      _h_pt_zp  -> fill(zpPt);
      _h_pt_q   -> fill(qPt);
      _h_eta_zp -> fill(zpEta);
      _h_eta_q  -> fill(qEta);
      _h_dR_qzp -> fill(drqzp);

      // =======================================
      // Event selection
      // Jet
      //    pT > 30 GeV
      //    |eta| < 2.4
      //    Jet ID selection (no muon energy fraction cut)
      // Muon
      //    OS dimuon inside a jet w/ dR < 0.4
      //    pT > 32(13) GeV
      //    |eta| < 2.4
      //    -> count all the combination
      // =======================================

      Particles muons;
      for(const auto& p: fs.particles()){
        if( p.abspid() != 13 )  continue;
        if( p.pt() < 13. )      continue;
        if( p.abseta() > 2.4 )  continue;
        muons.push_back(p);
      }

      // Jet Loop
      for(const auto& j: ptjets){
        if( j.pt() < 30. )      continue;
        if( j.abseta() > 2.4 )  continue;
        if( !passJetID(j) )     continue;

        // Muon Loop
        Particles nonIsoMuons;
        for(const auto& m: muons){
          if( deltaR(m.momentum(),j.momentum())>0.4 ) continue;
          nonIsoMuons.push_back(m);
        }
        if( nonIsoMuons.size() < 2 ) continue;
        for(const auto& m1: nonIsoMuons){
          for(const auto& m2: nonIsoMuons){
            if( m1.charge() * m2.charge() > 0 ) continue;
            Particle lmu, smu;
            if( m1.pt() > m2.pt() ){
              lmu = m1; smu = m2;
            }
            else{
              lmu = m2; smu = m1;
            }
            if( lmu.pt() < 32. ) continue;
            
            // ============================================
            // Passed all the event selection
            // Fill the histograms
            // ============================================
            _es_h_pt_zp  -> fill( zpPt );
            _es_h_pt_q   -> fill( qPt );
            _es_h_pt_j   -> fill( j.pt() );
            _es_h_pt_lmu -> fill( lmu.pt() );
            _es_h_pt_smu -> fill( smu.pt() );

            _es_h_eta_zp -> fill( zpEta );
            _es_h_eta_q  -> fill( qEta );
            _es_h_eta_j  -> fill( j.eta() );
            _es_h_eta_lmu-> fill( lmu.eta() );
            _es_h_eta_smu-> fill( smu.eta() );

            const FourMomentum dimuon = lmu.momentum() + smu.momentum();
            double invm = dimuon.mass();
            _es_h_invm_1 -> fill(invm);
            _es_h_invm_2 -> fill(invm);
            _es_h_invm_3 -> fill(invm);

            _es_h_sig_5 -> fill(invm);
            _es_h_sig_8 -> fill(invm);
            _es_h_sig_10 -> fill(invm);
            _es_h_sig_12 -> fill(invm);
            _es_h_sig_20 -> fill(invm);
            _es_h_sig_30 -> fill(invm);
            _es_h_sig_50 -> fill(invm);

            _es_h_dR_qzp   -> fill( drqzp );
            _es_h_dR_qdimu -> fill( deltaR(partner.momentum(), dimuon) );
            _es_h_dR_qlmu  -> fill( deltaR(partner.momentum(), lmu.momentum()) );
            _es_h_dR_qsmu  -> fill( deltaR(partner.momentum(), smu.momentum()) );
            _es_h_dR_mumu  -> fill( deltaR(lmu.momentum(), smu.momentum()) );
            _es_h_dR_jzp   -> fill( deltaR(j.momentum(), zp.momentum()) );
            _es_h_dR_jdimu -> fill( deltaR(j.momentum(), dimuon) );
            _es_h_dR_jlmu  -> fill( deltaR(j.momentum(), lmu.momentum()) );
            _es_h_dR_jsmu  -> fill( deltaR(j.momentum(), smu.momentum()) );

            _n_evt -> fill(4);


          }// End of mu2 loop
        }// End of mu1 loop
      }// End of jet loop

    }// End of event loop

    /// Normalise histograms etc., after the run
    void finalize() {
      //const string sampleTag = getOption("sample", "");  // getOption("sample", defaultValue)
      /*const string sampleTag = "RS";
      if (sampleTag == "RS") {
        //MSG_INFO("Detected RS sample from plugin option.");
        norm = (double)numEvents() / 5000.; // Z' radiation rate
        norm *= 0.01; // coupling
        norm *= 0.0106103 / 0.0644342; // BR for Z'->mumu
        norm *= 2.552/10.208; // HepMC xsec bug
      }
      else if (sampleTag == "QCD") {
        //MSG_INFO("Detected QCD sample from plugin option.");
        norm = 1.; 202070.1 / 6308848.; // n_evt based weight
        // 4453.5322999999989 / 19349980.0; // sig(FO, hepmc)/sig(QCD, mg) sig(QCD, hepmc) = 1.399e6
      }
      if (sampleTag == "FO") {
        norm = (double)numEvents() / 5000.;
      }*/

      norm = (double)numEvents() / 20000.;

      double weight = crossSection()/sumOfWeights()/femtobarn * norm;

      scale(_n_evt, weight);
      scale(_n_zp, weight);
      scale(_h_pt_zp, weight);
      scale(_h_pt_q, weight);
      scale(_h_eta_zp, weight);
      scale(_h_eta_q, weight);
      scale(_h_dR_qzp, weight);

      scale(_es_h_pt_zp, weight);
      scale(_es_h_pt_q, weight);
      scale(_es_h_pt_j, weight);
      scale(_es_h_pt_lmu, weight);
      scale(_es_h_pt_smu, weight);
      scale(_es_h_eta_zp, weight);
      scale(_es_h_eta_q, weight);
      scale(_es_h_eta_j, weight);
      scale(_es_h_eta_lmu, weight);
      scale(_es_h_eta_smu, weight);
      scale(_es_h_dR_mumu, weight);
      scale(_es_h_dR_qzp, weight);
      scale(_es_h_dR_qdimu, weight);
      scale(_es_h_dR_qlmu, weight);
      scale(_es_h_dR_qsmu, weight);
      scale(_es_h_dR_jzp, weight);
      scale(_es_h_dR_jdimu, weight);
      scale(_es_h_dR_jlmu, weight);
      scale(_es_h_dR_jsmu, weight);
      scale(_es_h_invm_1, weight);
      scale(_es_h_invm_2, weight);
      scale(_es_h_invm_3, weight);
      scale(_es_h_sig_5, weight);
      scale(_es_h_sig_8, weight);
      scale(_es_h_sig_10, weight);
      scale(_es_h_sig_12, weight);
      scale(_es_h_sig_20, weight);
      scale(_es_h_sig_30, weight);
      scale(_es_h_sig_50, weight);

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
    Histo1DPtr _n_zp;
    Histo1DPtr _h_pt_zp;
    Histo1DPtr _h_pt_q;
    Histo1DPtr _h_eta_zp;
    Histo1DPtr _h_eta_q;
    Histo1DPtr _h_dR_qzp;

    Histo1DPtr _es_h_pt_zp;
    Histo1DPtr _es_h_pt_q;
    Histo1DPtr _es_h_pt_j;
    Histo1DPtr _es_h_pt_lmu;
    Histo1DPtr _es_h_pt_smu;
    Histo1DPtr _es_h_eta_zp;
    Histo1DPtr _es_h_eta_q;
    Histo1DPtr _es_h_eta_j;
    Histo1DPtr _es_h_eta_lmu;
    Histo1DPtr _es_h_eta_smu;
    Histo1DPtr _es_h_dR_mumu;
    Histo1DPtr _es_h_dR_qzp;
    Histo1DPtr _es_h_dR_qdimu;
    Histo1DPtr _es_h_dR_qlmu;
    Histo1DPtr _es_h_dR_qsmu;
    Histo1DPtr _es_h_dR_jzp;
    Histo1DPtr _es_h_dR_jdimu;
    Histo1DPtr _es_h_dR_jlmu;
	Histo1DPtr _es_h_dR_jsmu;
    Histo1DPtr _es_h_invm_1;
    Histo1DPtr _es_h_invm_2;
    Histo1DPtr _es_h_invm_3;
    Histo1DPtr _es_h_sig_5;
    Histo1DPtr _es_h_sig_8;
    Histo1DPtr _es_h_sig_10;
    Histo1DPtr _es_h_sig_12;
    Histo1DPtr _es_h_sig_20;
    Histo1DPtr _es_h_sig_30;
    Histo1DPtr _es_h_sig_50;


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
