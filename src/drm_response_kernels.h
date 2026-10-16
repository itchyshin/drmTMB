#ifndef DRMTMB_RESPONSE_KERNELS_H
#define DRMTMB_RESPONSE_KERNELS_H

#include "drm_numeric.h"

// Location-scale Student-t. nu = 2 + exp(eta_nu). Matches model_type==3.
// Used by the main loop and the student has_mi 2-point sum. Not a 7-arg
// drm_response_log_density leaf: that ABI has no nu slot
// (LOOP/notes/A7-student-nu-abi.md). weights(i) stay outside.
// logLik.drmTMB() reads the TMB objective built from this function.
// fitted_distribution() uses stats::dt(), which is already stable.
// The three univariate call sites in src/drmTMB.cpp (the two missing-predictor
// leaves and the main observed-data loop) call this function. They do not
// carry their own lgamma expression.
//
// log f = D(nu) - log(2 pi)/2 - log(sigma) - (nu + 1)/2 * log1p(z^2 / nu),
//   D(nu) = lgamma((nu + 1)/2) - lgamma(nu/2) - log(nu/2)/2.
// The textbook form lgamma((nu+1)/2) - lgamma(nu/2) - log(nu pi)/2 subtracts
// two values of size (nu/2) log(nu/2), so it loses about eps * nu log(nu)
// per row: 1e-6 by eta_nu = 20, order 1 by eta_nu = 34 (#1462, #1504). D(nu)
// is O(1/nu), so it is returned directly: by the exact lgamma difference
// below nu = 100 (error below 1e-13 there), and by the asymptotic series
//   D(nu) = -1/(4 nu) + 1/(24 nu^3) - 1/(20 nu^5) + 17/(112 nu^7)
//           - 31/(36 nu^9) + ...
// from nu = 100 on (truncation below 1e-20). log1p() keeps z^2/nu, which
// the log(1 + z^2/nu) form drops once nu is large. The density tends to the
// Gaussian log-density -log(2 pi)/2 - log(sigma) - z^2/2 as nu -> infinity.
// Both branches are recorded on the tape, so each sees nu clamped into the
// region where it is finite.
template<class Type>
Type drm_student_log_density(Type y, Type mu, Type log_sigma, Type eta_nu)
{
  Type nu = Type(2.0) + exp(eta_nu);
  Type z = (y - mu) / exp(log_sigma);
  Type half = Type(0.5);
  Type nu_cut = Type(100.0);

  Type nu_direct = CppAD::CondExpLt(nu, nu_cut, nu, nu_cut);
  Type d_direct =
    lgamma(half * nu_direct + half) -
    lgamma(half * nu_direct) -
    half * log(half * nu_direct);

  Type nu_series = CppAD::CondExpLt(nu, nu_cut, nu_cut, nu);
  Type inv = Type(1.0) / nu_series;
  Type inv2 = inv * inv;
  Type d_series = inv * (
    -Type(1.0) / Type(4.0) + inv2 * (
      Type(1.0) / Type(24.0) + inv2 * (
        -Type(1.0) / Type(20.0) + inv2 * (
          Type(17.0) / Type(112.0) - inv2 * Type(31.0) / Type(36.0)))));
  Type d_nu = CppAD::CondExpLt(nu, nu_cut, d_direct, d_series);

  // Cap only the kernel factor. Past 1e300 the Gaussian limit has already
  // been reached, and (Inf * 0) from z^2/nu would be NaN.
  Type nu_kernel = CppAD::CondExpLt(nu, Type(1.0e300), nu, Type(1.0e300));
  return d_nu - half * log(Type(2.0) * M_PI) -
    log_sigma -
    half * (nu_kernel + Type(1.0)) * drm_log1p_pos((z * z) / nu_kernel);
}

// Gamma log-density, log link, mean-CV: shape s = 1/sigma^2, scale = mu / s.
// Textbook: (s - 1) log y - y/scale - lgamma(s) - s log(scale). Its terms are
// of size s log(s), so at small CV (large s) the rounding is about
// eps * s log(s). With r = y/mu, u = r - 1 and the Stirling remainder B(s),
//   log f = log(s)/2 - log(2 pi)/2 - B(s) - s * (u - log1p(u)) - log(y),
// where s * (u - log1p(u)) ~ s u^2 / 2 is the standardised squared residual.
// u = expm1(log(y) - eta) keeps u to absolute accuracy eps. The kernel
// tends to the Gaussian limit as s -> infinity.
template<class Type>
Type drm_gamma_log_density(Type y, Type eta, Type log_sigma)
{
  Type shape = exp(Type(-2.0) * log_sigma);
  Type log_y = log(y);
  return Type(0.5) * log(shape) - Type(0.5) * log(Type(2.0) * M_PI) -
    drm_stirling_remainder(shape) -
    shape * drm_expm1_minus_x(log_y - eta) -
    log_y;
}

// Beta log-density with shapes alpha, beta_shape (> 0, already floored by the
// caller). Textbook lgamma(a+b) - lgamma(a) - lgamma(b) + (a-1) log(y) +
// (b-1) log(1-y) loses about eps * phi log(phi) once phi = a + b is large.
// With p = a + b, B() the Stirling remainder, and u_a = y p / a - 1,
// u_b = (1-y) p / b - 1,
//   log f = -a h(u_a) - b h(u_b) - log(y) - log(1-y)
//           + (log a + log b - log p)/2 - log(2 pi)/2
//           + B(p) - B(a) - B(b),   h(u) = u - log1p(u),
// (a u_a + b u_b = 0 exactly, so those terms are dropped). Every term is
// O(1) or the standardised residual, and the density tends to the Gaussian
// log-density as phi -> infinity.
template<class Type>
Type drm_beta_log_density(Type y, Type alpha, Type beta_shape)
{
  Type p = alpha + beta_shape;
  Type log_p = log(p);
  Type log_a = log(alpha);
  Type log_b = log(beta_shape);
  Type log_y = log(y);
  Type log_1my = log(Type(1.0) - y);
  // u_a = y p / a - 1 and u_b = (1 - y) p / b - 1 to full double accuracy.
  // The rounding of the products y p and (1 - y) p is not negligible: it is
  // about eps * a, and a * u * eps_u is the error that survives in a h(u).
  // drm_two_prod_err() recovers it exactly (Dekker 1971), and 1 - y is
  // split into a rounded value and its exact remainder.
  Type one_my = Type(1.0) - y;
  Type one_my_err = (Type(1.0) - one_my) - y;
  Type yp = y * p;
  Type bp = one_my * p;
  Type u_a = ((yp - alpha) + drm_two_prod_err(y, p, yp)) / alpha;
  Type u_b = ((bp - beta_shape) + drm_two_prod_err(one_my, p, bp) +
    one_my_err * p) / beta_shape;
  return -alpha * drm_x_minus_log1p(u_a) -
    beta_shape * drm_x_minus_log1p(u_b) -
    log_y - log_1my +
    Type(0.5) * (log_a + log_b - log_p) -
    Type(0.5) * log(Type(2.0) * M_PI) +
    drm_stirling_remainder(p) -
    drm_stirling_remainder(alpha) -
    drm_stirling_remainder(beta_shape);
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
      return drm_beta_log_density(y_val, alpha, beta_shape);
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
      return drm_gamma_log_density(y_val, eta_val, log_sigma_val);
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
