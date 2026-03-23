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

__BOOKHISTO__


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
          if( gp->status() != 11 && gp->status() != 1 ) continue;
          //cout<<endl<<"  pid = "<<p.pid()<<", ";
          auto vtx = gp->production_vertex();
          if( !vtx ) continue;
          //cout<<"vtx, ";
          if( vtx->particles_in().size()==2 && vtx->particles_out().size()>1 ) {
          //  cout<<"inout OK, ";
            if( p.abspid()<7 || p.pid()==21 ) {
          //    cout<<"push back";
              outs.push_back(p);
            }
          }
          /*
          else {
            cout<<"vtx in = "<<vtx->particles_in().size()<<", vtx out = "<<vtx->particles_out().size()<<endl;
            Particle cand = p;
            cout<<"  + parents: "<<cand.pid();
            while(cand.parents().size()!=0) {
              cout<<" <- ["<<cand.parents().size()<<"]";
              for(const auto& ppp : cand.parents()) {
                cout<<" "<<ppp.pid()<<"("<<ppp.genParticle()->status()<<")";
              }
              cand = cand.parents()[0];
            }
            cout<<endl;
            cand = p;
            cout<<"  + children: "<<cand.pid();
            while(cand.children().size()!=0) {
              cout<<" -> ["<<cand.children().size()<<"]";
              for(const auto& ppp : cand.children()) {
                cout<<" "<<ppp.pid()<<"("<<ppp.genParticle()->status()<<")";
              }
              cand = cand.children()[0];
            }
            cout<<endl;
          }
          */
          //if( outs.size() == 2 ) break;
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
              if( (cand.children())[0].pid() == p.pid() ) {
                cand = (cand.children())[0];
              }
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
        if( sampleTag == "RS" || sampleTag == "RS_One" ) isFSR = checkFSR(outs);

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
          if( cand1.children().size() == 0 ) {
            legs.push_back(cand1);
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
          if( cand2.children().size() == 0 ) {
            legs.push_back(cand2);
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
            if( cand.children().size() == 0 ) 
              legs.push_back(cand);
          }
        } // End of else
        return legs;
      }
      Particle findPartnerQuark(const Particle & zp, const Particles& legs){
        // dR matching
        /*
        double dR[2];
        for(unsigned i=0; i<2; i++){
          dR[i] = deltaR(legs[i].momentum(),zp.momentum());
        }
        if( dR[0] < dR[1] ){
          return legs[0];
        }
        else{
          return legs[1]; // findLegPartons
        }
        */

        // pT2 matching
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
        const Jets& ptjets = alljets.jetsByPt(30*GeV);
        const Particles& allptc = event.allParticles();

        // =======================================
        // Zprime selection (only for Signal)
        // =======================================
        Particle zp, partner;
        const string sampleTag = "__SAMPLETAG__";
        Particles zps = findZprimes(allptc);
        int nZp = zps.size();
        _n_zp -> fill(nZp);
        _n_evt->fill(0);
        if( zps.size() != 1 ) vetoEvent;
        _n_evt->fill(1);
        zp = zps[0];

        /*
        cout<<endl<<"--- New Event ---"<<endl;
        Particle ppp = zp;
        while(ppp.parents().size()!=0) {
          cout<<"PID: "<<ppp.pid()<<", s="<<ppp.genParticle()->status()<<" ("<<ppp.pt()<<", "<<ppp.eta()<<", "<<ppp.phi()<<")"<<endl;
          cout<<"  - parent size = "<<ppp.parents().size()<<", pid";
          for(const auto& pppp : ppp.parents()) {
            cout<<": "<<pppp.pid();
          }
          cout<<endl;
          cout<<"  - children size = "<<ppp.children().size()<<", pid";
          for(const auto& pppp : ppp.children()) {
            cout<<": "<<pppp.pid();
          }
          cout<<endl;
          ppp = ppp.parents()[0];
        }
        */

        Particles outs = findOutPartons(allptc);
        if( outs.size() != 2 ){
          cout << "[ERROR] # of outgoing parton: " << outs.size() << endl; 
          vetoEvent;
        }
        _n_evt->fill(2);

        Particles legs = findLegPartons(sampleTag, zp, outs);
        if( legs.size() != 2 ){
          cout << "[ERROR] # of leg parton: " << legs.size() << endl;
          cout<<endl<<endl;
          vetoEvent;
        }
        _n_evt->fill(3);
        partner = findPartnerQuark(zp, legs);
        
        // ============================================
        // ptj test
        // ============================================
        if( zp.children()[0].pt() < __LPT__ ) vetoEvent;
        if( zp.children()[1].pt() < __SPT__ ) vetoEvent;

        for(const auto& jet: ptjets) {
          if( jet.pt() < 30. ) continue;
          if( jet.abseta() > 2.4 ) continue;
          if( deltaR( zp.children()[0].momentum(), jet.momentum() ) > 0.3 ) continue;
          if( deltaR( zp.children()[1].momentum(), jet.momentum() ) > 0.3 ) continue;

          double dR = 9999; Particle this_parton;
          for(const auto& out: outs) {
            FourMomentum branch = zp.momentum() + partner.momentum();
            if( deltaR( branch, out.momentum() ) < dR ) {
              dR = deltaR( branch, out.momentum() );
              this_parton = out;
            }
          }
          if(dR < 1.) _h_branchpt->fill(this_parton.pt());
          break;
        }

        /*
        if( !(legs[0].pt() > 30. && legs[1].pt() > 30. && legs[0].abseta() < 2.5 && legs[1].abseta() < 2.5) ) vetoEvent; // Restrict phase space

        // =======================================
        // Kinematic distribution of quark and Z'
        // =======================================
        if( zp.children().size() != 2 ) {
          cout<<"[ERROR] N(Z' children) != 2"<<endl;
          vetoEvent;
        }
        _n_evt->fill(4);

        //if( zp.children()[0].abseta() < 2.5 && zp.children()[1].abseta() < 2.5 && 
        //    legs[0].pt() > 30. && legs[1].pt() > 30. && 
        //    legs[0].abseta() < 2.5 && legs[1].abseta() < 2.5 ) {
        if( zp.children()[0].abseta() < 2.5 && zp.children()[1].abseta() < 2.5 ) {

          double dRparton = deltaR(partner.momentum(),zp.momentum());
          _n_evt->fill(5);
          _hval_pt_zp->fill(zp.pt());
          _hval_pt_q->fill(partner.pt());
          _hval_z->fill(partner.pt()/(zp.pt()+partner.pt()));
          if( dRparton < 1. )
            _hval_c_z->fill(partner.E()/(zp.E()+partner.E()));

          _hval_eta_zp->fill(zp.eta());
          _hval_eta_q->fill(partner.eta());
  
          _hval_dR_qzp->fill(dRparton);
          _hval_dRfine_qzp->fill(deltaR(partner.momentum(),zp.momentum()));

          Particle qmatch, qother;
          if( deltaR(outs[0].momentum(),zp.momentum()) < deltaR(outs[0].momentum(),zp.momentum()) ) {
            qmatch = outs[0]; qother = outs[1];
          }
          else {
            qmatch = outs[1]; qother = outs[0];
          }
          _hval_pt_qmatch->fill(qmatch.pt());
          _hval_pt_qother->fill(qother.pt());
          _hval_eta_qmatch->fill(qmatch.eta());
          _hval_eta_qother->fill(qother.eta());

          // Fill histogram here
        }
        

        // ==============
        // Muon selection
        // ==============
        Particles muons;
        for(const auto& p: fs.particles()){
          if( p.abspid() != 13 ) continue;
          if( p.pt() < __SPT__ ) continue;
          if( p.abseta() > 2.5 ) continue;
          muons.push_back(p);
        }
        if( muons.size() < 2 ) vetoEvent;
        std::sort(muons.begin(),muons.end(),[](const Particle& a,const Particle& b){return a.pt()>b.pt();});

        // =======================================
        // Some kinematic distribution
        // before the dR cut on jet and muons
        // =======================================

        bool foundDimuon = false;
        Particle lm, sm;
        for(unsigned i=0; i<muons.size(); i++){
          Particle m1 = muons[i];
          if( m1.pt() < __LPT__ ) continue;
          for(unsigned j=i+1; j<muons.size(); j++){
            Particle m2 = muons[j];
            if( m1.charge() * m2.charge() > 0 ) continue;
            lm = m1; sm = m2;
            foundDimuon = true;
            break;
          }
          if(foundDimuon) break;
        }
        if( !foundDimuon ) vetoEvent;

        Jet this_jet;
        bool foundLeadJet = false;
        double dRmatch = 9999.;
        for(const auto& jet: ptjets) {
          if( !(jet.abseta() < 2.4) ) continue;

          // --- MuF cut --- //
          //double MuE = 0;
          //for(const auto& p : jet.constituents()) {
          //  if( p.abspid() == 13 ) MuE += p.E();
          //}
          //if( MuE == 0 ) continue;
          /////////////////////

          double dR_ = deltaR(partner.momentum(), jet.momentum());
          if( dR_ < dRmatch ) {
            dRmatch = dR_;
            this_jet = jet;
            foundLeadJet = true;
          }
        }

        if( foundLeadJet && dRmatch < .4 ) {
          FourMomentum dimuon = lm.momentum() + sm.momentum();

          _h0_pt_zp->fill(zp.pt());
          _h0_pt_j->fill(this_jet.pt());
          _h0_pt_q->fill(partner.pt());
          _h0_pt_lm->fill(lm.pt());
          _h0_pt_sm->fill(sm.pt());
          
          _h0_eta_zp->fill(zp.eta());
          _h0_eta_j->fill(this_jet.eta());
          _h0_eta_q->fill(partner.eta());
          // _h0_eta_lm->fill(lm.eta());
          // _h0_eta_sm->fill(sm.eta());

          _h0_z_zp->fill(zp.pt()/this_jet.pt());
          _h0_z_dimu->fill(dimuon.pt()/this_jet.pt());
          if( deltaR(this_jet.momentum(),zp.momentum()) < .4 )
            _h0_c_z_zp->fill(zp.pt()/this_jet.pt());
          if( deltaR(this_jet.momentum(),dimuon) < .4 )
            _h0_c_z_dimu->fill(dimuon.pt()/this_jet.pt());

          _h0_dR_qzp->fill(deltaR(partner.momentum(),zp.momentum()));
          _h0_dR_qdimu->fill(deltaR(partner.momentum(),dimuon));
          _h0_dR_qlm->fill(deltaR(partner.momentum(),lm.momentum()));
          _h0_dR_qsm->fill(deltaR(partner.momentum(),sm.momentum()));
          _h0_dR_jzp->fill(deltaR(this_jet.momentum(),zp.momentum()));
          _h0_dR_jdimu->fill(deltaR(this_jet.momentum(),dimuon));
          _h0_dR_jlm->fill(deltaR(this_jet.momentum(),lm.momentum()));
          _h0_dR_jsm->fill(deltaR(this_jet.momentum(),sm.momentum()));
          _h0_dR_jq->fill(dRmatch);
  
          _h0_dRfine_qzp->fill(deltaR(partner.momentum(),zp.momentum()));
          _h0_dRfine_qdimu->fill(deltaR(partner.momentum(),dimuon));
          _h0_dRfine_qlm->fill(deltaR(partner.momentum(),lm.momentum()));
          _h0_dRfine_qsm->fill(deltaR(partner.momentum(),sm.momentum()));
          _h0_dRfine_jzp->fill(deltaR(this_jet.momentum(),zp.momentum()));
          _h0_dRfine_jdimu->fill(deltaR(this_jet.momentum(),dimuon));
          _h0_dRfine_jlm->fill(deltaR(this_jet.momentum(),lm.momentum()));
          _h0_dRfine_jsm->fill(deltaR(this_jet.momentum(),sm.momentum()));

          Particles constituents = this_jet.constituents();
          double MuE = 0;
          for(const auto& p: constituents){
            if( p.abspid() == 13 ) MuE += p.E();
          }
          _h0_j_MuF->fill(MuE/this_jet.E());
          if( deltaR(this_jet.momentum(),dimuon) < .4 )
            _h0_c_j_MuF->fill(MuE/this_jet.E());
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
        for(const auto& jet: ptjets) {
          if( jet.pt() < 30. ) continue;
          if( jet.abseta() > 2.4 ) continue;
          // --- CHF cut --- //
          //if( !(jet.hadronicEnergy()/jet.totalEnergy() > 0) ) continue;

          // Muon Loop
          for(unsigned i=0; i<muons.size(); i++) {
            Particle lmu = muons[i];
            if( lmu.pt() < __LPT__ ) continue;
            if( deltaR( lmu.momentum(), jet.momentum() ) > 0.3 ) continue;
            for(unsigned j=i+1; j<muons.size(); j++) {
              Particle smu = muons[j];
              if( deltaR( smu.momentum(), jet.momentum() ) > 0.3 ) continue;
              if( lmu.charge() * smu.charge() > 0 ) continue;

              // ============================================
              // Passed all the event selection
              // Fill the histograms
              // ============================================
              
              const FourMomentum dimuon = lmu.momentum() + smu.momentum();
              _h_invm -> fill(dimuon.mass());
              _h_pt_j   -> fill( jet.pt() );
              _h_eta_j  -> fill( jet.eta() );
              _h_pt_lmu -> fill( lmu.pt() );
              _h_pt_smu -> fill( smu.pt() );
              //_h_eta_lmu-> fill( lmu.eta() );
              //_h_eta_smu-> fill( smu.eta() );
              _h_dRfine_mumu  -> fill( deltaR(lmu.momentum(), smu.momentum()) );
              _h_dRfine_jdimu -> fill( deltaR(jet.momentum(), dimuon) );
              _h_dRfine_jlmu  -> fill( deltaR(jet.momentum(), lmu.momentum()) );
              _h_dRfine_jsmu  -> fill( deltaR(jet.momentum(), smu.momentum()) );

              _h_z_zp->fill(zp.pt()/jet.pt());
              _h_z_dimu->fill(dimuon.pt()/jet.pt());
              if( deltaR(jet.momentum(),zp.momentum()) < .4 )
                _h_c_z_zp->fill(zp.pt()/jet.pt());
              if( deltaR(jet.momentum(),dimuon) < .4 )
                _h_c_z_dimu->fill(dimuon.pt()/jet.pt());

              _h_pt_zp  -> fill( zp.pt() );
              _h_eta_zp -> fill( zp.eta() );
              _h_pt_q   -> fill( partner.pt() );
              _h_eta_q  -> fill( partner.eta() );
              _h_dR_qzp   -> fill( deltaR(partner.momentum(), zp.momentum()) );
              _h_dR_qdimu -> fill( deltaR(partner.momentum(), dimuon) );
              _h_dR_qlmu  -> fill( deltaR(partner.momentum(), lmu.momentum()) );
              _h_dR_qsmu  -> fill( deltaR(partner.momentum(), smu.momentum()) );
              _h_dRfine_qzp   -> fill( deltaR(partner.momentum(), zp.momentum()) );
              _h_dRfine_qdimu -> fill( deltaR(partner.momentum(), dimuon) );
              _h_dRfine_qlmu  -> fill( deltaR(partner.momentum(), lmu.momentum()) );
              _h_dRfine_qsmu  -> fill( deltaR(partner.momentum(), smu.momentum()) );
              _h_dRfine_jzp   -> fill( deltaR(jet.momentum(), zp.momentum()) );

              if( dimuon.pt()/jet.pt() > 0.95 ) {
                Particles constituents = jet.constituents();
                int chaMul = 0; double MuE = 0;
                for(const auto& p: constituents){
                  if( p.isCharged() ) chaMul += 1;
                  if( p.abspid() == 13 ) MuE += p.E();
                }
                _h_j_multiplicity->fill(constituents.size());
                _h_j_NHF->fill(jet.neutralEnergy()/jet.totalEnergy());
                _h_j_CHF->fill(jet.hadronicEnergy()/jet.totalEnergy());
                _h_j_CM->fill(chaMul);
                _h_j_MuF->fill(MuE/jet.E());
              }
              
              vetoEvent;

            }// End of mu2 loop
          }// End of mu1 loop
        }// End of jet loop
        */
      }// End of event loop

      /// Normalise histograms etc., after the run
      void finalize() {
        norm = (double)numEvents() / 20000.;
        double weight = crossSection()/sumOfWeights()/femtobarn * norm;

__SCALEHISTO__

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
