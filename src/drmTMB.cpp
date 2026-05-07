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
  DATA_MATRIX(V_known_matrix);
  DATA_INTEGER(V_known_type);
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
  DATA_INTEGER(n_mu_re_terms);
  DATA_IMATRIX(mu_re_index);
  DATA_MATRIX(mu_re_value);
  DATA_IVECTOR(mu_re_term);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_sigma);
  PARAMETER_VECTOR(beta_mu1);
  PARAMETER_VECTOR(beta_mu2);
  PARAMETER_VECTOR(beta_sigma1);
  PARAMETER_VECTOR(beta_sigma2);
  PARAMETER_VECTOR(beta_rho12);
  PARAMETER_VECTOR(u_mu);
  PARAMETER_VECTOR(log_sd_mu);

  Type nll = 0;
  if (model_type == 1) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> sigma = exp(log_sigma);
    vector<Type> obs_sigma = sqrt(V_known + sigma * sigma);

    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          mu(i) += mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
    }

    if (V_known_type == 2) {
      int n = y.size();
      matrix<Type> Omega(n, n);
      for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
          Omega(i, j) = V_known_matrix(i, j);
        }
        Omega(i, i) += sigma(i) * sigma(i);
      }
      density::MVNORM_t<Type> neg_log_density(Omega);
      nll += neg_log_density(y - mu);
    } else {
      for (int i = 0; i < y.size(); ++i) {
        nll -= dnorm(y(i), mu(i), obs_sigma(i), true);
      }
    }

    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(obs_sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
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
