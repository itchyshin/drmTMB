// R 4.5's Apple clang headers currently use a diagnostic pragma for
// -Wfixed-enum-extension that this local clang does not recognize. Including
// Boolean.h through the legacy branch before TMB avoids a package-check
// installation warning without shipping non-portable compiler flags.
#include <Rconfig.h>
#ifdef HAVE_ENUM_BASE_TYPE
#define DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE 1
#undef HAVE_ENUM_BASE_TYPE
#endif
#include <R_ext/Boolean.h>
#ifdef DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE
#define HAVE_ENUM_BASE_TYPE 1
#endif
#include <TMB.hpp>

template<class Type>
Type objective_function<Type>::operator()()
{
  DATA_VECTOR(y);
  DATA_VECTOR(V_known);
  DATA_VECTOR(y1);
  DATA_VECTOR(y2);
  DATA_INTEGER(model_type);
  DATA_MATRIX(X_mu);
  DATA_MATRIX(X_sigma);
  DATA_MATRIX(X_mu1);
  DATA_MATRIX(X_mu2);
  DATA_MATRIX(X_sigma1);
  DATA_MATRIX(X_sigma2);
  DATA_MATRIX(X_rho12);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_sigma);
  PARAMETER_VECTOR(beta_mu1);
  PARAMETER_VECTOR(beta_mu2);
  PARAMETER_VECTOR(beta_sigma1);
  PARAMETER_VECTOR(beta_sigma2);
  PARAMETER_VECTOR(beta_rho12);

  Type nll = 0;
  if (model_type == 1) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> sigma = exp(log_sigma);
    vector<Type> obs_sigma = sqrt(V_known + sigma * sigma);

    for (int i = 0; i < y.size(); ++i) {
      nll -= dnorm(y(i), mu(i), obs_sigma(i), true);
    }

    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(obs_sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 2) {
    vector<Type> mu1 = X_mu1 * beta_mu1;
    vector<Type> mu2 = X_mu2 * beta_mu2;
    vector<Type> log_sigma1 = X_sigma1 * beta_sigma1;
    vector<Type> log_sigma2 = X_sigma2 * beta_sigma2;
    vector<Type> sigma1 = exp(log_sigma1);
    vector<Type> sigma2 = exp(log_sigma2);
    vector<Type> eta_rho12 = X_rho12 * beta_rho12;
    vector<Type> rho12 = Type(0.99999999) * tanh(eta_rho12);

    Type log2pi = log(Type(2.0) * M_PI);
    for (int i = 0; i < y1.size(); ++i) {
      Type z1 = (y1(i) - mu1(i)) / sigma1(i);
      Type z2 = (y2(i) - mu2(i)) / sigma2(i);
      Type one_minus_rho2 = Type(1.0) - rho12(i) * rho12(i);
      nll += log2pi + log_sigma1(i) + log_sigma2(i);
      nll += Type(0.5) * log(one_minus_rho2);
      nll += Type(0.5) * (z1 * z1 - Type(2.0) * rho12(i) * z1 * z2 + z2 * z2) / one_minus_rho2;
    }

    REPORT(mu1);
    REPORT(mu2);
    REPORT(log_sigma1);
    REPORT(log_sigma2);
    REPORT(sigma1);
    REPORT(sigma2);
    REPORT(eta_rho12);
    REPORT(rho12);
    ADREPORT(beta_mu1);
    ADREPORT(beta_mu2);
    ADREPORT(beta_sigma1);
    ADREPORT(beta_sigma2);
    ADREPORT(beta_rho12);
  }

  return nll;
}
