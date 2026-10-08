#ifndef DRMTMB_RESPONSE_KERNELS_H
#define DRMTMB_RESPONSE_KERNELS_H

#include "drm_numeric.h"

// Location-scale Student-t. nu = 2 + exp(eta_nu). Matches model_type==3.
// Used by the main loop and the student has_mi 2-point sum. Not a 7-arg
// drm_response_log_density leaf: that ABI has no nu slot
// (LOOP/notes/A7-student-nu-abi.md). weights(i) stay outside.
// logLik.drmTMB() reads the TMB objective built from this function.
// fitted_distribution() uses stats::dt(), which is already stable.
//
// The textbook constant lgamma((nu+1)/2) - lgamma(nu/2) cancels once nu is
// past about 1e6: the two lgamma values are about (nu/2) log(nu/2), and the
// rounding error in their difference has reached +1e12 on the sum of n = 300
// rows (#1462). log(1 + z^2/nu) drops z^2/nu in the same regime. The density
// below is the same expression, evaluated so that it tends to the Gaussian
// log-density -0.5 log(2 pi) - log(sigma) - 0.5 z^2.
//
// For nu < 1e4 the constant is still the lgamma difference (accurate there;
// the dt() oracle at nu = 10 stays on this branch). For nu >= 1e4 it is the
// Stirling expansion in a = nu/2,
//   -0.5 log(2 pi) - 1/(8a) + 1/(192 a^3) - 1/(640 a^5),
// whose remainder is below 1e-15 at the switch. The kernel uses
// drm_log1p_nonnegative(z^2/nu). The conditional records both constant
// branches, so each one sees nu clamped into the region where it is finite.
template<class Type>
Type drm_student_log_density(Type y, Type mu, Type log_sigma, Type eta_nu)
{
  Type nu = Type(2.0) + exp(eta_nu);
  Type z = (y - mu) / exp(log_sigma);
  Type half = Type(0.5);
  Type nu_cut = Type(1.0e4);

  Type nu_direct = CppAD::CondExpLt(nu, nu_cut, nu, nu_cut);
  Type a_direct = half * nu_direct;
  Type log_norm_direct =
    lgamma(a_direct + half) -
    lgamma(a_direct) -
    half * log(nu_direct * M_PI);

  Type nu_series = CppAD::CondExpLt(nu, nu_cut, nu_cut, nu);
  Type inv_a = Type(2.0) / nu_series;
  Type inv_a2 = inv_a * inv_a;
  Type log_norm_series =
    -half * log(Type(2.0) * M_PI)
    - inv_a / Type(8.0)
    + inv_a2 * inv_a / Type(192.0)
    - inv_a2 * inv_a2 * inv_a / Type(640.0);
  Type log_norm = CppAD::CondExpLt(
    nu, nu_cut, log_norm_direct, log_norm_series);

  // Cap only the kernel factor. Past 1e300 the Gaussian limit has already
  // been reached, and (Inf * 0) from z^2/nu would be NaN.
  Type nu_kernel = CppAD::CondExpLt(nu, Type(1.0e300), nu, Type(1.0e300));
  Type log1p_z = drm_log1p_nonnegative((z * z) / nu_kernel);
  return log_norm -
    log_sigma -
    half * (nu_kernel + Type(1.0)) * log1p_z;
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
      Type phi_shape = alpha + beta_shape;
      Type failures = trials_val - y_val;
      return lgamma(trials_val + Type(1.0)) -
        lgamma(y_val + Type(1.0)) -
        lgamma(failures + Type(1.0)) +
        lgamma(phi_shape) -
        lgamma(trials_val + phi_shape) +
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
