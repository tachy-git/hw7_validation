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
        declare(FastJets(FinalState(), FastJets::ANTIKT, 0.3), "Jets");

__BOOKHISTO__

book(_h0_dr_leadjet_lm_sm,"h0_dr_leadjet_lm_sm",50,0,0.5,50,0,0.5);

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

        _n_evt->fill(0);

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
        // Some kinematic distribution
        // before the dR cut on jet and muons
        // =======================================
        Particles muons;
        for(const auto& p: fs.particles()){
          if( p.abspid() != 13 )  continue;
          if( p.pt() < 5. )      continue;
          if( p.abseta() > 2.4 )  continue;
          muons.push_back(p);
        }
        if( muons.size() < 2 ) vetoEvent;
        std::sort(muons.begin(),muons.end(),[](const Particle& a,const Particle& b){return a.pt()>b.pt();});

        bool foundDimuon = false;
        Particle lm, sm;
        for(unsigned i=0; i<muons.size(); i++){
          for(unsigned j=i+1; j<muons.size(); j++){
            Particle m1 = muons[i];
            Particle m2 = muons[j];
            if( m1.charge() * m2.charge() > 0 ) continue;
            if( m1.pt() > m2.pt() ){
              lm = m1; sm = m2;
              }
            else{
              lm = m2; sm = m1;
            }
            if( lm.pt() < __LPT__ || sm.pt() < __SPT__ ) continue;
            foundDimuon = true;
            break;
          }
          if(foundDimuon) break;
        }
        if(!foundDimuon) vetoEvent;
        _h0_pt_lm->fill(lm.pt());
        _h0_pt_sm->fill(sm.pt());
        _h0_eta_lm->fill(lm.eta());
        _h0_eta_sm->fill(sm.eta());

        double dr = -999;
        Particle realmu;
        for(const auto& m: muons){
          if( m.pt() < 5. || m.abseta() > 2.4 ) continue;
          if( m.hasAncestorWith(Cuts::abspid==zp_pid,false) ){
            realmu = m;
            break;
          }
        }
        _h0_pt_realmu->fill(realmu.pt());
        _h0_eta_realmu->fill(realmu.eta());

        Jet leadjet;
        bool foundLeadJet = false;
        for(const auto& jet: ptjets){
          if( jet.pt() < 30. ) continue;
          if( jet.abseta() > 2.4 ) continue;
          //if( !passJetID(jet) ) continue;
          leadjet = jet;
          foundLeadJet = true;
          break;
        }
        if(foundLeadJet){
          dr = deltaR(leadjet.momentum(),realmu.momentum());
          _h0_pt_leadjet->fill(leadjet.pt());
          _h0_eta_leadjet->fill(leadjet.eta());
          _h0_dR_leadjet_lm->fill(deltaR(leadjet.momentum(), lm.momentum()));
          _h0_f_dR_leadjet_lm->fill(deltaR(leadjet.momentum(), lm.momentum()));
          _h0_dR_leadjet_sm->fill(deltaR(leadjet.momentum(), sm.momentum()));
          _h0_f_dR_leadjet_sm->fill(deltaR(leadjet.momentum(), sm.momentum()));
          _h0_f_dR_mumu->fill(deltaR(lm.momentum(), sm.momentum()));
          _h0_f_dR_leadjet_realmu->fill(dr);

          _h0_dR_qzp->fill(deltaR(partner.momentum(),zp.momentum()));
          _h0_f_dR_qzp->fill(deltaR(partner.momentum(),zp.momentum()));
          _h0_dR_qlm->fill(deltaR(partner.momentum(),lm.momentum()));
          _h0_f_dR_qlm->fill(deltaR(partner.momentum(),lm.momentum()));
          _h0_pt_zp->fill(zp.pt());
          _h0_eta_zp->fill(zp.eta());
          _h0_pt_q->fill(partner.pt());
          _h0_eta_q->fill(partner.eta());

          _h0_dr_leadjet_lm_sm->fill(deltaR(leadjet.momentum(),lm.momentum()), deltaR(leadjet.momentum(),sm.momentum()));

          _h0_dphi_leadjet_lm->fill(deltaPhi(leadjet.momentum(),lm.momentum()));
          _h0_deta_leadjet_lm->fill(deltaEta(leadjet.momentum(),lm.momentum()));
          if( deltaR(leadjet.momentum(), lm.momentum()) < 0.2 ){
            _h0_pt_leadjet_less->fill(leadjet.pt());
            _h0_dR_qzp_less->fill(deltaR(partner.momentum(),zp.momentum()));
            _h0_f_dR_qzp_less->fill(deltaR(partner.momentum(),zp.momentum()));
            _h0_dR_qlm_less->fill(deltaR(partner.momentum(),lm.momentum()));
            _h0_f_dR_qlm_less->fill(deltaR(partner.momentum(),lm.momentum()));
            _h0_pt_q_less->fill(partner.pt());
            _h0_pt_zp_less->fill(zp.pt());
            _h0_eta_q_less->fill(partner.eta());
            _h0_eta_zp_less->fill(zp.eta());
            _h0_f_dR_leadjet_sm_less->fill(deltaR(leadjet.momentum(), sm.momentum()));
            cout << "[less]zp " << std::scientific << std::setprecision(16) << zp.px() << endl;
            cout << "[less]pq " << std::scientific << std::setprecision(16) << partner.px() << endl;
            cout << "[less]lm " << std::scientific << std::setprecision(16) << lm.px() << " " << lm.hasAncestorWith(Cuts::abspid==zp_pid,false) << endl;
          }
          else if( deltaR(leadjet.momentum(), lm.momentum()) < 0.3){
            _h0_pt_leadjet_more->fill(leadjet.pt());
            _h0_dR_qzp_more->fill(deltaR(partner.momentum(),zp.momentum()));
            _h0_f_dR_qzp_more->fill(deltaR(partner.momentum(),zp.momentum()));
            _h0_dR_qlm_more->fill(deltaR(partner.momentum(),lm.momentum()));
            _h0_f_dR_qlm_more->fill(deltaR(partner.momentum(),lm.momentum()));
            _h0_pt_q_more->fill(partner.pt());
            _h0_pt_zp_more->fill(zp.pt());
            _h0_eta_q_more->fill(partner.eta());
            _h0_eta_zp_more->fill(zp.eta());
            _h0_f_dR_leadjet_sm_more->fill(deltaR(leadjet.momentum(), sm.momentum()));
            cout << "[more] " << std::scientific << std::setprecision(16) << zp.px() << endl;
            cout << "[more]pq " << std::scientific << std::setprecision(16) << partner.px() << endl;
            cout << "[more]lm " << std::scientific << std::setprecision(16) << lm.px() << " " << lm.hasAncestorWith(Cuts::abspid==zp_pid,false) << endl;
          }
        }
        double minDR = 999.;
        Jet closest;
        bool foundClosestJet = false;
        for(const auto& jet: ptjets){
          if( jet.pt() < 30. ) continue;
          if( jet.abseta() > 2.4 ) continue;
          double dR = deltaR(jet.momentum(), lm.momentum());
          if(dR < minDR){
            minDR = dR;
            closest = jet;
            foundClosestJet = true;
          }
        }
        if(foundClosestJet){
          _h0_pt_closest->fill(closest.pt());
          _h0_eta_closest->fill(closest.eta());
          _h0_dR_closest_lm->fill(minDR);
          _h0_f_dR_closest_lm->fill(minDR);
          _h0_dR_closest_sm->fill(deltaR(closest.momentum(), sm.momentum()));
          _h0_f_dR_closest_sm->fill(deltaR(closest.momentum(), sm.momentum()));
        }

        // =======================================
        // Event selection
        //    pT > 30 GeV
        //    |eta| < 2.4
        // Muon
        //    OS dimuon inside a jet w/ dR < 0.3
        //    pT > __LPT__(__SPT__) GeV
        //    |eta| < 2.4
        //    For now, only count the leading combination
        // =======================================
        // Jet Loop
        for(const auto& jet: ptjets){
          if( jet.pt() < 30. )      continue;
          if( jet.abseta() > 2.4 )  continue;

          // Muon Loop
          Particles nonIsoMuons;
          for(const auto& m: muons){
            if( deltaR(m.momentum(),jet.momentum())>0.3 ) continue;
            nonIsoMuons.push_back(m);
          }
          if( nonIsoMuons.size() < 2 ) continue;
          for(unsigned i=0; i<nonIsoMuons.size(); i++){
            for(unsigned j=i+1; j<nonIsoMuons.size(); j++){
              Particle m1 = nonIsoMuons[i];
              Particle m2 = nonIsoMuons[j];
              if( m1.charge() * m2.charge() > 0 ) continue;
              Particle lmu, smu;
              if( m1.pt() > m2.pt() ){
                lmu = m1; smu = m2;
              }
              else{
                lmu = m2; smu = m1;
              }
              if( lmu.pt() < __LPT__ || smu.pt() < __SPT__ ) continue;
              // ============================================
              // Passed all the event selection
              // Fill the histograms
              // ============================================
              const FourMomentum dimuon = lmu.momentum() + smu.momentum();
              double invm = dimuon.mass();
              _h_pt_j   -> fill( jet.pt() );
              _h_pt_lmu -> fill( lmu.pt() );
              _h_pt_smu -> fill( smu.pt() );
              _h_eta_j  -> fill( jet.eta() );
              _h_eta_lmu-> fill( lmu.eta() );
              _h_eta_smu-> fill( smu.eta() );
              _h_invm_1 -> fill(invm);
              _h_invm_2 -> fill(invm);
              _h_dR_mumu  -> fill( deltaR(lmu.momentum(), smu.momentum()) );
              _h_dR_jdimu -> fill( deltaR(jet.momentum(), dimuon) );
              _h_dR_jlmu  -> fill( deltaR(jet.momentum(), lmu.momentum()) );
              _h_dR_jsmu  -> fill( deltaR(jet.momentum(), smu.momentum()) );
              _h_f_dR_mumu  -> fill( deltaR(lmu.momentum(), smu.momentum()) );
              _h_f_dR_jdimu -> fill( deltaR(jet.momentum(), dimuon) );
              _h_f_dR_jlmu  -> fill( deltaR(jet.momentum(), lmu.momentum()) );
              _h_f_dR_jsmu  -> fill( deltaR(jet.momentum(), smu.momentum()) );

              if( sampleTag == "FO" || sampleTag == "RS" ){
                _h_pt_zp  -> fill( zp.pt() );
                _h_pt_q   -> fill( partner.pt() );
                _h_eta_zp -> fill( zp.eta() );
                _h_eta_q  -> fill( partner.eta() );
                _h_dR_qzp   -> fill( deltaR(partner.momentum(), zp.momentum()) );
                _h_dR_qdimu -> fill( deltaR(partner.momentum(), dimuon) );
                _h_dR_qlmu  -> fill( deltaR(partner.momentum(), lmu.momentum()) );
                _h_dR_qsmu  -> fill( deltaR(partner.momentum(), smu.momentum()) );
                _h_dR_jzp   -> fill( deltaR(jet.momentum(), zp.momentum()) );
                _h_f_dR_qzp   -> fill( deltaR(partner.momentum(), zp.momentum()) );
                _h_f_dR_qdimu -> fill( deltaR(partner.momentum(), dimuon) );
                _h_f_dR_qlmu  -> fill( deltaR(partner.momentum(), lmu.momentum()) );
                _h_f_dR_qsmu  -> fill( deltaR(partner.momentum(), smu.momentum()) );
                _h_f_dR_jzp   -> fill( deltaR(jet.momentum(), zp.momentum()) );
              }
              // For now, only count the leading case
              vetoEvent;

            }// End of mu2 loop
          }// End of mu1 loop
        }// End of jet loop

      }// End of event loop

      /// Normalise histograms etc., after the run
      void finalize() {
        norm = (double)numEvents() / 20000.;
        double weight = crossSection()/sumOfWeights()/femtobarn * norm;

__SCALEHISTO__
scale(_h0_dr_leadjet_lm_sm,weight);

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
__HISTOPTR__
Histo2DPtr _h0_dr_leadjet_lm_sm;
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
