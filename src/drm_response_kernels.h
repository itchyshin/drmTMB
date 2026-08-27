#ifndef DRMTMB_RESPONSE_KERNELS_H
#define DRMTMB_RESPONSE_KERNELS_H

#include "drm_numeric.h"

// Pluggable per-family response log-density leaf, used by the missing-predictor
// mi() quadrature so a non-Gaussian response can reuse the same integration
// loop. P2 extracts only the Gaussian case (a pure refactor: the returned value
// is byte-identical to the inline dnorm it replaces); P3 fills the other
// families and wires them into non-Gaussian-response mi() call sites.
//
// Contract:
//   * weights(i) is applied OUTSIDE this leaf at every call site -- do NOT
//     absorb it here, or every caller's semantics change.
//   * eta_val / log_sigma_val carry live AD gradient; never route them through
//     asDouble() (that would silently zero their gradients).
//   * model_type is a plain int (DATA_INTEGER), so this switch is resolved at
//     tape construction -- it is not a CondExp/taping concern.
template<class Type>
Type drm_response_log_density(
    int model_type,
    Type y_val,
    Type eta_val,
    Type log_sigma_val,
    Type V_known_val,
    Type trials_val,
    int link_code)
{
  (void) trials_val; // used by the binomial leaf added in P3
  switch (model_type) {
    case 1: {
      // gaussian: identity mean, sd = sqrt(V_known + exp(2*log_sigma)).
      // This exp(2*log_sigma) form is the one used at every mi()-branch call
      // site; it is NOT bit-identical to the vanilla no-mi path's sigma*sigma
      // precompute, which is deliberately left untouched.
      Type sigma_i = sqrt(V_known_val + exp(Type(2.0) * log_sigma_val));
      return dnorm(y_val, eta_val, sigma_i, true);
    }
    case 6: {
      // poisson: log link, mu = exp(eta); no dispersion or trials.
      return dpois(y_val, exp(eta_val), true);
    }
    case 18: {
      // binomial: link dispatched on link_code (0 = logit, 1 = probit,
      // 2 = cloglog; see drm_binom_log_mu() in drm_numeric.h).
      // trials_val successes-out-of-trials.
      DrmBinomLogMu<Type> log_mu = drm_binom_log_mu(eta_val, link_code);
      Type log_p1 = log_mu.log_mu;
      Type log_p0 = log_mu.log_one_minus_mu;
      Type failures = trials_val - y_val;
      Type log_choose = lgamma(trials_val + Type(1.0)) -
        lgamma(y_val + Type(1.0)) - lgamma(failures + Type(1.0));
      return log_choose + y_val * log_p1 + failures * log_p0;
    }
    case 7: {
      // nbinom2: log link via eta; dispersion size = exp(-2*log_sigma).
      // The kernel takes the raw linear predictor (eta), NOT mu.
      return drm_nbinom2_log_density(y_val, eta_val, log_sigma_val);
    }
    case 10: {
      // beta: nudged logit mean, precision phi = exp(-2*log_sigma). Replicates
      // the model_type==10 block verbatim (eps 1e-12, shape floor 1e-8).
      Type beta_mu_eps = Type(1e-12);
      Type beta_shape_floor = Type(1e-8);
      Type mu_raw = exp(drm_log_inv_logit(eta_val));
      Type mu = beta_mu_eps + (Type(1.0) - Type(2.0) * beta_mu_eps) * mu_raw;
      Type phi = exp(Type(-2.0) * log_sigma_val);
      Type alpha_raw = mu * phi;
      Type beta_raw = (Type(1.0) - mu) * phi;
      Type alpha =
        CppAD::CondExpLt(alpha_raw, beta_shape_floor, beta_shape_floor, alpha_raw);
      Type beta_shape =
        CppAD::CondExpLt(beta_raw, beta_shape_floor, beta_shape_floor, beta_raw);
      return lgamma(alpha + beta_shape) - lgamma(alpha) - lgamma(beta_shape) +
        (alpha - Type(1.0)) * log(y_val) +
        (beta_shape - Type(1.0)) * log(Type(1.0) - y_val);
    }
    case 4: {
      // lognormal: identity log-location. dnorm(log(y), mu, sigma) - log(y).
      // Replicates the model_type==4 main-loop density so the mi() 2-point
      // sum and the observed-x loop agree (S6 A7 / #962).
      Type log_y = log(y_val);
      return dnorm(log_y, eta_val, exp(log_sigma_val), true) - log_y;
    }
    case 5: {
      // gamma: log link, mean-CV. shape = 1/sigma^2, scale = mu * sigma^2.
      // Replicates the model_type==5 main-loop density so the mi() 2-point
      // sum and the observed-x loop agree (S6 A7 / #962).
      Type mu = exp(eta_val);
      Type sigma = exp(log_sigma_val);
      Type variance_multiplier = sigma * sigma;
      Type shape = Type(1.0) / variance_multiplier;
      Type scale = mu * variance_multiplier;
      return (shape - Type(1.0)) * log(y_val) -
        y_val / scale -
        lgamma(shape) -
        shape * log(scale);
    }
    default:
      // Non-Gaussian response leaves are added in P3; unreachable in P2 (only
      // the model_type == 1 mi() block calls this helper).
      return Type(0.0);
  }
}

#endif // DRMTMB_RESPONSE_KERNELS_H
