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

      book(_h_pti,   "h_pti",   50,0.,200.0);
      book(_h_etai,  "h_etai",  100,-5.,5.);
      book(_h_ptj,   "h_ptj",   50,0.,200.0);
      book(_h_etaj,  "h_etaj",  100,-5.,5.0);
	  book(_h_phii, "h_phii", 64,0,6.4);
	  book(_h_phij, "h_phij", 64,0,6.4);

      book(_h_dR_ij, "h_dR_ij", 40, 0., 4.);
	  book(_h_dEta_ij, "h_dEta_ij", 50,0,5);
	  book(_h_dPhi_ij, "h_dPhi_ij", 32,0,3.2);

      book(_h_m_ij,  "h_m_ij",  100,0.,500.);

      book(_h_pT,  "h_pT",  100,0.,100.0);
      book(_h_qT,  "h_qT",  100,0.,400.0);
      book(_h_z,   "h_z",   100,0.,1.);
      //book(_n_h, "n_h", 1,0.,1.);
      //book(_s_h, "s_z_h", 50, 0.,1., 50, 0.,1.);

    }

    /// Perform the per-event analysis
    void analyze(const Event& event) {
      //setup analysis
      const double weight = 1.;

      const FinalState& fs = applyProjection<FinalState>(event, "FS");

      Particle out, recoil, branch;
      vector<Particle> leg;

      // find events with Z'
      // and save Z' as 'out'
      // note that we will focus on events with only one Z'
      int NZp = 0;
      for(const Particle& p : fs.particles()) {
        if(p.pid()==9900032) {
          out = p;
          NZp++;
        }
      }
      _n_evt->fill(0,weight);
      if( NZp!=1 ) vetoEvent;
      _n_evt->fill(1,weight);

      // find ancestor parton of Z'
      // and save it as 'qAnc'
	  Particle qAnc = out;
	  while( qAnc.parents().size()==1 ){
        Particle qAncTmp = (qAnc.parents())[0];
        if( qAncTmp.abspid()<7 )
            qAnc = qAncTmp;
        else
            break;
	  }
      // find leg particles
      // --> find parton candidate that might radiate Z'
      // and save its final state as 'leg'
      // here, MEptls are particles that are...
      // (in MG) outgoing ptls from the hard scattering --> two partons and one Z'
      // (in HW FSR) outgoing ptls from the hard scattering --> two partons
      // (in HW ISR) incoming ptl that will radiate Z' and a ghost ptl with pid 82 --> one parton and one ghost
	  Particles MEptls = ((qAnc.parents())[0]).children();
	  for(const auto& q: MEptls){
        // only check quarks
	  	if(q.abspid()>6) continue;

        // find a final state
		Particle qFinal = q;
		while( qFinal.children().size()>0 ){
            bool findChild = false;
			for(const auto& qChild: qFinal.children()){
				if( q.pid() == qChild.pid() ){
					qFinal = qChild;
                    findChild = true;
					break;
					}
			}
            // to avoid an infinite loop
            // in ISR, quark-antiquark pair can be create a glu glu pair
            // in this case, while loop does not end.
            if( !findChild ) break;
		}
		leg.push_back(qFinal);
	  }
	  if( leg.size()<1 ) vetoEvent;
	  _n_evt->fill(2,weight);
	  /*
      if( leg[0].abspid()!=leg[1].abspid() ) {
        cout<<"[ERROR] The first two particles have different abs pdg id."<<endl;
        cout<<"        Terminate running."<<endl;
        vetoEvent;
      }
	  */
	  double m0, m1, m2;
	  m2 = out.momentum().mass();
	  double pT, zq, qT;
	  for(const auto& l: leg){
		if( l.abseta() > 5. ) vetoEvent;
	  }
	  _n_evt->fill(3,weight);
      //if( abs(leg[0].eta()) > 5. || abs(leg[1].eta()) > 5. ) vetoEvent;
      //if( leg[0].pt() < 20. || leg[1].pt() < 20. ) vetoEvent;
	  if( leg.size()==1 ){
		branch = leg[0];
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
        branch = leg[0]; recoil = leg[1];
	    pT = sqrt(pT2[0]);
	    zq = z[0];
      }
      else {
        branch = leg[1]; recoil = leg[0];
	    pT = sqrt(pT2[1]);
	    zq = z[1];
      }
	  }
      if( branch.abspid() < 3 ) m0=0.325;
      else if( branch.abspid() == 3 ) m0=0.101;
      else if( branch.abspid() == 4 ) m0=1.27;
      else if( branch.abspid() == 5 ) m0=4.7;
      else if( branch.abspid() == 6 ) m0=172.;
      else {
        cout<<"[ERROR] quark mass is not defined. Veto this event."<<endl;
        vetoEvent;
      }
	  _n_evt->fill(5,weight);

	  //if( leg[0].pt() >= 20. && leg[1].pt() >= 20. ) _n_evt->fill(6,weight);
	  
      qT = sqrt(((branch.momentum()+out.momentum()).invariant()-sqr(m0))/zq/(1-zq));

      _h_pT->fill(pT);
      _h_qT->fill(qT);
      _h_z->fill(zq);

      _h_pti->fill(branch.pt(),weight);
      _h_etai->fill(branch.eta(),weight);
      _h_ptj->fill(out.pt(),weight);
      _h_etaj->fill(out.eta(),weight);
	  _h_phii->fill(branch.phi(),weight);
	  _h_phij->fill(out.phi(),weight);

	  if( branch.pt()<30. ) vetoEvent;
	  _n_evt->fill(6,weight);

	  double dR = deltaR(branch.momentum(),out.momentum());
      _h_dR_ij->fill(dR,weight);
      _h_dEta_ij->fill(deltaEta(branch.momentum(),out.momentum()),weight);
      _h_dPhi_ij->fill(deltaPhi(branch.momentum(),out.momentum()),weight);

      _h_m_ij->fill((branch.momentum()+out.momentum()).mass(),weight);

      //if(_scatter_h.size()<20000)
	  //    _scatter_h.push_back(make_pair(xh,xz));
	  //  _s_h->fill(xh,xz,weight);
    }

    /// Normalise histograms etc., after the run
    void finalize() {
      double weight = crossSection()/sumOfWeights()/femtobarn * numEvents()/20000.;

	  scale(_n_evt, weight);

      scale(_h_pT, weight);
      scale(_h_qT, weight);
      scale(_h_z, weight);

      scale(_h_pti, weight );
      scale(_h_etai, weight );
      scale(_h_ptj, weight );
      scale(_h_etaj, weight );
      scale(_h_phii, weight );
      scale(_h_phij, weight );

      scale(_h_dR_ij, weight );
      scale(_h_dEta_ij, weight );
      scale(_h_dPhi_ij, weight );

      scale(_h_m_ij, weight );

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

    Histo1DPtr _h_pT;
    Histo1DPtr _h_qT;
    Histo1DPtr _h_z;

    Histo1DPtr _h_pti;
    Histo1DPtr _h_etai;
    Histo1DPtr _h_ptj;
    Histo1DPtr _h_etaj;
    Histo1DPtr _h_phii;
    Histo1DPtr _h_phij;

    Histo1DPtr _h_dR_ij;
    Histo1DPtr _h_dEta_ij;
    Histo1DPtr _h_dPhi_ij;

    Histo1DPtr _h_m_ij;



    //Histo1DPtr _n_h;
    //Histo2DPtr _s_h;
    //@}

    //vector<pair<double,double> > _scatter_h;
  };



  // The hook for the plugin system
  DECLARE_RIVET_PLUGIN(RAnalysis);


}
