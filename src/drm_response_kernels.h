#ifndef DRMTMB_RESPONSE_KERNELS_H
#define DRMTMB_RESPONSE_KERNELS_H

#include "drm_numeric.h"

// Location-scale Student-t. nu = 2 + exp(eta_nu). Matches model_type==3.
// Used by the main loop and the student has_mi 2-point sum. Not a 7-arg
// drm_response_log_density leaf: that ABI has no nu slot
// (LOOP/notes/A7-student-nu-abi.md). weights(i) stay outside.
template<class Type>
Type drm_student_log_density(Type y, Type mu, Type log_sigma, Type eta_nu)
{
  Type sigma = exp(log_sigma);
  Type nu = Type(2.0) + exp(eta_nu);
  Type z = (y - mu) / sigma;
  Type half = Type(0.5);
  return lgamma(half * (nu + Type(1.0))) -
    lgamma(half * nu) -
    half * log(nu * M_PI) -
    log_sigma -
    half * (nu + Type(1.0)) * log(Type(1.0) + z * z / nu);
}

// Pluggable per-family response log-density leaf, used by the missing-predictor
// mi() quadrature so a non-Gaussian response can reuse the same integration
// loop. P2 extracts only the Gaussian case (a pure refactor: the returned value
// is byte-identical to the inline dnorm it replaces); P3 fills the other
// families and wires them into non-Gaussian-response mi() call sites.
// Student (model_type 3) is deliberately not a case here — see
// drm_student_log_density and LOOP/notes/A7-student-nu-abi.md.
//
// Contract:
//   * weights(i) is applied OUTSIDE this leaf at every call site -- do NOT
//     absorb it here, or every caller's semantics change.
//   * For a two-point (or quadrature) mi() mixture, "outside this leaf" is
//     not enough on its own: weights(i) must be applied outside the WHOLE
//     mixture (after logspace_add() combines the leaves), not to each leaf
//     before the leaves are combined. `weights(i) * leaf()` computed per leaf
//     and then mixed computes log(p1*f1^w + p0*f0^w), not the correct
//     w*log(p1*f1 + p0*f0) -- a constant weight then moves the MLE (Dinnage
//     audit M1). The mi_family == 1 two-point sites in src/drmTMB.cpp now
//     call this leaf unweighted and multiply weights(i) into the combined
//     log_denom afterwards.
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
    case 14: {
      // beta_binomial: nudged logit mean, phi = exp(-2*log_sigma).
      // Replicates the model_type==14 main-loop density so the mi() 2-point
      // sum and the observed-x loop agree (S6 A7 / #962).
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
      Type failures = trials_val - y_val;
      return lgamma(trials_val + Type(1.0)) -
        lgamma(y_val + Type(1.0)) -
        lgamma(failures + Type(1.0)) +
        lgamma(phi) -
        lgamma(trials_val + phi) +
        lgamma(y_val + alpha) -
        lgamma(alpha) +
        lgamma(failures + beta_shape) -
        lgamma(beta_shape);
    }
    default:
      // Returning Type(0.0) here (a likelihood contribution of 1, i.e. a
      // silent no-op) let a future family wired into an mi() two-point sum
      // fit "successfully" with a wrong likelihood before its case was
      // added here (Dinnage audit Mi-9). model_type is a plain int
      // (DATA_INTEGER), not an AD variable, so erroring here is a normal
      // runtime branch, not a taping concern.
      error("drm_response_log_density(): unhandled model_type");
      return Type(0.0); // unreachable; keeps the compiler's return-path check happy
  }
}

#endif // DRMTMB_RESPONSE_KERNELS_H
