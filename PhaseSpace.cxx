/// \file
/// \ingroup tutorial_physics
/// \notebook -js
/// Example of use of TGenPhaseSpace
///
/// \macro_image
/// \macro_code
///
/// \author Valerio Filippini

#include "TGenPhaseSpace.h"
#include "TH1F.h"
#include "TH2F.h"
#include "TLorentzVector.h"
#include "TRandom3.h"
#include <chrono>
#include <iostream>
#include <istream>

const double MASS_P=0.93827231;
const double MASS_E=0.00510998;

// Calcuating Q^2
//	Gotten from t channel
// -q^mu^2 = -(e^mu - e^mu')^2 = Q^2
double Q2_calc(TLorentzVector e_mu, TLorentzVector e_mu_prime) {
  TLorentzVector q_mu = (e_mu - e_mu_prime);
  return -q_mu.Mag2();
}
//	Calcualting W
//	Gotten from s channel [(gamma + P)^2 == s == w^2]
//	Sqrt√[M_p^2 - Q^2 + 2 M_p gamma]
double W_calc(TLorentzVector e_mu, TLorentzVector e_mu_prime) {
  TLorentzVector q_mu = (e_mu - e_mu_prime);
  TLorentzVector p_mu;
  p_mu.SetXYZM(0, 0, 0, MASS_P);
  return (p_mu + q_mu).Mag();
}

void PhaseSpace(std::string file_name, int gen_num = 10000, float energy=10.6, float q2_min=0.0, float q2_max=12.0) {

  ofstream myfile;
  myfile.open(file_name.c_str());

  TLorentzVector target(0.0, 0.0, 0.0, MASS_P);
  TLorentzVector beam(0.0, 0.0, energy, energy);
  TLorentzVector cms = beam + target;

  //(Momentum, Energy units are Gev/C, GeV)
  Double_t masses[2] = {MASS_E, MASS_P};

  TGenPhaseSpace *event = new TGenPhaseSpace();
  event->SetDecay(cms, 2, masses);

  int n = 0;
  while (n < gen_num) {
    Double_t weight = event->Generate();
    TLorentzVector *Eprime = event->GetDecay(0);
    TLorentzVector *Proton = event->GetDecay(1);

    double W = W_calc(beam, *Eprime);
    double Q2 = Q2_calc(beam, *Eprime);

    if (Q2 > q2_min && Q2 < q2_max) {
      if (n++ % 1000 == 0)
        std::cout << "\t" << n << "\r" << std::flush;

      myfile << "\t2 0.93827231 1 0 1 11 " << energy << " 2212 0 " << weight
             << std::endl;
      myfile << "1 0 1 11 0 0 " << Eprime->Px() << " " << Eprime->Py() << " "
             << Eprime->Pz() << " " << Eprime->E() << " " << Eprime->M()
             << " 0 0 0" << std::endl;
      myfile << "2 0 1 2212 0 0 " << Proton->Px() << " " << Proton->Py() << " "
             << Proton->Pz() << " " << Proton->E() << " " << Proton->M()
             << " 0 0 0" << std::endl;
    }
  }
  myfile << std::endl;
  myfile.close();
  exit(0);
}
